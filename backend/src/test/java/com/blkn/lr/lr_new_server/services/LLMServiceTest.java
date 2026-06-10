package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
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

        // diagnose2：返回特征诊断结果（旧 diagnose1/困惑度已删除）
        server.createContext("/diagnose2", exchange -> {
            lastPath.set("/diagnose2");
            lastBody.set(readBody(exchange.getRequestBody()));
            respond(exchange, 200,
                    "{\"hasAphasia\":true,\"severity\":\"中度\",\"score\":4.5,\"evidence\":[\"短而简化\"]}");
        });

        // repair：返回修复后的句子
        server.createContext("/repair", exchange -> {
            lastPath.set("/repair");
            lastBody.set(readBody(exchange.getRequestBody()));
            respond(exchange, 200, "{\"repairedConversation\":\"我想喝水。\"}");
        });

        // 模拟服务端 500：注册到精确路径，避免依赖 HttpContext 前缀匹配
        server.createContext("/boom/diagnose2",
                exchange -> respond(exchange, 500, "{\"detail\":\"特征抽取失败\"}"));

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
    void diagnose2ShouldPostConversationAndParseResult() throws Exception {
        Map<String, Object> result = llmService.diagnose2("医生：你好\n患者：水...喝");

        assertEquals("/diagnose2", lastPath.get());
        // 请求体应为 {"conversation": "..."}
        Map<String, Object> sentBody = objectMapper.readValue(lastBody.get(), Map.class);
        assertEquals("医生：你好\n患者：水...喝", sentBody.get("conversation"));
        // 响应解析：特征诊断结构
        assertEquals(true, result.get("hasAphasia"));
        assertEquals("中度", result.get("severity"));
        assertEquals(4.5, ((Number) result.get("score")).doubleValue(), 1e-6);
    }

    @Test
    void repairShouldParseRepairedConversation() throws Exception {
        Map<String, Object> result = llmService.repair("我...水...");

        assertEquals("/repair", lastPath.get());
        assertEquals("我想喝水。", result.get("repairedConversation"));
    }

    @Test
    void shouldThrowBusinessErrorWhenServiceReturns500() {
        // 将 baseUrl 指向 /boom，使 diagnose2() 拼出 /boom/diagnose2 命中桩 500 路径
        String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        ReflectionTestUtils.setField(llmService, "llmServiceUrl", baseUrl + "/boom");

        BusinessErrorException ex = assertThrows(BusinessErrorException.class,
                () -> llmService.diagnose2("任意"));
        assertTrue(ex.getMessage().contains("HTTP 500"),
                "异常 message 应明确包含 HTTP 500 状态：" + ex.getMessage());
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
