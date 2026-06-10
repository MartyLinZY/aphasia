package com.blkn.lr.lr_new_server.dao;

import com.blkn.lr.lr_new_server.models.question.Question;

import java.util.Collection;
import java.util.List;

/**
 * 题目数据访问抽象。Controller / DTO / Service 应依赖本接口而非具体实现。
 */
public interface QuestionDao {
    Question findById(String id);

    /**
     * 批量按 id 查询；用于 Mapper 在组装包含多道题的 Exam / ExamResult 时避免 N+1 查询。
     * 返回结果只包含查到的题目（缺失的 id 不会出现），调用方自行处理缺失。
     */
    List<Question> findAllByIds(Collection<String> ids);

    Question save(Question q);

    Question deleteById(String id);
}
