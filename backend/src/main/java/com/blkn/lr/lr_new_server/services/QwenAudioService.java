package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.config.LlmApiConfig;
import com.blkn.lr.lr_new_server.dto.apiproxy.FluencyResult;
import com.blkn.lr.lr_new_server.util.WavUtil;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 通过阿里通义千问 Omni 多模态模型对患者录音做 BDAE 0-10 言语流畅度评估。
 * Omni 系列在 Dashscope 上只支持 OpenAI 兼容模式 + 流式输出 (stream:true)。
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
        String audioDataUri = "data:;base64," + Base64.getEncoder().encodeToString(wav);

        String body = buildRequestBody(audioDataUri);
        Request request = new Request.Builder()
                .url(llmApiConfig.getAudioUrl())
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .header("Accept", "text/event-stream")
                .post(RequestBody.create(body, JSON_MEDIA))
                .build();

        try (Response response = client().newCall(request).execute()) {
            ResponseBody respBody = response.body();
            if (!response.isSuccessful()) {
                String errText = respBody == null ? "" : respBody.string();
                log.warn("qwen-audio 调用失败: code={} body={}", response.code(), errText);
                throw new IOException("qwen-audio HTTP " + response.code() + ": " + errText);
            }
            if (respBody == null) {
                throw new IOException("qwen-audio 响应 body 为空");
            }
            String assistantText = readSseStream(respBody);
            return parseFluencyResult(assistantText);
        }
    }

    private String buildRequestBody(String audioDataUri) {
        JsonObject root = new JsonObject();
        root.addProperty("model", llmApiConfig.getAudioModel());

        JsonArray messages = new JsonArray();

        JsonObject systemMsg = new JsonObject();
        systemMsg.addProperty("role", "system");
        systemMsg.addProperty("content", SYSTEM_PROMPT);
        messages.add(systemMsg);

        JsonObject userMsg = new JsonObject();
        userMsg.addProperty("role", "user");
        JsonArray userContent = new JsonArray();

        JsonObject audioPart = new JsonObject();
        audioPart.addProperty("type", "input_audio");
        JsonObject inputAudio = new JsonObject();
        inputAudio.addProperty("data", audioDataUri);
        inputAudio.addProperty("format", "wav");
        audioPart.add("input_audio", inputAudio);
        userContent.add(audioPart);

        JsonObject textPart = new JsonObject();
        textPart.addProperty("type", "text");
        textPart.addProperty("text", USER_INSTRUCTION);
        userContent.add(textPart);

        userMsg.add("content", userContent);
        messages.add(userMsg);

        root.add("messages", messages);

        JsonArray modalities = new JsonArray();
        modalities.add("text");
        root.add("modalities", modalities);

        root.addProperty("stream", true);
        JsonObject streamOptions = new JsonObject();
        streamOptions.addProperty("include_usage", true);
        root.add("stream_options", streamOptions);

        return gson.toJson(root);
    }

    /**
     * 读取 SSE 流，把每个 chunk 的 delta.content 拼起来。
     */
    private String readSseStream(ResponseBody respBody) throws IOException {
        StringBuilder full = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(respBody.byteStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isEmpty() || !line.startsWith("data:")) {
                    continue;
                }
                String payload = line.substring(5).trim();
                if ("[DONE]".equals(payload)) {
                    break;
                }
                try {
                    JsonObject chunk = gson.fromJson(payload, JsonObject.class);
                    if (chunk == null) continue;
                    JsonArray choices = chunk.getAsJsonArray("choices");
                    if (choices == null || choices.size() == 0) continue;
                    JsonObject delta = choices.get(0).getAsJsonObject().getAsJsonObject("delta");
                    if (delta == null) continue;
                    if (delta.has("content") && !delta.get("content").isJsonNull()) {
                        full.append(delta.get("content").getAsString());
                    }
                } catch (Exception e) {
                    log.debug("跳过无法解析的 SSE 块: {}", payload);
                }
            }
        }
        log.debug("qwen-audio SSE 完整文本: {}", full);
        return full.toString();
    }

    private FluencyResult parseFluencyResult(String assistantText) throws IOException {
        if (assistantText == null || assistantText.isBlank()) {
            throw new IOException("qwen-audio 返回空文本");
        }
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
