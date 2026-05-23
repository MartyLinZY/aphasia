package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.config.LlmApiConfig;
import com.blkn.lr.lr_new_server.dto.apiproxy.FluencyResult;
import com.blkn.lr.lr_new_server.util.WavUtil;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Base64;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 通过阿里通义千问音频多模态模型（qwen-audio-turbo-latest）
 * 对患者录音做 BDAE 0-10 言语流畅度评估，端到端取代旧的
 * 「停顿次数+重复+电报式+DNN困惑度」规则树。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class QwenAudioService {

    private static final MediaType JSON_MEDIA = MediaType.get("application/json; charset=utf-8");

    private static final String SYSTEM_PROMPT =
            "你是中文失语症言语评估师。你将听到一段汉语普通话录音，需要按 BDAE 言语流畅度 0-10 量表打分，并转写录音。"
                    + "评分标准：\n"
                    + "0 完全无词或短而无意义的言语；\n"
                    + "1 反复刻板的言语，少量意义；\n"
                    + "2 单个词，常为错语，费力并犹豫；\n"
                    + "3 流畅反复的咕哝，少量奇特语；\n"
                    + "4 踌躇、电报式言语，多为单个词，偶有动词或介词；\n"
                    + "5 电报式但有一定文法结构和少数陈述句，仍有明显错语；\n"
                    + "6 较完整的陈述句，可能有错语；\n"
                    + "7 流畅，可能滔滔不绝，可有音素错语或新造语；\n"
                    + "8 句子常完整但找词困难、有迂回说法、语义错语；\n"
                    + "9 大多数为完整且与主题有关的句子，偶有踌躇/错语；\n"
                    + "10 句子有正常长度和复杂性，无缓慢、踌躇、错语或发音困难。\n"
                    + "若录音完全无声或无可识别内容，fluency=0。\n"
                    + "严格只输出一个 JSON 对象，键固定为 fluency / detail / content，不要任何额外文字或代码块标记。";

    private static final String USER_INSTRUCTION =
            "请评估这段录音的言语流畅度，仅输出 JSON："
                    + "{\"fluency\": <0-10 整数>, \"detail\": \"<对应等级的简短中文描述>\", \"content\": \"<逐字转写，中文>\"}";

    private static final Pattern JSON_BLOCK = Pattern.compile("\\{[\\s\\S]*\\}");

    private final LlmApiConfig llmApiConfig;
    private final Gson gson = new Gson();

    private OkHttpClient client;

    private OkHttpClient client() {
        if (client == null) {
            int timeout = llmApiConfig.getAudioTimeoutSeconds();
            client = new OkHttpClient.Builder()
                    .connectTimeout(15, TimeUnit.SECONDS)
                    .readTimeout(timeout, TimeUnit.SECONDS)
                    .writeTimeout(timeout, TimeUnit.SECONDS)
                    .build();
        }
        return client;
    }

    public FluencyResult analyzeFluency(byte[] rawPcm16kMono) throws IOException {
        if (rawPcm16kMono == null || rawPcm16kMono.length == 0) {
            return new FluencyResult(0, "患者未说任何内容", "");
        }

        String apiKey = llmApiConfig.getApiKey();
        if (apiKey == null || apiKey.isBlank()) {
            throw new IOException("LLM_API_KEY 未配置，无法调用 qwen-audio");
        }

        byte[] wav = WavUtil.pcm16kMonoToWav(rawPcm16kMono);
        String audioDataUri = "data:audio/wav;base64," + Base64.getEncoder().encodeToString(wav);

        String body = buildRequestBody(audioDataUri);
        Request request = new Request.Builder()
                .url(llmApiConfig.getAudioUrl())
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .post(RequestBody.create(body, JSON_MEDIA))
                .build();

        try (Response response = client().newCall(request).execute()) {
            ResponseBody respBody = response.body();
            String text = respBody == null ? "" : respBody.string();
            if (!response.isSuccessful()) {
                log.warn("qwen-audio 调用失败: code={} body={}", response.code(), text);
                throw new IOException("qwen-audio HTTP " + response.code());
            }
            return parseFluencyResult(text);
        }
    }

    private String buildRequestBody(String audioDataUri) {
        JsonObject root = new JsonObject();
        root.addProperty("model", llmApiConfig.getAudioModel());

        JsonArray messages = new JsonArray();

        JsonObject systemMsg = new JsonObject();
        systemMsg.addProperty("role", "system");
        JsonArray systemContent = new JsonArray();
        JsonObject systemText = new JsonObject();
        systemText.addProperty("text", SYSTEM_PROMPT);
        systemContent.add(systemText);
        systemMsg.add("content", systemContent);
        messages.add(systemMsg);

        JsonObject userMsg = new JsonObject();
        userMsg.addProperty("role", "user");
        JsonArray userContent = new JsonArray();
        JsonObject audioPart = new JsonObject();
        audioPart.addProperty("audio", audioDataUri);
        userContent.add(audioPart);
        JsonObject textPart = new JsonObject();
        textPart.addProperty("text", USER_INSTRUCTION);
        userContent.add(textPart);
        userMsg.add("content", userContent);
        messages.add(userMsg);

        JsonObject input = new JsonObject();
        input.add("messages", messages);
        root.add("input", input);

        JsonObject parameters = new JsonObject();
        parameters.addProperty("result_format", "message");
        root.add("parameters", parameters);

        return gson.toJson(root);
    }

    private FluencyResult parseFluencyResult(String responseBody) throws IOException {
        JsonObject root = gson.fromJson(responseBody, JsonObject.class);
        if (root == null) {
            throw new IOException("qwen-audio 响应为空");
        }
        JsonObject output = root.getAsJsonObject("output");
        if (output == null) {
            throw new IOException("qwen-audio 响应缺少 output: " + responseBody);
        }
        JsonArray choices = output.getAsJsonArray("choices");
        if (choices == null || choices.size() == 0) {
            throw new IOException("qwen-audio 响应缺少 choices: " + responseBody);
        }
        JsonObject message = choices.get(0).getAsJsonObject().getAsJsonObject("message");
        if (message == null) {
            throw new IOException("qwen-audio 响应缺少 message: " + responseBody);
        }

        String assistantText = extractAssistantText(message);
        String jsonBlock = extractJsonBlock(assistantText);
        JsonObject result;
        try {
            result = gson.fromJson(jsonBlock, JsonObject.class);
        } catch (Exception e) {
            throw new IOException("qwen-audio 返回内容无法解析为 JSON: " + assistantText, e);
        }
        if (result == null) {
            throw new IOException("qwen-audio 返回 JSON 为空: " + assistantText);
        }

        double fluency = result.has("fluency") && !result.get("fluency").isJsonNull()
                ? result.get("fluency").getAsDouble() : 0;
        String detail = result.has("detail") && !result.get("detail").isJsonNull()
                ? result.get("detail").getAsString() : "";
        String content = result.has("content") && !result.get("content").isJsonNull()
                ? result.get("content").getAsString() : "";

        if (fluency < 0) fluency = 0;
        if (fluency > 10) fluency = 10;

        log.debug("qwen-audio 评分: fluency={}, content={}", fluency, content);
        return new FluencyResult(fluency, detail, content);
    }

    private String extractAssistantText(JsonObject message) {
        JsonElement content = message.get("content");
        if (content == null || content.isJsonNull()) {
            return "";
        }
        if (content.isJsonPrimitive()) {
            return content.getAsString();
        }
        if (content.isJsonArray()) {
            StringBuilder sb = new StringBuilder();
            for (JsonElement e : content.getAsJsonArray()) {
                if (e.isJsonObject() && e.getAsJsonObject().has("text")) {
                    sb.append(e.getAsJsonObject().get("text").getAsString());
                }
            }
            return sb.toString();
        }
        return content.toString();
    }

    private String extractJsonBlock(String text) {
        if (text == null || text.isEmpty()) {
            return "{}";
        }
        Matcher m = JSON_BLOCK.matcher(text);
        if (m.find()) {
            return m.group();
        }
        return text.trim();
    }
}
