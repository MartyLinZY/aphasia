package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.config.AppSetting;
import com.blkn.lr.lr_new_server.dao.impl.FileDao;
import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.io.File;
import java.util.List;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FileController 测试。
 *
 * <p>四个 endpoint：
 * <ul>
 *   <li>POST /api/image：调 {@code uploadFile} 分支 image → {@code fileDao.createImageFile}</li>
 *   <li>POST /api/audio：调 {@code uploadFile} 分支 audio → {@code fileDao.createAudioFile}</li>
 *   <li>GET /api/images：列出当前 uid 的图片 URL + name</li>
 *   <li>GET /api/audios：列出当前 uid 的音频 URL + name</li>
 * </ul>
 *
 * <p>关键分支：content-type 包含 "image/" / "audio/" / 都不匹配 → BusinessErrorException。
 * 拼接 URL 走 {@code StaticResourcesConfig.getUrlPrefix(host, port)}（host 由 AppSetting、port 由 Environment）。
 */
class FileControllerTest {

    private MockMvc mvc;
    private FileDao fileDao;
    private Environment env;
    private AppSetting appSetting;

    private static final String UID = "user-7";

    @BeforeEach
    void setUp() {
        fileDao = mock(FileDao.class);
        env = mock(Environment.class);
        appSetting = mock(AppSetting.class);
        when(appSetting.getHost()).thenReturn("localhost");
        when(env.getProperty("server.port")).thenReturn("8080");

        FileController controller = new FileController(fileDao, env, appSetting);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    // ============================================================
    // POST /api/image —— image/* content-type 走 createImageFile 分支
    // ============================================================

    @Test
    void uploadImagesShouldRouteImageContentTypeToCreateImageFile() throws Exception {
        when(fileDao.createImageFile(org.mockito.ArgumentMatchers.any(), eq(UID)))
                .thenReturn(new File("/tmp/abc.png"));

        MockMultipartFile mf = new MockMultipartFile("file", "abc.png", "image/png", new byte[]{1, 2, 3});
        mvc.perform(multipart("/api/image").file(mf).requestAttr("uid", UID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("abc.png"))
                // URL prefix + getImageUrlPath("/images/user-7/abc.png")
                .andExpect(jsonPath("$.url").value("http://localhost:8080/images/" + UID + "/abc.png"));
        verify(fileDao).createImageFile(org.mockito.ArgumentMatchers.any(), eq(UID));
    }

    @Test
    void uploadImagesShouldThrowForNonImageNonAudioContentType() throws Exception {
        // 走 image endpoint 但 content-type 是 text/plain —— 应命中 else 分支抛 BusinessErrorException
        MockMultipartFile mf = new MockMultipartFile("file", "x.txt", "text/plain", new byte[]{1, 2});
        mvc.perform(multipart("/api/image").file(mf).requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
    }

    // ============================================================
    // POST /api/audio —— audio/* content-type 走 createAudioFile 分支
    // ============================================================

    @Test
    void uploadAudioShouldRouteAudioContentTypeToCreateAudioFile() throws Exception {
        when(fileDao.createAudioFile(org.mockito.ArgumentMatchers.any(), eq(UID)))
                .thenReturn(new File("/tmp/xyz.wav"));

        MockMultipartFile mf = new MockMultipartFile("file", "xyz.wav", "audio/wav", new byte[]{5, 6});
        mvc.perform(multipart("/api/audio").file(mf).requestAttr("uid", UID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("xyz.wav"))
                .andExpect(jsonPath("$.url").value("http://localhost:8080/audio/" + UID + "/xyz.wav"));
        verify(fileDao).createAudioFile(org.mockito.ArgumentMatchers.any(), eq(UID));
    }

    @Test
    void uploadImagesShouldAlsoAcceptAudioContentType() throws Exception {
        // image endpoint + audio content-type —— Controller 不卡 endpoint，按 content-type 分流。
        // 这条锁住"路由器是 content-type 驱动而非 URL 驱动"的当前行为。
        when(fileDao.createAudioFile(org.mockito.ArgumentMatchers.any(), eq(UID)))
                .thenReturn(new File("/tmp/audio-via-image.wav"));

        MockMultipartFile mf = new MockMultipartFile("file", "audio-via-image.wav", "audio/wav", new byte[]{1});
        mvc.perform(multipart("/api/image").file(mf).requestAttr("uid", UID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.url").value("http://localhost:8080/audio/" + UID + "/audio-via-image.wav"));
    }

    // ============================================================
    // GET /api/images / /api/audios —— list 模式
    // ============================================================

    @Test
    void getAllImageInfoShouldSplitPathAndPrependUrlPrefix() throws Exception {
        when(fileDao.getAllImageUrlPaths(UID))
                .thenReturn(List.of("/images/" + UID + "/a.png", "/images/" + UID + "/b.jpg"));

        mvc.perform(get("/api/images").requestAttr("uid", UID))
                .andExpect(status().isOk())
                // 取 split("/") 最后一段做 name
                .andExpect(jsonPath("$[0].name").value("a.png"))
                .andExpect(jsonPath("$[0].url").value("http://localhost:8080/images/" + UID + "/a.png"))
                .andExpect(jsonPath("$[1].name").value("b.jpg"))
                .andExpect(jsonPath("$[1].url").value("http://localhost:8080/images/" + UID + "/b.jpg"));
    }

    @Test
    void getAllImageInfoShouldReturnEmptyArrayWhenNoImages() throws Exception {
        when(fileDao.getAllImageUrlPaths(UID)).thenReturn(List.of());

        mvc.perform(get("/api/images").requestAttr("uid", UID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void getAllAudioInfoShouldSplitPathAndPrependUrlPrefix() throws Exception {
        when(fileDao.getAllAudioUrlPaths(UID))
                .thenReturn(List.of("/audio/" + UID + "/c.wav"));

        mvc.perform(get("/api/audios").requestAttr("uid", UID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("c.wav"))
                .andExpect(jsonPath("$[0].url").value("http://localhost:8080/audio/" + UID + "/c.wav"));
    }

    @Test
    void getAllAudioInfoShouldReturnEmptyArrayWhenNoAudios() throws Exception {
        when(fileDao.getAllAudioUrlPaths(UID)).thenReturn(List.of());

        mvc.perform(get("/api/audios").requestAttr("uid", UID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
