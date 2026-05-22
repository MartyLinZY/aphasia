package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.InputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 验证 LLMService 通过 HTTP 调用 FastAPI 微服务的契约：
 * 用 JDK 内置 HttpServer 起桩服务模拟 FastAPI，覆盖成功与错误两条路径。
 */
class LLMServiceTest {

    private HttpServer server;
    private LLMService llmService;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AtomicReference<String> lastPath = new AtomicReference<>();
    private final AtomicReference<String> lastBody = new AtomicReference<>();

    @BeforeEach
    void setUp() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);

        // diagnose1：返回大模型诊断结果
        server.createContext("/diagnose1", exchange -> {
            lastPath.set("/diagnose1");
            lastBody.set(readBody(exchange.getRequestBody()));
            respond(exchange, 200,
                    "{\"type\":\"运动性失语\",\"severity\":\"中度\",\"error\":\"无\",\"LLManswer\":\"是 运动性失语 中度\"}");
        });

        // diagnose2：返回困惑度
        server.createContext("/diagnose2", exchange -> {
            lastPath.set("/diagnose2");
            lastBody.set(readBody(exchange.getRequestBody()));
            respond(exchange, 200, "{\"perplexity\":123.45}");
        });

        // repair：返回修复后的句子
        server.createContext("/repair", exchange -> {
            lastPath.set("/repair");
            lastBody.set(readBody(exchange.getRequestBody()));
            respond(exchange, 200, "{\"repairedConversation\":\"我想喝水。\"}");
        });

        // 模拟服务端 500
        server.createContext("/boom", exchange -> respond(exchange, 500, "{\"detail\":\"模型加载失败\"}"));

        server.start();

        llmService = new LLMService();
        String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        ReflectionTestUtils.setField(llmService, "llmServiceUrl", baseUrl);
    }

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void diagnose1ShouldPostConversationAndParseResult() throws Exception {
        Map<String, Object> result = llmService.diagnose1("医生：你好\n患者：水...喝");

        assertEquals("/diagnose1", lastPath.get());
        // 请求体应为 {"conversation": "..."}
        Map<String, Object> sentBody = objectMapper.readValue(lastBody.get(), Map.class);
        assertEquals("医生：你好\n患者：水...喝", sentBody.get("conversation"));
        // 响应解析
        assertEquals("运动性失语", result.get("type"));
        assertEquals("中度", result.get("severity"));
        assertEquals("无", result.get("error"));
    }

    @Test
    void diagnose2ShouldParsePerplexity() throws Exception {
        Map<String, Object> result = llmService.diagnose2("患者：水...喝");

        assertEquals("/diagnose2", lastPath.get());
        assertEquals(123.45, ((Number) result.get("perplexity")).doubleValue(), 1e-6);
    }

    @Test
    void repairShouldParseRepairedConversation() throws Exception {
        Map<String, Object> result = llmService.repair("我...水...");

        assertEquals("/repair", lastPath.get());
        assertEquals("我想喝水。", result.get("repairedConversation"));
    }

    @Test
    void shouldThrowBusinessErrorWhenServiceReturns500() {
        // 将服务地址指向 /boom 上层（用一个会命中 500 的路径）
        String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        ReflectionTestUtils.setField(llmService, "llmServiceUrl", baseUrl + "/boom");

        BusinessErrorException ex = assertThrows(BusinessErrorException.class,
                () -> llmService.diagnose1("任意"));
        assertTrue(ex.getMessage().contains("HTTP 500"));
    }

    private static String readBody(InputStream in) {
        try (InputStream is = in) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static void respond(com.sun.net.httpserver.HttpExchange exchange, int code, String json) {
        try {
            byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json; charset=utf-8");
            exchange.sendResponseHeaders(code, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
