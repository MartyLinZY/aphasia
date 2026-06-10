package com.blkn.lr.lr_new_server.mapper;

import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.question.Question;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Collection;
import java.util.LinkedList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ExamMapperTest {

    private QuestionDao questionDao;
    private ExamMapper examMapper;

    @BeforeEach
    void setUp() {
        questionDao = mock(QuestionDao.class);
        examMapper = new ExamMapper(questionDao, new QuestionMapper());
    }

    @Test
    void toDtoShouldBatchFetchAllQuestionsInOneCall() {
        Question q1 = question("q1", "题1");
        Question q2 = question("q2", "题2");
        Question q3 = question("q3", "题3");
        when(questionDao.findAllByIds(any())).thenReturn(List.of(q1, q2, q3));

        Exam exam = examWithQuestions(List.of(List.of("q1", "q2"), List.of("q3")));

        ExamDto dto = examMapper.toDto(exam);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Collection<String>> captor = ArgumentCaptor.forClass(Collection.class);
        verify(questionDao, times(1)).findAllByIds(captor.capture());
        verify(questionDao, never()).findById(any());
        assertTrue(captor.getValue().containsAll(List.of("q1", "q2", "q3")),
                "应一次性把 exam 树下所有 question id 传入");

        // 验证拼装结果正确
        assertEquals(2, dto.getCategories().get(0).getSubCategories().get(0).getQuestions().size());
        assertEquals("题1", dto.getCategories().get(0).getSubCategories().get(0).getQuestions().get(0).getQuestionText());
        assertEquals("题3", dto.getCategories().get(1).getSubCategories().get(0).getQuestions().get(0).getQuestionText());
    }

    @Test
    void toDtoShouldUsePlaceholderForMissingQuestions() {
        // 模拟某些 id 在 questions 表中已删除：批量查只返回 q1，q2 缺失
        Question q1 = question("q1", "题1");
        when(questionDao.findAllByIds(any())).thenReturn(List.of(q1));

        Exam exam = examWithQuestions(List.of(List.of("q1", "q2-deleted")));

        ExamDto dto = examMapper.toDto(exam);

        var questions = dto.getCategories().get(0).getSubCategories().get(0).getQuestions();
        assertEquals("题1", questions.get(0).getQuestionText());
        // 缺失题走占位分支（QuestionMapper.toDto(null)）
        assertEquals("原问题已删除", questions.get(1).getAlias());
    }

    @Test
    void toDtoShouldNotQueryWhenExamHasNoQuestions() {
        when(questionDao.findAllByIds(any())).thenReturn(List.of());

        Exam exam = new Exam();
        exam.setName("空套题");
        exam.setCategories(new LinkedList<>());

        ExamDto dto = examMapper.toDto(exam);

        // 即使没有题目，也只调用一次（带空集合）；不会回退到逐题 findById
        verify(questionDao, times(1)).findAllByIds(any());
        verify(questionDao, never()).findById(any());
        assertEquals(0, dto.getCategories().size());
    }

    private Question question(String id, String text) {
        Question q = new Question();
        q.setId(id);
        q.setQuestionText(text);
        q.setTypeName("AudioQuestion");
        return q;
    }

    private Exam examWithQuestions(List<List<String>> subCategoryQuestionIds) {
        Exam exam = new Exam();
        exam.setName("测试套题");
        LinkedList<QuestionCategory> categories = new LinkedList<>();
        for (List<String> subQs : subCategoryQuestionIds) {
            QuestionSubCategory sub = new QuestionSubCategory();
            sub.setDescription("子项");
            sub.setQuestions(new LinkedList<>(subQs));
            sub.setTerminateRules(new LinkedList<>());
            sub.setEvalRules(new LinkedList<>());

            QuestionCategory cat = new QuestionCategory();
            cat.setDescription("亚项");
            LinkedList<QuestionSubCategory> subs = new LinkedList<>();
            subs.add(sub);
            cat.setSubCategories(subs);
            cat.setRules(new LinkedList<>());
            categories.add(cat);
        }
        exam.setCategories(categories);
        return exam;
    }
}
