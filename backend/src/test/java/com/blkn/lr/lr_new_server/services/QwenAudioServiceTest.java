package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.config.LlmApiConfig;
import com.blkn.lr.lr_new_server.dto.apiproxy.FluencyResult;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * QwenAudioService 单元测试。
 *
 * <p>Service 真实路径：base64 编码音频 → POST chat/completions（OpenAI 兼容）
 * → 读 SSE 流（{@code data: {...}\n\n} ... {@code data: [DONE]\n\n}）→ 拼 delta.content
 * → 在文本里正则抠 JSON 块 → fluency 截 0-10 → 返回 {@code FluencyResult}。
 *
 * <p>测试用 JDK HttpServer 模拟桩 endpoint，直接 chunked 写 SSE。重点覆盖：
 * <ul>
 *   <li>边界：空音频、apiKey 缺失</li>
 *   <li>HTTP 错误码 → IOException 含状态码</li>
 *   <li>SSE 多 chunk 拼接 → 解析 fluency / detail / content</li>
 *   <li>fluency 越界截断（&gt;10 → 10、&lt;0 → 0）</li>
 *   <li>SSE 中间有无法解析的 chunk → 跳过，不影响整体</li>
 *   <li>SSE 只有 [DONE] / 无 content → 抛空文本异常</li>
 *   <li>响应文本里没有 JSON 块 → 抛解析异常</li>
 * </ul>
 */
class QwenAudioServiceTest {

    private HttpServer server;
    private LlmApiConfig config;
    private QwenAudioService service;

    private final AtomicReference<Integer> httpStatus = new AtomicReference<>(200);
    private final AtomicReference<List<String>> sseEvents = new AtomicReference<>(List.of());
    private final AtomicReference<String> errorBody = new AtomicReference<>("");
    private final AtomicReference<String> lastAuthHeader = new AtomicReference<>();
    private final AtomicReference<String> lastRequestBody = new AtomicReference<>();

