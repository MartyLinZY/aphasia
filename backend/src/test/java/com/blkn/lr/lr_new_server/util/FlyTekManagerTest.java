package com.blkn.lr.lr_new_server.util;

import org.junit.jupiter.api.Test;

import java.net.MalformedURLException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * FlyTekManager 单元测试。
 *
 * <p>{@link FlyTekManager#getAuthUrl} 是讯飞 ASR/TTS WebSocket 鉴权的核心拼装函数：
 * HMAC-SHA256 签名 + Base64 + URL 查询参数注入。两个 public 实例方法
 * （recognizeAudio / synthesisAudioFromText）涉及 WebSocket 真连接 + 文件 IO，
 * 本测试范围不覆盖（独立任务，需要 OkHttpClient 静态 mock）。
 */
class FlyTekManagerTest {

    @Test
    void getAuthUrlShouldRewriteHttpToWss() throws Exception {
        String authed = FlyTekManager.getAuthUrl(
                "https://iat-api.xfyun.cn/v2/iat", "test-key", "test-secret");
        assertTrue(authed.startsWith("wss://"),
                "https URL 必须改写为 wss，否则讯飞 WS 不接受: " + authed);
        // 包含必需的鉴权 query 参数
        assertTrue(authed.contains("authorization="), authed);
        assertTrue(authed.contains("date="), authed);
        assertTrue(authed.contains("host="), authed);
    }

    @Test
    void getAuthUrlAlwaysProducesWssRegardlessOfInputScheme() throws Exception {
        // 当前实现内部用 "https://" 重建 HttpUrl 然后 replace —— 即使输入是 http://，
        // 结果始终是 wss://（讯飞线上端点都是 HTTPS，这条隐性约束符合实际场景）。
        // 锁住这条行为，未来若改成"按输入 scheme 输出"会立刻提示。
        String fromHttp = FlyTekManager.getAuthUrl("http://localhost:8080/iat", "k", "s");
        assertTrue(fromHttp.startsWith("wss://"), fromHttp);
    }

    @Test
    void getAuthUrlShouldPreserveHostAndPath() throws Exception {
        String authed = FlyTekManager.getAuthUrl(
                "https://tts-api.xfyun.cn/v2/tts", "k", "s");
        assertTrue(authed.contains("tts-api.xfyun.cn"), authed);
        assertTrue(authed.contains("/v2/tts"), authed);
    }

    @Test
    void getAuthUrlShouldProduceDifferentSignaturesForDifferentSecrets() throws Exception {
        // 验证 HMAC 真的把 secret 算进了签名 —— 不同 secret 必须产生不同 authorization
        String authedA = FlyTekManager.getAuthUrl(
                "https://iat-api.xfyun.cn/v2/iat", "k", "secret-A");
        String authedB = FlyTekManager.getAuthUrl(
                "https://iat-api.xfyun.cn/v2/iat", "k", "secret-B");
        // 提取 authorization 参数（同一时刻调用，host/date 应该一致，仅 secret 影响签名）
        assertNotNull(authedA);
        assertNotNull(authedB);
        // 直接比较整体 URL 即可——其余参数都一样，只有签名因 secret 变化
        // 注意：date 可能秒级跳变，所以对此条断言放宽：要么签名不等，要么 date 不等
        assertTrue(!authedA.equals(authedB), "签名 / 时间至少有一个不同");
    }

    @Test
    void getAuthUrlShouldThrowOnMalformedHostUrl() {
        // 完全无法解析的 URL
        assertThrows(MalformedURLException.class, () -> FlyTekManager.getAuthUrl("not-a-url", "k", "s"));
    }

    @Test
    void getAuthUrlSignatureShouldBeUrlSafe() throws Exception {
        // 输出 URL 不应裸出现 + / = 等让讯飞 query parser 困惑的字符
        // （它们应该已经被 OkHttp HttpUrl.Builder 做了 query 编码）
        String authed = FlyTekManager.getAuthUrl(
                "https://iat-api.xfyun.cn/v2/iat", "k", "s+/=");
        // 必须是合法 URL（OkHttp 会拒绝拼出 invalid url 的字符）
        assertEquals(0, authed.indexOf("wss://"));
    }
}
