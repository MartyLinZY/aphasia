package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.models.question.Question;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * QuestionDaoImpl 单元测试。
 *
 * <p>关键点是 {@link QuestionDaoImpl#findAllByIds}：项 N1 重构暴露的批量预 fetch 入口。
 * 必须验证三件事：① null / 空集合 → 直接返 List.of() 不打 DB；② 过滤掉 null 和非合法 ObjectId
 * 字符串（{@code ObjectId.isValid}）；③ 合法 id 用 $in 一次拉取（防止打成 N 次单条查询，
 * 否则项 N1 的反 N+1 优化白做）。
 */
class QuestionDaoImplTest {

    private static final String VALID_ID_1 = "507f1f77bcf86cd799439011";
    private static final String VALID_ID_2 = "507f191e810c19729de860ea";

    private MongoTemplate template;
    private QuestionDaoImpl dao;

    @BeforeEach
    void setUp() {
        template = mock(MongoTemplate.class);
        dao = new QuestionDaoImpl(template);
    }

    // ============================================================
    // findById / save —— 薄包装
    // ============================================================

    @Test
    void findByIdShouldPassThroughTemplate() {
        Question q = new Question();
        when(template.findById(VALID_ID_1, Question.class)).thenReturn(q);
        assertSame(q, dao.findById(VALID_ID_1));
    }

    @Test
    void saveShouldPassThroughTemplate() {
        Question q = new Question();
        when(template.save(q)).thenReturn(q);
        assertSame(q, dao.save(q));
    }

    // ============================================================
    // findAllByIds —— 关键反 N+1 入口
    // ============================================================

    @Test
    void findAllByIdsShouldReturnEmptyListForNullInput() {
        assertEquals(List.of(), dao.findAllByIds(null));
        verify(template, never()).find(any(Query.class), any());
    }

    @Test
    void findAllByIdsShouldReturnEmptyListForEmptyCollection() {
        assertEquals(List.of(), dao.findAllByIds(List.of()));
        verify(template, never()).find(any(Query.class), any());
    }

    @Test
    void findAllByIdsShouldBatchValidObjectIdsInSingleInQuery() {
        Question q1 = new Question();
        Question q2 = new Question();
        when(template.find(any(Query.class), eq(Question.class))).thenReturn(List.of(q1, q2));

        List<Question> result = dao.findAllByIds(List.of(VALID_ID_1, VALID_ID_2));

        assertEquals(List.of(q1, q2), result);

        // 关键断言：template.find 只被调一次
        ArgumentCaptor<Query> captor = ArgumentCaptor.forClass(Query.class);
        verify(template, org.mockito.Mockito.times(1)).find(captor.capture(), eq(Question.class));
        // Query 序列化后应包含 $in 操作符与两个 ObjectId 字符串
        String queryStr = captor.getValue().getQueryObject().toString();
        assertTrue(queryStr.contains("$in"), "应使用 $in: " + queryStr);
        assertTrue(queryStr.contains(VALID_ID_1), queryStr);
        assertTrue(queryStr.contains(VALID_ID_2), queryStr);
    }

    @Test
    void findAllByIdsShouldFilterOutNullAndInvalidObjectIds() {
        when(template.find(any(Query.class), eq(Question.class))).thenReturn(List.of());

        // 混入 null + 非合法 ObjectId 字符串（不是 24 字符 hex）
        dao.findAllByIds(java.util.Arrays.asList(VALID_ID_1, null, "not-an-objectid", VALID_ID_2));

        ArgumentCaptor<Query> captor = ArgumentCaptor.forClass(Query.class);
        verify(template).find(captor.capture(), eq(Question.class));
        String queryStr = captor.getValue().getQueryObject().toString();
        assertTrue(queryStr.contains(VALID_ID_1), queryStr);
        assertTrue(queryStr.contains(VALID_ID_2), queryStr);
        // 非法 id 不应进入 $in 列表
        assertTrue(!queryStr.contains("not-an-objectid"), queryStr);
    }

    @Test
    void findAllByIdsShouldReturnEmptyWhenAllIdsAreInvalid() {
        // 全是非法 id —— 提前返 List.of() 不打 DB（避免无意义的空 $in 查询）
        assertEquals(List.of(), dao.findAllByIds(List.of("not-an-objectid", "still-not-one")));
        verify(template, never()).find(any(Query.class), any());
    }

    // ============================================================
    // deleteById —— findAndRemove
    // ============================================================

    @Test
    void deleteByIdShouldDelegateToFindAndRemoveAndReturnRemoved() {
        Question removed = new Question();
        when(template.findAndRemove(any(Query.class), eq(Question.class))).thenReturn(removed);

        assertSame(removed, dao.deleteById(VALID_ID_1));

        ArgumentCaptor<Query> captor = ArgumentCaptor.forClass(Query.class);
        verify(template).findAndRemove(captor.capture(), eq(Question.class));
        String queryStr = captor.getValue().getQueryObject().toString();
        // 应是按 _id 精确匹配
        assertTrue(queryStr.contains("_id"), queryStr);
        assertTrue(queryStr.contains(VALID_ID_1), queryStr);
    }

    @Test
    void deleteByIdShouldThrowForInvalidObjectId() {
        // 非合法 ObjectId 字符串直接走 new ObjectId(...) 会抛 IllegalArgumentException
        // —— 当前行为是不做提前校验，直接由 ObjectId ctor 抛。这条锁定该行为。
        org.junit.jupiter.api.Assertions.assertThrows(IllegalArgumentException.class,
                () -> dao.deleteById("not-an-objectid"));
    }
}