    @BeforeEach
    void setUp() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/audio", exchange -> {
            lastAuthHeader.set(exchange.getRequestHeaders().getFirst("Authorization"));
            lastRequestBody.set(readBody(exchange.getRequestBody()));
            int code = httpStatus.get();
            if (code != 200) {
                respond(exchange, code, errorBody.get());
                return;
            }
            // 200：以 SSE 流形式写回若干个 data: 行 + [DONE]
            exchange.getResponseHeaders().add("Content-Type", "text/event-stream; charset=utf-8");
            exchange.sendResponseHeaders(200, 0); // chunked
            try (OutputStream out = exchange.getResponseBody()) {
                for (String evt : sseEvents.get()) {
                    out.write(("data: " + evt + "\n\n").getBytes(StandardCharsets.UTF_8));
                    out.flush();
                }
                out.write("data: [DONE]\n\n".getBytes(StandardCharsets.UTF_8));
            }
            exchange.close();
        });
        server.start();

        config = mock(LlmApiConfig.class);
        when(config.getAudioUrl()).thenReturn("http://127.0.0.1:" + server.getAddress().getPort() + "/audio");
        when(config.getApiKey()).thenReturn("sk-test");
        when(config.getAudioModel()).thenReturn("qwen-audio-turbo-latest");
        when(config.getAudioTimeoutSeconds()).thenReturn(10);

        service = new QwenAudioService(config);
    }

    @AfterEach
    void tearDown() {
        if (server != null) server.stop(0);
    }

    // ============================================================
    // 边界：不打 HTTP 也能返回 / 抛
    // ============================================================

    @Test
    void analyzeShouldReturnZeroForNullAudio() throws IOException {
        FluencyResult r = service.analyzeFluency(null);
        assertEquals(0, r.getFluency());
        assertEquals("患者未说任何内容", r.getDetail());
        assertEquals("", r.getContent());
    }

    @Test
    void analyzeShouldReturnZeroForEmptyAudio() throws IOException {
        FluencyResult r = service.analyzeFluency(new byte[0]);
        assertEquals(0, r.getFluency());
        assertEquals("患者未说任何内容", r.getDetail());
    }

    @Test
    void analyzeShouldThrowWhenApiKeyMissing() {
        when(config.getApiKey()).thenReturn("");
        IOException e = assertThrows(IOException.class,
                () -> service.analyzeFluency(somePcm()));
        assertTrue(e.getMessage().contains("LLM_API_KEY"), e.getMessage());
    }

    @Test
    void analyzeShouldThrowWhenApiKeyIsBlank() {
        when(config.getApiKey()).thenReturn("   ");
        assertThrows(IOException.class, () -> service.analyzeFluency(somePcm()));
    }

    // ============================================================
    // HTTP 错误码
    // ============================================================

    @Test
    void analyzeShouldThrowOnHttp500WithStatusInMessage() {
        httpStatus.set(500);
        errorBody.set("{\"error\":\"model overloaded\"}");

        IOException e = assertThrows(IOException.class,
                () -> service.analyzeFluency(somePcm()));
        assertTrue(e.getMessage().contains("HTTP 500"), e.getMessage());
        assertTrue(e.getMessage().contains("model overloaded"), e.getMessage());
    }

    // ============================================================
    // 正常 SSE 流：单 chunk + 多 chunk 拼接
    // ============================================================

    @Test
    void analyzeShouldParseFluencyFromSingleChunkResponse() throws IOException {
        sseEvents.set(List.of(
                deltaContent("{\"fluency\":7,\"detail\":\"流畅\",\"content\":\"今天天气很好\"}")));

        FluencyResult r = service.analyzeFluency(somePcm());

        assertEquals(7.0, r.getFluency());
        assertEquals("流畅", r.getDetail());
        assertEquals("今天天气很好", r.getContent());
        // Bearer header 正确拼装
        assertEquals("Bearer sk-test", lastAuthHeader.get());
        // 请求体应包含 base64 audio 标签 + model
        String body = lastRequestBody.get();
        assertTrue(body.contains("input_audio"), "应有 input_audio 节点");
        assertTrue(body.contains("data:audio/wav;base64,"), "应是 base64 data URI");
        assertTrue(body.contains("qwen-audio-turbo-latest"), "应用配置 model");
        assertTrue(body.contains("\"stream\":true"), "应启用 stream");
    }

    @Test
    void analyzeShouldConcatenateMultipleChunks() throws IOException {
        sseEvents.set(List.of(
                deltaContent("{\"fluency\":5,"),
                deltaContent("\"detail\":\"中等\","),
                deltaContent("\"content\":\"你好\"}")));

        FluencyResult r = service.analyzeFluency(somePcm());

        assertEquals(5.0, r.getFluency());
        assertEquals("中等", r.getDetail());
        assertEquals("你好", r.getContent());
    }

    @Test
    void analyzeShouldExtractJsonBlockFromSurroundingText() throws IOException {
        // 模型有时会在 JSON 前后冒出说明文字，extractJsonBlock 用正则抠
        sseEvents.set(List.of(
                deltaContent("结果如下：{\"fluency\":3,\"detail\":\"较差\",\"content\":\"嗯\"} 完成")));

        FluencyResult r = service.analyzeFluency(somePcm());
        assertEquals(3.0, r.getFluency());
        assertEquals("较差", r.getDetail());
    }

    // ============================================================
    // fluency 截断 / 缺字段降级
    // ============================================================

    @Test
    void analyzeShouldClampFluencyAbove10() throws IOException {
        sseEvents.set(List.of(
                deltaContent("{\"fluency\":99,\"detail\":\"超出\",\"content\":\"x\"}")));

        FluencyResult r = service.analyzeFluency(somePcm());
        assertEquals(10.0, r.getFluency());
    }

    @Test
    void analyzeShouldClampFluencyBelow0() throws IOException {
        sseEvents.set(List.of(
                deltaContent("{\"fluency\":-3,\"detail\":\"异常\",\"content\":\"x\"}")));

        FluencyResult r = service.analyzeFluency(somePcm());
        assertEquals(0.0, r.getFluency());
    }

    @Test
    void analyzeShouldDefaultMissingFieldsToZeroAndEmptyString() throws IOException {
        // 模型只输出了 fluency，没给 detail / content
        sseEvents.set(List.of(deltaContent("{\"fluency\":4}")));

        FluencyResult r = service.analyzeFluency(somePcm());
        assertEquals(4.0, r.getFluency());
        assertEquals("", r.getDetail());
        assertEquals("", r.getContent());
    }

    @Test
    void analyzeShouldTreatNullFieldsAsDefaults() throws IOException {
        sseEvents.set(List.of(deltaContent(
                "{\"fluency\":null,\"detail\":null,\"content\":null}")));

        FluencyResult r = service.analyzeFluency(somePcm());
        assertEquals(0.0, r.getFluency());
        assertEquals("", r.getDetail());
        assertEquals("", r.getContent());
    }

    // ============================================================
    // SSE 不规整：跳过坏 chunk，不应导致整次失败
    // ============================================================

    @Test
    void analyzeShouldSkipUnparseableSseChunks() throws IOException {
        sseEvents.set(List.of(
                "not-json-at-all",               // 整块就不是 JSON
                "{\"choices\":[]}",              // 缺 delta
                deltaContent("{\"fluency\":6,\"detail\":\"OK\",\"content\":\"\"}")));

        FluencyResult r = service.analyzeFluency(somePcm());
        assertEquals(6.0, r.getFluency());
        assertEquals("OK", r.getDetail());
    }

    @Test
    void analyzeShouldTreatNullDeltaContentAsSkippable() throws IOException {
        // 阿里返回的某些 chunk delta.content 字段可能是 null（首块/末块）
        sseEvents.set(List.of(
                "{\"choices\":[{\"delta\":{\"role\":\"assistant\",\"content\":null}}]}",
                deltaContent("{\"fluency\":8,\"detail\":\"流利\",\"content\":\"句子\"}")));

        FluencyResult r = service.analyzeFluency(somePcm());
        assertEquals(8.0, r.getFluency());
    }

    // ============================================================
    // SSE 流为空 / 解析失败
    // ============================================================

    @Test
    void analyzeShouldThrowWhenSseOnlyHasDone() {
        sseEvents.set(List.of()); // 只会写 [DONE]
        IOException e = assertThrows(IOException.class,
                () -> service.analyzeFluency(somePcm()));
        assertTrue(e.getMessage().contains("返回空文本"), e.getMessage());
    }

    @Test
    void analyzeShouldThrowWhenNoJsonBlockAndNotValidJson() {
        // assistantText 不空，但 extractJsonBlock 兜底返回原文，gson 解析失败
        sseEvents.set(List.of(deltaContent("纯文本无大括号")));

        IOException e = assertThrows(IOException.class,
                () -> service.analyzeFluency(somePcm()));
        assertTrue(e.getMessage().contains("无法解析为 JSON")
                        || e.getMessage().contains("返回内容"),
                e.getMessage());
    }

    // ============================================================
    // helpers
    // ============================================================

    /** 一段非空的 16k mono PCM 字节（数据本身不重要，长度 > 0 即可触达 HTTP 路径）。*/
    private static byte[] somePcm() {
        byte[] data = new byte[640]; // 20ms @ 16kHz s16
        for (int i = 0; i < data.length; i++) data[i] = (byte) (i & 0xff);
        return data;
    }

    /** 构造一条 OpenAI 兼容的 SSE chunk —— delta.content = embeddedText。*/
    private static String deltaContent(String embeddedText) {
        String escaped = embeddedText
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n");
        return "{\"choices\":[{\"delta\":{\"content\":\"" + escaped + "\"}}]}";
    }

    private static String readBody(InputStream in) {
        try (InputStream is = in) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static void respond(HttpExchange exchange, int code, String body) {
        try {
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json; charset=utf-8");
            exchange.sendResponseHeaders(code, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
