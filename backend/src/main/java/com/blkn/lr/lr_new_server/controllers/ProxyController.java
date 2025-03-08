package com.blkn.lr.lr_new_server.controllers;

import com.alibaba.fastjson.JSONObject;
import com.blkn.lr.lr_new_server.dto.apiproxy.HandWritingRecognizeResult;
import com.blkn.lr.lr_new_server.dto.apiproxy.TextSimilarityResult;
import com.blkn.lr.lr_new_server.dto.flytek.audio.AudioRecognizeResult;
import com.blkn.lr.lr_new_server.dto.apiproxy.FluencyResult;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.expection.FlyTekApiException;
import com.blkn.lr.lr_new_server.util.BaiduApiManager;
import com.blkn.lr.lr_new_server.util.FlyTekManager;
import com.blkn.lr.lr_new_server.util.ThreadPools;
import com.blkn.lr.lr_new_server.util.fluency.FluencyProcessor;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Future;

@RestController
@RequestMapping("/api/proxy")
public class ProxyController {

    @Autowired
    private BaiduApiManager baiduApi;

    @Autowired
    private FluencyProcessor processor;


    @Autowired
    Environment environment;

    @PostMapping("/text_similarity")
    TextSimilarityResult calTextSimilarity(@RequestParam("text1") String text1, @RequestParam("text2") String text2) {
        System.out.println(text1);
        System.out.println(text2);
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
        Future<String> future = FlyTekManager.getInstance().recognizeAudio(file.getBytes());
        String result = future.get();
//        System.out.println("收到一次语音识别请求");
//        String result = "测试结果";
        File dest = new File(System.getProperty("user.dir")+ File.separator + file.getOriginalFilename());
        file.transferTo(dest);

        return new AudioRecognizeResult(result);
    }

    @PostMapping("/fluency")
    FluencyResult calFluency(@RequestParam("file") MultipartFile file) throws FlyTekApiException {
        try {
            Future<String> future = FlyTekManager.getInstance().recognizeAudio(file.getBytes());
            String audioContent = future.get();
            System.out.println(audioContent);
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
//                    System.out.println("stop finish");
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            });

            ThreadPools.fluencyCalculator.submit(() -> {
                repeatFuture.complete(processor.repeat(audioContent));
//                System.out.println("repeat finish");
            });

            ThreadPools.fluencyCalculator.submit(() -> {
                try {
                    telegramFuture.complete(processor.Telegram_Language(audioContent));
//                    System.out.println("telegram finish");
                } catch (Exception e) {
                    e.printStackTrace();
                }
            });

            ThreadPools.fluencyCalculator.submit(() -> {
                try {
                    dnnFuture.complete((double) baiduApi.dnn(audioContent).get("ppl") / audioContent.length());
//                    System.out.println("dnn finish");
                } catch (Exception e) {
                    e.printStackTrace();
                }

            });

            boolean repeat = repeatFuture.get();
//            System.out.println("repeat:" + repeat);
            int stopTimes = stopFuture.get();
//            System.out.println("stop:" + stopTimes);
            JSONObject telegram = telegramFuture.get();
//            System.out.println("tele:" + telegram.get("value"));
            double dnn = dnnFuture.get();
//            System.out.println("dnn" + dnn);

            StringBuilder detail = new StringBuilder();
            double fluency = processor.fluency_score(1, stopTimes, repeat,telegram, dnn, detail);
            return new FluencyResult(fluency, detail.toString(), audioContent);
//            return new FluencyResult(1, "213");
        } catch (Exception e) {
            throw new FlyTekApiException();
        }
    }

    @PostMapping("/handwrite_recognize")
    HandWritingRecognizeResult recognizeHandleWriting(@RequestParam("file") MultipartFile file) throws Exception {
        String result = baiduApi.handWriteRecognize(file.getBytes());

//        System.out.println("收到一次手写识别请求");
//        String result = "测试结果";
        File dest = new File(System.getProperty("user.dir")+ File.separator + file.getOriginalFilename());
        file.transferTo(dest);

        return new HandWritingRecognizeResult(result);
    }

    @PostMapping("/audio_from_text")
    Map<String, String> generateAudioFromText(@RequestBody Map<String, String> param, HttpServletRequest request) throws Exception {
        if (!param.containsKey("text") || param.get("text").isEmpty()) {
            throw new BusinessErrorException("收到内容为空的语音合成请求");
        }

        String text = param.get("text");

        if (text.length() > 100) {
            throw new BusinessErrorException("语音合成请求长度>100，拒绝响应");
        }

        String uid = (String) request.getAttribute("uid");
        int uType = (int) request.getAttribute("uType");

        if (uType != 2) {
            throw new BusinessErrorException("收到非法的语音合成请求，用户不为医生");
        }

        String port = environment.getProperty("server.port");
        Future<String> future = FlyTekManager.getInstance().synthesisAudioFromText(text, uid, port);
        String url = future.get();

        String[] tokens = url.split("/");
        String fileName = tokens[tokens.length - 1];

        return Map.of("url", url, "name", fileName);
    }
}
