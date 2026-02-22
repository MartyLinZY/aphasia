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
            "你是一个辅助失语症患者说话的助手。用户可能输入不完整、语序混乱或语义不合理的句子。"
                    + "请根据情况对文本进行补全、调整语序或修改为合理表达，然后输出修改后的完整、通顺的中文内容。"
                    + "若用户未指定目标语言，默认结果为中文。只输出最终结果，不要解释过程。\n\n"
                    + "参考示例：\n\n"
                    + "【补全】不完整表达 → 补全为完整句：\n"
                    + "  输入：我要…水  输出：我要喝水。\n"
                    + "  输入：今天 天气  输出：今天天气很好。\n"
                    + "  输入：去医院 看病  输出：我要去医院看病。\n\n"
                    + "【调整语序】词序错乱 → 调整为正常语序：\n"
                    + "  输入：饭吃我  输出：我吃饭。\n"
                    + "  输入：球踢 孩子 在 操场  输出：孩子在操场踢球。\n"
                    + "  输入：妈妈 菜 买 去 市场  输出：妈妈去市场买菜。\n\n"
                    + "【修改不合理句子】语义或搭配不当 → 改为合理表达：\n"
                    + "  输入：苹果吃电视  输出：我在吃苹果。（或根据语境改为合理句子）\n"
                    + "  输入：下雨太阳  输出：今天下雨了，没有太阳。（或：一会儿下雨一会儿出太阳。）\n"
                    + "  输入：狗 飞 天上  输出：狗在地上跑。（或根据患者可能想表达的意思改为合理句子）\n";

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
