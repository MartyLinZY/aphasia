package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.config.LlmApiConfig;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * 翻译服务：通过 LLM 对输入文本进行补全/猜测含义并输出翻译结果。
 */
@Service
public class TranslationService {

    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");
    private static final String SYSTEM_PROMPT =
            "你是一个辅助失语症患者说话的助手。用户可能输入不完整、含糊或有语病的句子。"
                    + "请先根据上下文补全或合理猜测其含义，然后输出修改后的完整、通顺的内容，保证语句的意思能够符合现实场景并且符合常规语句的表达方式。"
                    + "若用户未指定目标语言，默认结果为中文。只输出最终结果，不要解释过程。";

    @Autowired
    private LlmApiConfig llmApiConfig;

    private final OkHttpClient client = new OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();

    private final Gson gson = new Gson();

    /**
     * 调用 LLM 对文本进行补全或猜测含义，并返回翻译后的内容。
     *
     * @param text 原始文本
     * @return 翻译后的内容；若未配置 API Key 或调用失败则返回原文本或错误信息
     */
    public String translate(String text) {
        if (text == null) {
            return "";
        }
        text = text.trim();
        if (text.isEmpty()) {
            return "";
        }

        String apiKey = llmApiConfig.getApiKey();
        if (apiKey == null || apiKey.isBlank()) {
            return text;
        }
 
        try {
            String responseBody = callLlm(text);
            return parseTranslationFromResponse(responseBody, text);
        } catch (IOException e) {
            return text;
        }
    }

    private String callLlm(String userText) throws IOException {
        JsonObject body = new JsonObject();
        body.addProperty("model", llmApiConfig.getModel());

        JsonArray messages = new JsonArray();
        JsonObject systemMsg = new JsonObject();
        systemMsg.addProperty("role", "system");
        systemMsg.addProperty("content", SYSTEM_PROMPT);
        messages.add(systemMsg);

        JsonObject userMsg = new JsonObject();
        userMsg.addProperty("role", "user");
        userMsg.addProperty("content", userText);
        messages.add(userMsg);

        body.add("messages", messages);

        String requestUrl = buildChatCompletionsUrl(llmApiConfig.getApiUrl());
        Request request = new Request.Builder()
                .url(requestUrl)
                .header("Authorization", "Bearer " + llmApiConfig.getApiKey())
                .header("Content-Type", "application/json")
                .post(RequestBody.create(gson.toJson(body), JSON))
                .build();

        try (Response response = client.newCall(request).execute()) {
            ResponseBody responseBody = response.body();
            if (responseBody == null) {
                throw new IOException("Response body is null");
            }
            if (!response.isSuccessful()) {
                throw new IOException("LLM API error: " + response.code() + " " + responseBody.string());
            }
            return responseBody.string();
        }
    }

    /** 若配置的是 base URL（以 /v1 结尾），则追加 /chat/completions */
    private String buildChatCompletionsUrl(String apiUrl) {
        if (apiUrl == null || apiUrl.isEmpty()) {
            return apiUrl;
        }
        String u = apiUrl.trim();
        if (u.endsWith("/chat/completions")) {
            return u;
        }
        return u.endsWith("/") ? u + "chat/completions" : u + "/chat/completions";
    }

    private String parseTranslationFromResponse(String responseBody, String fallback) {
        try {
            JsonObject root = gson.fromJson(responseBody, JsonObject.class);
            if (root == null) {
                return fallback;
            }
            JsonArray choices = root.getAsJsonArray("choices");
            if (choices == null || choices.size() == 0) {
                return fallback;
            }
            JsonObject first = choices.get(0).getAsJsonObject();
            JsonObject message = first.getAsJsonObject("message");
            if (message == null) {
                return fallback;
            }
            String content = message.has("content") ? message.get("content").getAsString() : null;
            return (content != null && !content.isBlank()) ? content.trim() : fallback;
        } catch (Exception e) {
            return fallback;
        }
    }
}
