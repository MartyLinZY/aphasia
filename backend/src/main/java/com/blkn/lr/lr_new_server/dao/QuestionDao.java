package com.blkn.lr.lr_new_server.dao;

import com.blkn.lr.lr_new_server.models.question.Question;

/**
 * 题目数据访问抽象。Controller / DTO / Service 应依赖本接口而非具体实现。
 */
public interface QuestionDao {
    Question findById(String id);

    Question save(Question q);

    Question deleteById(String id);
}
