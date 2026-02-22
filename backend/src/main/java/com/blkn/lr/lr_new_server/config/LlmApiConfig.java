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
}
