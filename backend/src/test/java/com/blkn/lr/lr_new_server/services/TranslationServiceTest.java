package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.config.LlmApiConfig;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * TranslationService 单元测试。
 *
 * <p>用 JDK 内置 HttpServer 桩 OpenAI 兼容的 chat/completions 端点。
 * Service 里的 OkHttpClient 是 final 字段直接创建的，但接 localhost
 * 没问题——不需要也不该 mock 这个 client。
 *
 * <p>覆盖矩阵：① 输入清洗（null / 空 / 全空白） / ② 配置缺失（apiKey 空）/
 * ③ HTTP 成功（解析 choices[0].message.content） / ④ HTTP 错误码 fallback /
 * ⑤ 响应 JSON 各种不规整形态 fallback（null / 无 choices / 空 choices /
 * 无 message / blank content）/ ⑥ buildChatCompletionsUrl URL 拼装变体。
 */
class TranslationServiceTest {

    private HttpServer server;
    private LlmApiConfig config;
    private TranslationService service;

    private final AtomicReference<Integer> httpStatus = new AtomicReference<>(200);
    private final AtomicReference<String> responseBody = new AtomicReference<>("");
    private final AtomicReference<String> lastRequestBody = new AtomicReference<>();
    private final AtomicReference<String> lastAuthHeader = new AtomicReference<>();

    @BeforeEach
    void setUp() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/chat/completions", exchange -> {
            lastRequestBody.set(readBody(exchange.getRequestBody()));
            lastAuthHeader.set(exchange.getRequestHeaders().getFirst("Authorization"));
            respond(exchange, httpStatus.get(), responseBody.get());
        });
        server.start();

        config = mock(LlmApiConfig.class);
        when(config.getApiUrl()).thenReturn("http://127.0.0.1:" + server.getAddress().getPort() + "/v1");
        when(config.getApiKey()).thenReturn("sk-test");
        when(config.getModel()).thenReturn("qwen-plus");

        service = new TranslationService(config);
    }

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    // ============================================================
    // 输入清洗 —— 不应触达 HTTP
    // ============================================================

    @Test
    void translateShouldReturnEmptyForNullInput() {
        assertEquals("", service.translate(null));
        // 不应发起请求
        assertEquals(null, lastRequestBody.get());
    }

    @Test
    void translateShouldReturnEmptyForEmptyString() {
        assertEquals("", service.translate(""));
    }

    @Test
    void translateShouldReturnEmptyForWhitespaceOnly() {
        assertEquals("", service.translate("   \n\t  "));
    }

    // ============================================================
    // 配置缺失 —— 直接回退原文，不报错（friendly degrade）
    // ============================================================

    @Test
    void translateShouldReturnOriginalTextWhenApiKeyIsNull() {
        when(config.getApiKey()).thenReturn(null);
        assertEquals("原文", service.translate("原文"));
    }

    @Test
    void translateShouldReturnOriginalTextWhenApiKeyIsBlank() {
        when(config.getApiKey()).thenReturn("   ");
        assertEquals("原文", service.translate("原文"));
    }

    // ============================================================
    // HTTP 成功路径
    // ============================================================

    @Test
    void translateShouldParseContentFromHappyPathResponse() {
        httpStatus.set(200);
        responseBody.set("{\"choices\":[{\"message\":{\"role\":\"assistant\",\"content\":\"我要喝水。\"}}]}");

        assertEquals("我要喝水。", service.translate("我要 水"));

        // 校验请求体携带 system+user 两条 message 且使用了配置的 model
        String body = lastRequestBody.get();
        assertTrue(body.contains("\"model\":\"qwen-plus\""), "应使用配置的 model: " + body);
        assertTrue(body.contains("\"role\":\"system\""), "应有 system message");
        assertTrue(body.contains("\"role\":\"user\""), "应有 user message");
        assertTrue(body.contains("我要 水"), "user content 应原样透传");
        // Bearer header 正确拼装
        assertEquals("Bearer sk-test", lastAuthHeader.get());
    }

    @Test
    void translateShouldTrimWhitespaceFromContent() {
        httpStatus.set(200);
        responseBody.set("{\"choices\":[{\"message\":{\"content\":\"  我要喝水。 \\n\"}}]}");

        assertEquals("我要喝水。", service.translate("我要 水"));
    }

    // ============================================================
    // HTTP 错误码 —— 回退原文（不抛异常）
    // ============================================================

    @Test
    void translateShouldFallbackToOriginalOnHttpError() {
        httpStatus.set(500);
        responseBody.set("{\"error\":\"upstream timeout\"}");

        assertEquals("原文", service.translate("原文"));
    }

    @Test
    void translateShouldFallbackToOriginalOn4xx() {
        httpStatus.set(401);
        responseBody.set("{\"error\":\"invalid key\"}");

        assertEquals("原文", service.translate("原文"));
    }

    // ============================================================
    // 响应 JSON 不规整 —— 全部回退原文
    // ============================================================

    @Test
    void translateShouldFallbackWhenResponseIsNotJson() {
        httpStatus.set(200);
        responseBody.set("not a json");
        assertEquals("原文", service.translate("原文"));
    }

    @Test
    void translateShouldFallbackWhenChoicesMissing() {
        httpStatus.set(200);
        responseBody.set("{\"id\":\"abc\"}");
        assertEquals("原文", service.translate("原文"));
    }

    @Test
    void translateShouldFallbackWhenChoicesEmpty() {
        httpStatus.set(200);
        responseBody.set("{\"choices\":[]}");
        assertEquals("原文", service.translate("原文"));
    }

    @Test
    void translateShouldFallbackWhenMessageMissing() {
        httpStatus.set(200);
        responseBody.set("{\"choices\":[{\"finish_reason\":\"stop\"}]}");
        assertEquals("原文", service.translate("原文"));
    }

    @Test
    void translateShouldFallbackWhenContentBlank() {
        httpStatus.set(200);
        responseBody.set("{\"choices\":[{\"message\":{\"content\":\"   \"}}]}");
        assertEquals("原文", service.translate("原文"));
    }

    // ============================================================
    // buildChatCompletionsUrl 拼装变体（通过观察实际发起的请求行为间接验证）
    // ============================================================

    @Test
    void translateShouldWorkWhenApiUrlAlreadyEndsWithChatCompletions() {
        // 用户配的 url 已经是完整 endpoint 而非 base URL
        when(config.getApiUrl()).thenReturn("http://127.0.0.1:" + server.getAddress().getPort() + "/v1/chat/completions");
        httpStatus.set(200);
        responseBody.set("{\"choices\":[{\"message\":{\"content\":\"ok\"}}]}");

        assertEquals("ok", service.translate("foo"));
    }

    @Test
    void translateShouldWorkWhenApiUrlHasTrailingSlash() {
        when(config.getApiUrl()).thenReturn("http://127.0.0.1:" + server.getAddress().getPort() + "/v1/");
        httpStatus.set(200);
        responseBody.set("{\"choices\":[{\"message\":{\"content\":\"ok\"}}]}");

        assertEquals("ok", service.translate("foo"));
    }

    // ============================================================
    // helpers
    // ============================================================

    private static String readBody(InputStream in) {
        try (InputStream is = in) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static void respond(HttpExchange exchange, int code, String json) {
        try {
            byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json; charset=utf-8");
            exchange.sendResponseHeaders(code, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
