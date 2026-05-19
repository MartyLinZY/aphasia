package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * LLM 诊断/修复服务：通过 HTTP 调用 FastAPI 微服务（LLM/app.py）。
 */
@Slf4j
@Service
public class LLMService {

    private static final MediaType JSON_TYPE = MediaType.get("application/json; charset=utf-8");
    private static final TypeReference<Map<String, Object>> MAP_REF = new TypeReference<>() {};

    @Value("${llm.service.url:http://127.0.0.1:8001}")
    private String llmServiceUrl;

    private final OkHttpClient client = new OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();

    private final ObjectMapper objectMapper = new ObjectMapper();

    public Map<String, Object> diagnose1(String conversation) throws Exception {
        return call("/diagnose1", conversation);
    }

    public Map<String, Object> diagnose2(String conversation) throws Exception {
        return call("/diagnose2", conversation);
    }

    public Map<String, Object> repair(String conversation) throws Exception {
        return call("/repair", conversation);
    }

    private Map<String, Object> call(String path, String conversation) throws Exception {
        String bodyJson = objectMapper.writeValueAsString(Map.of("conversation", conversation));
        Request request = new Request.Builder()
                .url(llmServiceUrl + path)
                .post(RequestBody.create(bodyJson, JSON_TYPE))
                .build();

        log.debug("调用 LLM 服务: {}", path);
        try (Response response = client.newCall(request).execute()) {
            ResponseBody body = response.body();
            if (body == null) {
                throw new BusinessErrorException("LLM 服务无响应");
            }
            String responseStr = body.string();
            if (!response.isSuccessful()) {
                log.error("LLM 服务返回错误 {}: {}", response.code(), responseStr);
                throw new BusinessErrorException("LLM 服务调用失败（HTTP " + response.code() + "）");
            }
            return objectMapper.readValue(responseStr, MAP_REF);
        }
    }
}
