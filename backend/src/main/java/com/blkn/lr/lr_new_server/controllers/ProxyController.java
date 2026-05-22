package com.blkn.lr.lr_new_server.controllers;

import com.alibaba.fastjson.JSONObject;
import com.blkn.lr.lr_new_server.dto.apiproxy.HandWritingRecognizeResult;
import com.blkn.lr.lr_new_server.dto.apiproxy.TextSimilarityResult;
import com.blkn.lr.lr_new_server.dto.flytek.audio.AudioRecognizeResult;
import com.blkn.lr.lr_new_server.dto.apiproxy.FluencyResult;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.expection.FlyTekApiException;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.util.BaiduApiManager;
import com.blkn.lr.lr_new_server.util.FlyTekManager;
import com.blkn.lr.lr_new_server.util.ThreadPools;
import com.blkn.lr.lr_new_server.util.fluency.FluencyProcessor;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import lombok.extern.slf4j.Slf4j;
import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Future;

@Slf4j
@RestController
@RequestMapping("/api/proxy")
public class ProxyController {

    @Autowired
    private BaiduApiManager baiduApi;

    @Autowired
    private FluencyProcessor processor;

    @Autowired
    private FlyTekManager flyTekManager;


    @Autowired
    Environment environment;

    @PostMapping("/text_similarity")
    TextSimilarityResult calTextSimilarity(@RequestParam("text1") String text1, @RequestParam("text2") String text2) {
        log.debug("text_similarity: text1={}, text2={}", text1, text2);
        Double sim;
        if (text1.equals("")) {
            sim = 0d;
        } else {
            sim = baiduApi.shortTextSimilarity(text1, text2);
        }
        return new TextSimilarityResult(sim);
    }

    @PostMapping("/audio_recognize")
    AudioRecognizeResult recognizeAudioContent(@RequestParam("file") MultipartFile file) throws Exception {
        Future<String> future = flyTekManager.recognizeAudio(file.getBytes());
        String result = future.get();
        String safeName = UUID.randomUUID() + "_" + Paths.get(file.getOriginalFilename()).getFileName().toString();
        File dest = new File(System.getProperty("user.dir"), safeName);
        file.transferTo(dest);

        return new AudioRecognizeResult(result);
    }

    @PostMapping("/fluency")
    FluencyResult calFluency(@RequestParam("file") MultipartFile file) throws FlyTekApiException {
        try {
            Future<String> future = flyTekManager.recognizeAudio(file.getBytes());
            String audioContent = future.get();
            log.debug("音频识别结果: {}", audioContent);
            if (audioContent.isEmpty()) {
                return new FluencyResult(0, "患者未说任何内容", audioContent);
            }

            CompletableFuture<Boolean> repeatFuture = new CompletableFuture<>();
            CompletableFuture<Integer> stopFuture = new CompletableFuture<>();
            CompletableFuture<JSONObject> telegramFuture = new CompletableFuture<>();
            CompletableFuture<Double> dnnFuture = new CompletableFuture<>();

            ThreadPools.fluencyCalculator.submit(() -> {
                // 计算停顿次数
                try {
                    stopFuture.complete(processor.get_stop_times(file.getBytes()));
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            });

            ThreadPools.fluencyCalculator.submit(() -> {
                repeatFuture.complete(processor.repeat(audioContent));
            });

            ThreadPools.fluencyCalculator.submit(() -> {
                try {
                    telegramFuture.complete(processor.Telegram_Language(audioContent));
                } catch (Exception e) {
                    log.warn("电报式语言判定失败", e);
                }
            });

            ThreadPools.fluencyCalculator.submit(() -> {
                try {
                    dnnFuture.complete((double) baiduApi.dnn(audioContent).get("ppl") / audioContent.length());
                } catch (Exception e) {
                    log.warn("DNN 困惑度计算失败", e);
                }

            });

            boolean repeat = repeatFuture.get();
            int stopTimes = stopFuture.get();
            JSONObject telegram = telegramFuture.get();
            double dnn = dnnFuture.get();

            StringBuilder detail = new StringBuilder();
            double fluency = processor.fluency_score(1, stopTimes, repeat,telegram, dnn, detail);
            return new FluencyResult(fluency, detail.toString(), audioContent);
        } catch (Exception e) {
            throw new FlyTekApiException();
        }
    }

    @PostMapping("/handwrite_recognize")
    HandWritingRecognizeResult recognizeHandleWriting(@RequestParam("file") MultipartFile file) throws Exception {
        String result = baiduApi.handWriteRecognize(file.getBytes());

        String safeName = UUID.randomUUID() + "_" + Paths.get(file.getOriginalFilename()).getFileName().toString();
        File dest = new File(System.getProperty("user.dir"), safeName);
        file.transferTo(dest);

        return new HandWritingRecognizeResult(result);
    }

    @PostMapping("/audio_from_text")
    @RequireRole({2})
    Map<String, String> generateAudioFromText(@RequestBody Map<String, String> param, HttpServletRequest request) throws Exception {
        if (!param.containsKey("text") || param.get("text").isEmpty()) {
            throw new BusinessErrorException("收到内容为空的语音合成请求");
        }

        String text = param.get("text");

        if (text.length() > 100) {
            throw new BusinessErrorException("语音合成请求长度>100，拒绝响应");
        }

        String uid = (String) request.getAttribute("uid");

        String port = environment.getProperty("server.port");
        Future<String> future = flyTekManager.synthesisAudioFromText(text, uid, port);
        String url = future.get();

        String[] tokens = url.split("/");
        String fileName = tokens[tokens.length - 1];

        return Map.of("url", url, "name", fileName);
    }
}
