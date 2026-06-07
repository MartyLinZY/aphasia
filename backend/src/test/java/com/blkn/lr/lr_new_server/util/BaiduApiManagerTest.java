package com.blkn.lr.lr_new_server.util;

import com.alibaba.fastjson2.JSONObject;
import com.blkn.lr.lr_new_server.config.BaiduApiConfig;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * BaiduApiManager 短文本相似度路径单元测试。
 *
 * <p>仅覆盖 {@link BaiduApiManager#shortTextSimilarity}（RestTemplate 可 mock）：
 * happy path + 3 条 null-return 分支（status != 200 / body null / error_code 存在）。
 *
 * <p>{@link BaiduApiManager#authorize} 和 {@link BaiduApiManager#handWriteRecognize}
 * 走 {@link OkHttpManager} 静态 client / {@code BaiduHttpUtil.post} 静态方法，
 * 需要 mockito-inline 静态 mock，不在本测试范围；将 accessToken 预设
 * 跳过 {@code checkAndSetToken} 中的 authorize 分支。
 */
class BaiduApiManagerTest {

    private RestTemplate restTemplate;
    private BaiduApiConfig config;
    private BaiduApiManager manager;

    @BeforeEach
    void setUp() {
        restTemplate = mock(RestTemplate.class);
        config = mock(BaiduApiConfig.class);
        when(config.getShortTextSimUrl())
                .thenReturn("https://aip.baidubce.com/rpc/2.0/nlp/v2/simnet?charset=UTF-8");

        manager = new BaiduApiManager(restTemplate, config);
        // 跳过鉴权：在 checkAndSetToken 里 accessToken != null 就不会调 authorize（即不打 OkHttp）
        ReflectionTestUtils.setField(manager, "accessToken", "test-token");
    }

    @Test
    void shortTextSimilarityShouldReturnScoreOnHappyPath() {
        JSONObject body = new JSONObject();
        body.put("score", 0.87);
        when(restTemplate.postForEntity(any(String.class), any(), eq(JSONObject.class)))
                .thenReturn(new ResponseEntity<>(body, HttpStatus.OK));

        assertEquals(0.87, manager.shortTextSimilarity("床", "船"));
    }

    @Test
    void shortTextSimilarityShouldReturnNullWhenStatusNotOk() {
        JSONObject body = new JSONObject();
        body.put("score", 0.5);
        when(restTemplate.postForEntity(any(String.class), any(), eq(JSONObject.class)))
                .thenReturn(new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR));

        assertNull(manager.shortTextSimilarity("a", "b"));
    }

    @Test
    void shortTextSimilarityShouldReturnNullWhenResponseBodyIsNull() {
        when(restTemplate.postForEntity(any(String.class), any(), eq(JSONObject.class)))
                .thenReturn(new ResponseEntity<>(null, HttpStatus.OK));

        assertNull(manager.shortTextSimilarity("a", "b"));
    }

    @Test
    void shortTextSimilarityShouldReturnNullWhenErrorCodePresent() {
        // 百度 API 200 但业务错误 —— 应返 null 让 Controller 退化处理
        JSONObject body = new JSONObject();
        body.put("error_code", 17);
        body.put("error_msg", "QPS limit");
        when(restTemplate.postForEntity(any(String.class), any(), eq(JSONObject.class)))
                .thenReturn(new ResponseEntity<>(body, HttpStatus.OK));

        assertNull(manager.shortTextSimilarity("a", "b"));
    }

    @Test
    void shortTextSimilarityShouldAppendAccessTokenToUrl() {
        JSONObject body = new JSONObject();
        body.put("score", 0.0);
        when(restTemplate.postForEntity(any(String.class), any(), eq(JSONObject.class)))
                .thenReturn(new ResponseEntity<>(body, HttpStatus.OK));

        manager.shortTextSimilarity("a", "b");

        // 实际 URL 应是 simUrl + "&access_token=" + token —— 抓 URL 入参验证
        org.mockito.ArgumentCaptor<String> urlCaptor = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(restTemplate).postForEntity(urlCaptor.capture(), any(), eq(JSONObject.class));
        String calledUrl = urlCaptor.getValue();
        org.junit.jupiter.api.Assertions.assertTrue(
                calledUrl.contains("&access_token=test-token"),
                "URL 必须拼上 accessToken: " + calledUrl);
    }
}
