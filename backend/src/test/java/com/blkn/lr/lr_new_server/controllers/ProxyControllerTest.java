package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.apiproxy.FluencyResult;
import com.blkn.lr.lr_new_server.dto.apiproxy.PinyinMatchResult;
import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.services.PinyinService;
import com.blkn.lr.lr_new_server.services.QwenAudioService;
import com.blkn.lr.lr_new_server.util.BaiduApiManager;
import com.blkn.lr.lr_new_server.util.FlyTekManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.io.IOException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * ProxyController 测试。
 *
 * <p>5 个 endpoint，每个都涉及外部依赖（Baidu/讯飞 SDK + Qwen LLM），
 * 关键关注点：① 路由 + multipart 接收 / @RequestParam 接收；② 文本相似度的空 text1 短路；
 * ③ Future 超时 → ProxyServiceException（{@code future.cancel(true)} 配对）；
 * ④ audio_from_text 的两条 400 分支（空 text / 长 > 100）。
 */
class ProxyControllerTest {

    private MockMvc mvc;
    private BaiduApiManager baidu;
    private QwenAudioService qwenAudio;
    private FlyTekManager flyTek;
    private Environment env;
    private PinyinService pinyin;

    private static final String UID = "user-7";

    @BeforeEach
    void setUp() {
        baidu = mock(BaiduApiManager.class);
        qwenAudio = mock(QwenAudioService.class);
        flyTek = mock(FlyTekManager.class);
        env = mock(Environment.class);
        pinyin = mock(PinyinService.class);
        when(env.getProperty("server.port")).thenReturn("8080");

        ProxyController controller = new ProxyController(baidu, qwenAudio, flyTek, env, pinyin);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    // ============================================================
    // POST /api/proxy/pinyin_match
    // ============================================================

    @Test
    void pinyinMatchShouldShortCircuitToFalseWhenKeywordBlank() throws Exception {
        mvc.perform(post("/api/proxy/pinyin_match")
                        .param("keyword", "")
                        .param("spoken", "yi sheng"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matched").value(false))
                .andExpect(jsonPath("$.similarity").value(0.0));
        verify(pinyin, org.mockito.Mockito.never()).match(any(), any(), org.mockito.ArgumentMatchers.anyDouble());
    }

    @Test
    void pinyinMatchShouldDelegateToPinyinServiceWithDefaultThreshold() throws Exception {
        when(pinyin.match("医生", "yi sheng", 0.7))
                .thenReturn(new PinyinMatchResult(true, 0.85, "yi1sheng1", "yi sheng"));

        mvc.perform(post("/api/proxy/pinyin_match")
                        .param("keyword", "医生")
                        .param("spoken", "yi sheng"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matched").value(true))
                .andExpect(jsonPath("$.similarity").value(0.85))
                .andExpect(jsonPath("$.expectedPinyin").value("yi1sheng1"))
                .andExpect(jsonPath("$.actualPinyin").value("yi sheng"));
    }

    @Test
    void pinyinMatchShouldHonorCustomThreshold() throws Exception {
        when(pinyin.match("医生", "wi shang", 0.5))
                .thenReturn(new PinyinMatchResult(true, 0.55, "yi1sheng1", "wi shang"));

        mvc.perform(post("/api/proxy/pinyin_match")
                        .param("keyword", "医生")
                        .param("spoken", "wi shang")
                        .param("threshold", "0.5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matched").value(true));
    }

    // ============================================================
    // POST /api/proxy/text_similarity
    // ============================================================

    @Test
    void textSimilarityShouldShortCircuitToZeroWhenText1IsEmpty() throws Exception {
        // text1=="" 时不该调下游 baidu API
        mvc.perform(post("/api/proxy/text_similarity")
                        .param("text1", "")
                        .param("text2", "对照"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sim").value(0.0));
        verify(baidu, org.mockito.Mockito.never()).shortTextSimilarity(any(), any());
    }

    @Test
    void textSimilarityShouldDelegateToBaiduWhenText1NotEmpty() throws Exception {
        when(baidu.shortTextSimilarity("床", "船")).thenReturn(0.42);

        mvc.perform(post("/api/proxy/text_similarity")
                        .param("text1", "床")
                        .param("text2", "船"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sim").value(0.42));
    }

    // ============================================================
    // POST /api/proxy/audio_recognize —— Future 同步 + 超时
    // ============================================================

    @Test
    void audioRecognizeShouldUnwrapFutureWithText() throws Exception {
        when(flyTek.recognizeAudio(any())).thenReturn(CompletableFuture.completedFuture("识别文本"));

        MockMultipartFile mf = new MockMultipartFile("file", "x.wav", "audio/wav", new byte[]{1, 2});
        mvc.perform(multipart("/api/proxy/audio_recognize").file(mf))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").value("识别文本"));
    }

    @Test
    void audioRecognizeShouldCancelFutureAndThrowOnTimeout() throws Exception {
        @SuppressWarnings("unchecked")
        Future<String> future = mock(Future.class);
        when(future.get(anyLong(), eq(TimeUnit.SECONDS))).thenThrow(new TimeoutException("讯飞超时"));
        when(flyTek.recognizeAudio(any())).thenReturn(future);

        MockMultipartFile mf = new MockMultipartFile("file", "x.wav", "audio/wav", new byte[]{1});
        mvc.perform(multipart("/api/proxy/audio_recognize").file(mf))
                .andExpect(status().is5xxServerError());
        // 关键：超时必须 cancel(true)，否则下游线程泄漏
        verify(future).cancel(true);
    }

    // ============================================================
    // POST /api/proxy/fluency —— delegate qwen-audio + 任意异常都包成 ProxyServiceException
    // ============================================================

    @Test
    void fluencyShouldDelegateToQwenAudio() throws Exception {
        when(qwenAudio.analyzeFluency(any())).thenReturn(new FluencyResult(7.0, "流畅", "你好"));

        MockMultipartFile mf = new MockMultipartFile("file", "x.wav", "audio/wav", new byte[]{1});
        mvc.perform(multipart("/api/proxy/fluency").file(mf))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fluency").value(7.0))
                .andExpect(jsonPath("$.detail").value("流畅"))
                .andExpect(jsonPath("$.content").value("你好"));
    }

    @Test
    void fluencyShouldWrapIoExceptionAsProxyServiceException() throws Exception {
        when(qwenAudio.analyzeFluency(any())).thenThrow(new IOException("qwen-audio HTTP 500"));

        MockMultipartFile mf = new MockMultipartFile("file", "x.wav", "audio/wav", new byte[]{1});
        mvc.perform(multipart("/api/proxy/fluency").file(mf))
                .andExpect(status().is5xxServerError());
    }

    // ============================================================
    // POST /api/proxy/handwrite_recognize —— 透传
    // ============================================================

    @Test
    void handwriteRecognizeShouldDelegateToBaidu() throws Exception {
        when(baidu.handWriteRecognize(any())).thenReturn("识别字");

        MockMultipartFile mf = new MockMultipartFile("file", "x.png", "image/png", new byte[]{1});
        mvc.perform(multipart("/api/proxy/handwrite_recognize").file(mf))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").value("识别字"));
    }

    // ============================================================
    // POST /api/proxy/audio_from_text —— 2 条 400 + Future 超时 + happy
    // ============================================================

    @Test
    void audioFromTextShouldRejectMissingTextKey() throws Exception {
        mvc.perform(post("/api/proxy/audio_from_text")
                        .contentType("application/json")
                        .content("{}")
                        .requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void audioFromTextShouldRejectEmptyText() throws Exception {
        mvc.perform(post("/api/proxy/audio_from_text")
                        .contentType("application/json")
                        .content("{\"text\":\"\"}")
                        .requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void audioFromTextShouldRejectTextLongerThan100() throws Exception {
        String text = "我".repeat(101);
        mvc.perform(post("/api/proxy/audio_from_text")
                        .contentType("application/json")
                        .content("{\"text\":\"" + text + "\"}")
                        .requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void audioFromTextShouldReturnUrlAndNameOnHappyPath() throws Exception {
        when(flyTek.synthesisAudioFromText(eq("你好"), eq(UID), eq("8080")))
                .thenReturn(CompletableFuture.completedFuture(
                        "http://localhost:8080/audio/" + UID + "/result.mp3"));

        mvc.perform(post("/api/proxy/audio_from_text")
                        .contentType("application/json")
                        .content("{\"text\":\"你好\"}")
                        .requestAttr("uid", UID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.url").value("http://localhost:8080/audio/" + UID + "/result.mp3"))
                // name = split("/") 最后一段
                .andExpect(jsonPath("$.name").value("result.mp3"));
    }

    @Test
    void audioFromTextShouldCancelFutureAndThrowOnTimeout() throws Exception {
        @SuppressWarnings("unchecked")
        Future<String> future = mock(Future.class);
        when(future.get(anyLong(), eq(TimeUnit.SECONDS))).thenThrow(new TimeoutException("讯飞 TTS 超时"));
        when(flyTek.synthesisAudioFromText(any(), any(), any())).thenReturn(future);

        mvc.perform(post("/api/proxy/audio_from_text")
                        .contentType("application/json")
                        .content("{\"text\":\"你好\"}")
                        .requestAttr("uid", UID))
                .andExpect(status().is5xxServerError());
        verify(future).cancel(true);
    }

    @Test
    void audioFromTextShouldWrapFutureExecutionExceptionUpward() throws Exception {
        // future.get 抛 ExecutionException（下游 SDK 调用失败）—— Controller 直接 throws Exception，
        // 不做额外包装。这条锁定当前行为。
        @SuppressWarnings("unchecked")
        Future<String> future = mock(Future.class);
        when(future.get(anyLong(), eq(TimeUnit.SECONDS)))
                .thenThrow(new ExecutionException(new RuntimeException("讯飞鉴权失败")));
        when(flyTek.synthesisAudioFromText(any(), any(), any())).thenReturn(future);

        mvc.perform(post("/api/proxy/audio_from_text")
                        .contentType("application/json")
                        .content("{\"text\":\"你好\"}")
                        .requestAttr("uid", UID))
                .andExpect(status().is5xxServerError());
        // ExecutionException 不是 TimeoutException，不会 cancel
        verify(future, org.mockito.Mockito.never()).cancel(true);
    }
}
