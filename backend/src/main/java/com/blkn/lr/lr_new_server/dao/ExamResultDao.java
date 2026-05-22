package com.blkn.lr.lr_new_server.dao;

import com.blkn.lr.lr_new_server.models.results.ExamResult;

import java.util.List;

/**
 * 作答结果数据访问抽象。Controller / Service 应依赖本接口而非具体实现。
 */
public interface ExamResultDao {
    ExamResult save(ExamResult model);

    List<ExamResult> findByOwnerId(String ownerId, boolean isRecovery);

    void deleteByIdWithOwnerId(String ownerId, String resultId);
}
