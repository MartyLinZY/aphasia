package com.blkn.lr.lr_new_server.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class FlyTekApiConfig {
    /// 这里必须是http/https，否则URL()无法识别
    private static final String AUDIO_RECOGNIZE_URL = "https://iat-api.xfyun.cn/v2/iat";
    private static final String AUDIO_SYNTHESIS_URL = "https://tts-api.xfyun.cn/v2/tts";

    @Value("${flytek.api.app-id:}")
    private String appId;

    @Value("${flytek.api.client-secret:}")
    private String clientSecret;

    @Value("${flytek.api.key:}")
    private String apiKey;

    public String getAudioRecognizeUrl() {
        return AUDIO_RECOGNIZE_URL;
    }

    public String getAudioSynthesisUrl() {
        return AUDIO_SYNTHESIS_URL;
    }

    public String getAppId() {
        return appId;
    }

    public String getClientSecret() {
        return clientSecret;
    }

    public String getApiKey() {
        return apiKey;
    }
}