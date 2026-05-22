package com.blkn.lr.lr_new_server.dao.impl;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class FileDaoTest {

    private final FileDao fileDao = new FileDao();

    @Test
    void getAllImageUrlPathsShouldReturnEmptyWhenDirMissing() {
        // 不存在的 uid 对应的目录不存在，listFiles() 返回 null，
        // 修复前会 NPE；修复后应返回空列表。
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
}
