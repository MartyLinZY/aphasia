package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.apiproxy.HandWritingRecognizeResult;
import com.blkn.lr.lr_new_server.dto.apiproxy.TextSimilarityResult;
import com.blkn.lr.lr_new_server.dto.flytek.audio.AudioRecognizeResult;
import com.blkn.lr.lr_new_server.dto.apiproxy.FluencyResult;
import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.exception.ProxyServiceException;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.services.QwenAudioService;
import com.blkn.lr.lr_new_server.util.BaiduApiManager;
import com.blkn.lr.lr_new_server.util.FlyTekManager;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;
import java.util.concurrent.Future;

@Slf4j
@RestController
@RequestMapping("/api/proxy")
@RequiredArgsConstructor
public class ProxyController {

    private final BaiduApiManager baiduApi;
    private final QwenAudioService qwenAudioService;
    private final FlyTekManager flyTekManager;
    private final Environment environment;

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
        return new AudioRecognizeResult(result);
    }

    @PostMapping("/fluency")
    FluencyResult calFluency(@RequestParam("file") MultipartFile file) throws ProxyServiceException {
        try {
            return qwenAudioService.analyzeFluency(file.getBytes());
        } catch (Exception e) {
            log.error("qwen-audio 流畅度评估失败", e);
            throw new ProxyServiceException("流畅度评估失败", e);
        }
    }

    @PostMapping("/handwrite_recognize")
    HandWritingRecognizeResult recognizeHandleWriting(@RequestParam("file") MultipartFile file) throws Exception {
        String result = baiduApi.handWriteRecognize(file.getBytes());
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
