package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.exception.FileIOException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * FileDao 单元测试。
 *
 * <p>FileDao 通过 {@link com.blkn.lr.lr_new_server.config.StaticResourcesConfig#getImageDirPath}
 * / {@code getAudioDirPath} 间接依赖 {@code System.getProperty("user.dir")} —— 写入路径
 * 与运行进程的 cwd 相对。本测试在每个用例之前把 {@code user.dir} 临时指向 JUnit5 提供的
 * {@code @TempDir}，结束后还原，保证 ① 真实文件 IO 路径被覆盖（不光是 null-list 兜底）；
 * ② 不污染开发机工作目录、不与并行用例共享状态。
 *
 * <p>覆盖路径：① saveToFile 正常写入 ② 同名文件覆盖（destFile.exists 走 delete 分支）
 * ③ MultipartFile.transferTo 抛 IOException → 翻成 FileIOException ④ listFiles 返
 * null（已有兜底测试，保留）⑤ getAll{Image,Audio}UrlPaths 真实文件列表 → URL 拼装。
 */
class FileDaoTest {

    private final FileDao fileDao = new FileDao();

    @TempDir
    Path tempDir;

    private String originalUserDir;

    @BeforeEach
    void setUp() {
        originalUserDir = System.getProperty("user.dir");
        System.setProperty("user.dir", tempDir.toString());
    }

    @AfterEach
    void tearDown() {
        // 还原 user.dir，避免污染后续用例 / IDE 开发环境
        if (originalUserDir != null) {
            System.setProperty("user.dir", originalUserDir);
        }
    }

    // ============================================================
    // listFiles 返 null 的兜底（原有测试，保留）
    // ============================================================

    @Test
    void getAllImageUrlPathsShouldReturnEmptyWhenDirMissing() {
        String unknownUid = "no-such-user-" + UUID.randomUUID();
        List<String> paths = fileDao.getAllImageUrlPaths(unknownUid);
        assertNotNull(paths);
        assertTrue(paths.isEmpty());
    }

    @Test
    void getAllAudioUrlPathsShouldReturnEmptyWhenDirMissing() {
        String unknownUid = "no-such-user-" + UUID.randomUUID();
        List<String> paths = fileDao.getAllAudioUrlPaths(unknownUid);
        assertNotNull(paths);
        assertTrue(paths.isEmpty());
    }

    // ============================================================
    // 真实写入路径 —— createImageFile / createAudioFile
    // ============================================================

    @Test
    void createImageFileShouldWriteBytesToImageDirUnderUid() throws Exception {
        String uid = "user-img-1";
        MockMultipartFile mf = new MockMultipartFile(
                "file", "pic.png", "image/png", new byte[]{1, 2, 3, 4});

        File result = fileDao.createImageFile(mf, uid);

        assertEquals("pic.png", result.getName());
        assertTrue(result.exists(), "目标文件应已写入");
        assertEquals(4, Files.size(result.toPath()), "字节数应与 multipart 一致");
        // 父目录应在 tempDir/images/<uid>
        assertEquals(tempDir.resolve("images").resolve(uid).toFile().getCanonicalPath(),
                result.getParentFile().getCanonicalPath());
    }

    @Test
    void createAudioFileShouldWriteBytesToAudioDirUnderUid() throws Exception {
        String uid = "user-aud-1";
        MockMultipartFile mf = new MockMultipartFile(
                "file", "voice.wav", "audio/wav", new byte[]{9, 8, 7});

        File result = fileDao.createAudioFile(mf, uid);

        assertTrue(result.exists());
        assertEquals(3, Files.size(result.toPath()));
        assertEquals(tempDir.resolve("audio").resolve(uid).toFile().getCanonicalPath(),
                result.getParentFile().getCanonicalPath());
    }

    @Test
    void createImageFileShouldOverwriteExistingFile() throws Exception {
        // 同名再传一次：走 destFile.exists() == true → delete() 分支
        String uid = "user-img-2";
        MockMultipartFile first = new MockMultipartFile(
                "file", "x.png", "image/png", new byte[]{1, 1, 1});
        fileDao.createImageFile(first, uid);

        MockMultipartFile second = new MockMultipartFile(
                "file", "x.png", "image/png", new byte[]{2, 2, 2, 2, 2});
        File overwritten = fileDao.createImageFile(second, uid);

        assertTrue(overwritten.exists());
        assertEquals(5, Files.size(overwritten.toPath()), "新内容应覆盖旧内容");
    }

    @Test
    void createImageFileShouldThrowFileIoExceptionWhenTransferToFails() {
        // MultipartFile.transferTo 抛 IOException → 应翻成 FileIOException（不直接吐 IOException）
        MultipartFile failing = new MockMultipartFile(
                "file", "boom.png", "image/png", new byte[]{1}) {
            @Override
            public void transferTo(@org.jetbrains.annotations.NotNull File dest) throws IOException {
                throw new IOException("磁盘满");
            }
        };

        assertThrows(FileIOException.class,
                () -> fileDao.createImageFile(failing, "user-fail"));
    }

    @Test
    void createImageFileShouldThrowBusinessErrorWhenDeleteFails() throws Exception {
        // 极少触发但分支真实存在：destFile.exists() && !destFile.delete() 返 true
        // 用 MultipartFile.getOriginalFilename() 返回的"空字符串"打到目录上 ——
        // 目标 path 实际是 .../images/<uid>/，destFile 解析为目录本身，
        // delete() 一个非空目录返回 false → 触发 BusinessErrorException。
        String uid = "user-img-3";
        // 先放一个文件进去，保证目录非空且 dest 解析为目录
        MockMultipartFile seed = new MockMultipartFile(
                "file", "seed.png", "image/png", new byte[]{1});
        fileDao.createImageFile(seed, uid);

        // 现在传一个 originalFilename 为空的 file —— dest path 拼成 "<dir>/"
        // new File("<dir>/") 等价于 new File("<dir>")，对应已存在的非空目录
        MockMultipartFile emptyName = new MockMultipartFile(
                "file", "", "image/png", new byte[]{2});

        assertThrows(BusinessErrorException.class,
                () -> fileDao.createImageFile(emptyName, uid));
    }

    // ============================================================
    // 真实读取路径 —— getAll{Image,Audio}UrlPaths
    // ============================================================

    @Test
    void getAllImageUrlPathsShouldReturnAllFileNamesUnderUid() throws Exception {
        String uid = "user-img-list";
        // 写两张图
        fileDao.createImageFile(new MockMultipartFile(
                "f", "a.png", "image/png", new byte[]{1}), uid);
        fileDao.createImageFile(new MockMultipartFile(
                "f", "b.jpg", "image/jpeg", new byte[]{2}), uid);

        List<String> urls = fileDao.getAllImageUrlPaths(uid);
        Set<String> set = urls.stream().collect(Collectors.toSet());
        assertEquals(Set.of("/images/" + uid + "/a.png", "/images/" + uid + "/b.jpg"), set);
    }

    @Test
    void getAllAudioUrlPathsShouldReturnAllFileNamesUnderUid() throws Exception {
        String uid = "user-aud-list";
        fileDao.createAudioFile(new MockMultipartFile(
                "f", "c.wav", "audio/wav", new byte[]{1}), uid);

        List<String> urls = fileDao.getAllAudioUrlPaths(uid);
        assertEquals(List.of("/audio/" + uid + "/c.wav"), urls);
    }

    @Test
    void getAllImageUrlPathsShouldReturnEmptyWhenDirExistsButIsEmpty() throws Exception {
        // 区别于 dir 不存在 (null) 的情况：dir 存在但内容为空 → for 循环 0 次
        String uid = "user-img-empty";
        Files.createDirectories(tempDir.resolve("images").resolve(uid));

        assertEquals(List.of(), fileDao.getAllImageUrlPaths(uid));
    }
}
