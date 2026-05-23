package com.blkn.lr.lr_new_server.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

/**
 * LLM 接口配置（兼容 OpenAI 格式，如 OpenAI、DeepSeek、智谱等）
 */
@Configuration
public class LlmApiConfig {

    @Value("${llm.api.url:https://dashscope.aliyuncs.com/compatible-mode/v1}")
    private String apiUrl;

    @Value("${llm.api.key:}")
    private String apiKey;

    @Value("${llm.model:qwen-plus}")
    private String model;

    @Value("${llm.timeout-seconds:30}")
    private int timeoutSeconds;

    @Value("${llm.audio.url:https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation}")
    private String audioUrl;

    @Value("${llm.audio.model:qwen-audio-turbo-latest}")
    private String audioModel;

    @Value("${llm.audio.timeout-seconds:60}")
    private int audioTimeoutSeconds;

    public String getApiUrl() {
        return apiUrl;
    }

    public String getApiKey() {
        return apiKey;
    }

    public String getModel() {
        return model;
    }

    public int getTimeoutSeconds() {
        return timeoutSeconds;
    }

    public String getAudioUrl() {
        return audioUrl;
    }

    public String getAudioModel() {
        return audioModel;
    }

    public int getAudioTimeoutSeconds() {
        return audioTimeoutSeconds;
    }
}
