package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import com.mongodb.client.result.UpdateResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.mongodb.core.ExecutableUpdateOperation.ExecutableUpdate;
import org.springframework.data.mongodb.core.ExecutableUpdateOperation.TerminatingUpdate;
import org.springframework.data.mongodb.core.ExecutableUpdateOperation.UpdateWithUpdate;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.CriteriaDefinition;
import org.springframework.data.mongodb.core.query.Update;

import java.util.LinkedList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * ExamDaoImpl 单元测试。
 * 不引入 embedded mongo —— MongoTemplate 全用 Mockito 桩，
 * 因此重点是验证 ExamDaoImpl 自身的业务行为（边界、index、swap 语义、
 * 取出-改写-save 的 round-trip），而不是 Mongo 的查询语法。
 *
 * <p>两种调用模式：
 * <ul>
 *   <li>Pattern A（fluent 链）：template.update(Exam.class).matching(q).apply(u).all()
 *       —— 这类方法在 DAO 里是"参数→Update→返回 modifiedCount"的薄包装，
 *       本测试用 stub 链验证传参 + 返回值传递。</li>
 *   <li>Pattern B（findById + save）：取整份 Exam 修改后 save 回去
 *       —— 这类方法承载所有边界 / index 逻辑，是 bug 滋生地，
 *       用 ArgumentCaptor 抓回 save 入参做精确断言。</li>
 * </ul>
 */
class ExamDaoImplTest {

    private static final String EXAM_ID = "507f1f77bcf86cd799439011"; // 24 字符合法 ObjectId

    private MongoTemplate template;
    private ExamDaoImpl dao;

    @BeforeEach
    void setUp() {
        template = mock(MongoTemplate.class);
        dao = new ExamDaoImpl(template);
    }

    // ============================================================
    // save / findPublishedExamById
    // ============================================================

    @Test
    void saveShouldPassThroughTemplateSave() {
        Exam input = simpleExam();
        when(template.save(input)).thenReturn(input);

        Exam result = dao.save(input);

        assertEquals(input, result);
        verify(template).save(input);
    }

    @Test
    void findPublishedExamByIdShouldReturnExamWhenPublishedAndNotDisabled() {
        Exam exam = simpleExam();
        exam.setPublished(true);
        exam.setDisabled(false);
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(exam, dao.findPublishedExamById(EXAM_ID));
    }

    @Test
    void findPublishedExamByIdShouldReturnNullWhenNotPublished() {
        Exam exam = simpleExam();
        exam.setPublished(false);
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertNull(dao.findPublishedExamById(EXAM_ID));
    }

    @Test
    void findPublishedExamByIdShouldReturnNullWhenDisabled() {
        Exam exam = simpleExam();
        exam.setPublished(true);
        exam.setDisabled(true);
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertNull(dao.findPublishedExamById(EXAM_ID));
    }

    @Test
    void findPublishedExamByIdShouldReturnNullWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertNull(dao.findPublishedExamById(EXAM_ID));
    }

    // ============================================================
    // Pattern A：fluent 链 —— addCategoryIntoExam / deleteExam /
    //   updateExamName / updateExamDesc / addSubCategoryIntoExam /
    //   addQuestionIntoExam / addDiagnosisRule / publishExam
    // ============================================================

    @Test
    void addCategoryIntoExamShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);

        long count = dao.addCategoryIntoExam(EXAM_ID, new QuestionCategory());

        assertEquals(1L, count);
        verify(template).update(Exam.class);
    }

    @Test
    void deleteExamShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);
        assertEquals(1L, dao.deleteExam(EXAM_ID));
    }

    @Test
    void updateExamNameShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);
        assertEquals(1L, dao.updateExamName(EXAM_ID, "新名字"));
    }

    @Test
    void updateExamDescShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);
        assertEquals(1L, dao.updateExamDesc(EXAM_ID, "新简介"));
    }

    @Test
    void addSubCategoryIntoExamShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);
        assertEquals(1L, dao.addSubCategoryIntoExam(EXAM_ID, 0, new QuestionSubCategory()));
    }

    @Test
    void addQuestionIntoExamShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);
        assertEquals(1L, dao.addQuestionIntoExam(EXAM_ID, 0, 0, "q-new"));
    }

    @Test
    void addDiagnosisRuleShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);
        assertEquals(1L, dao.addDiagnosisRule(EXAM_ID, new DiagnosisRule()));
    }

    @Test
    void publishExamShouldReturnModifiedCountFromFluentChain() {
        stubFluentUpdateWithModifiedCount(1L);
        assertEquals(1L, dao.publishExam(EXAM_ID));
    }

    @Test
    void fluentUpdateChainShouldPropagateZeroWhenNothingMatched() {
        // 目标 exam 不存在时 Mongo 返回 modifiedCount=0，DAO 应原样透传
        stubFluentUpdateWithModifiedCount(0L);
        assertEquals(0L, dao.deleteExam(EXAM_ID));
    }

    // ============================================================
    // Pattern B：deleteCategoryFromExam
    // ============================================================

    @Test
    void deleteCategoryFromExamShouldRemoveAtGivenIndex() {
        Exam exam = examWithCategories("cat0", "cat1", "cat2");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        long affected = dao.deleteCategoryFromExam(EXAM_ID, 1);

        assertEquals(1L, affected);
        Exam saved = captureSavedExam();
        assertEquals(2, saved.getCategories().size());
        assertEquals("cat0", saved.getCategories().get(0).getDescription());
        assertEquals("cat2", saved.getCategories().get(1).getDescription());
    }

    @Test
    void deleteCategoryFromExamShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);

        assertEquals(0L, dao.deleteCategoryFromExam(EXAM_ID, 0));
        verify(template, never()).save(any(Exam.class));
    }

    // ============================================================
    // Pattern B：moveCategoryUp / moveCategoryDown
    // ============================================================

    @Test
    void moveCategoryUpShouldSwapWithPrevious() {
        Exam exam = examWithCategories("a", "b", "c");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveCategoryUp(EXAM_ID, 2));

        Exam saved = captureSavedExam();
        assertEquals(List.of("a", "c", "b"),
                saved.getCategories().stream().map(QuestionCategory::getDescription).toList());
    }

    @Test
    void moveCategoryUpShouldBeNoOpAtIndexZero() {
        Exam exam = examWithCategories("a", "b");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveCategoryUp(EXAM_ID, 0));
        verify(template, never()).save(any(Exam.class));
    }

    @Test
    void moveCategoryUpShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.moveCategoryUp(EXAM_ID, 0));
        verify(template, never()).save(any(Exam.class));
    }

    @Test
    void moveCategoryDownShouldSwapWithNext() {
        Exam exam = examWithCategories("a", "b", "c");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveCategoryDown(EXAM_ID, 0));

        Exam saved = captureSavedExam();
        assertEquals(List.of("b", "a", "c"),
                saved.getCategories().stream().map(QuestionCategory::getDescription).toList());
    }

    @Test
    void moveCategoryDownShouldBeNoOpAtLastIndex() {
        Exam exam = examWithCategories("a", "b");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveCategoryDown(EXAM_ID, 1));
        verify(template, never()).save(any(Exam.class));
    }

    @Test
    void moveCategoryDownShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.moveCategoryDown(EXAM_ID, 0));
    }

    // ============================================================
    // Pattern B：deleteSubCategoryFromExam
    // ============================================================

    @Test
    void deleteSubCategoryFromExamShouldRemoveOnlyInGivenCategory() {
        Exam exam = examWithCategories("c0", "c1");
        // c0: 子项 [s0a, s0b]; c1: 子项 [s1a, s1b, s1c]
        setSubCategories(exam, 0, "s0a", "s0b");
        setSubCategories(exam, 1, "s1a", "s1b", "s1c");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.deleteSubCategoryFromExam(EXAM_ID, 1, 0));

        Exam saved = captureSavedExam();
        // c0 不受影响
        assertEquals(2, saved.getCategories().get(0).getSubCategories().size());
        // c1 删掉 s1a
        List<QuestionSubCategory> c1subs = saved.getCategories().get(1).getSubCategories();
        assertEquals(2, c1subs.size());
        assertEquals("s1b", c1subs.get(0).getDescription());
        assertEquals("s1c", c1subs.get(1).getDescription());
    }

    @Test
    void deleteSubCategoryFromExamShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.deleteSubCategoryFromExam(EXAM_ID, 0, 0));
    }

    // ============================================================
    // Pattern B：moveSubCategoryUp / moveSubCategoryDown
    // ============================================================

    @Test
    void moveSubCategoryUpShouldSwap() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "a", "b", "c");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveSubCategoryUp(EXAM_ID, 0, 2));

        Exam saved = captureSavedExam();
        assertEquals(List.of("a", "c", "b"),
                saved.getCategories().get(0).getSubCategories().stream()
                        .map(QuestionSubCategory::getDescription).toList());
    }

    @Test
    void moveSubCategoryUpShouldBeNoOpAtIndexZero() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "a", "b");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveSubCategoryUp(EXAM_ID, 0, 0));
        verify(template, never()).save(any(Exam.class));
    }

    @Test
    void moveSubCategoryDownShouldSwap() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "a", "b", "c");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveSubCategoryDown(EXAM_ID, 0, 0));

        Exam saved = captureSavedExam();
        assertEquals(List.of("b", "a", "c"),
                saved.getCategories().get(0).getSubCategories().stream()
                        .map(QuestionSubCategory::getDescription).toList());
    }

    @Test
    void moveSubCategoryDownShouldBeNoOpAtLastIndex() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "a", "b");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveSubCategoryDown(EXAM_ID, 0, 1));
        verify(template, never()).save(any(Exam.class));
    }

    @Test
    void moveSubCategoryUpShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.moveSubCategoryUp(EXAM_ID, 0, 0));
    }

    @Test
    void moveSubCategoryDownShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.moveSubCategoryDown(EXAM_ID, 0, 0));
    }

    // ============================================================
    // Pattern B：deleteQuestion / moveQuestionUp / moveQuestionDown
    // ============================================================

    @Test
    void deleteQuestionShouldRemoveAndReturnRemovedId() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        setQuestions(exam, 0, 0, "q1", "q2", "q3");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        String removed = dao.deleteQuestion(EXAM_ID, 0, 0, 1);

        assertEquals("q2", removed);
        Exam saved = captureSavedExam();
        assertEquals(List.of("q1", "q3"),
                saved.getCategories().get(0).getSubCategories().get(0).getQuestions());
    }

    @Test
    void deleteQuestionShouldReturnNullWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertNull(dao.deleteQuestion(EXAM_ID, 0, 0, 0));
    }

    @Test
    void moveQuestionUpShouldSwap() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        setQuestions(exam, 0, 0, "q1", "q2", "q3");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveQuestionUp(EXAM_ID, 0, 0, 2));

        Exam saved = captureSavedExam();
        assertEquals(List.of("q1", "q3", "q2"),
                saved.getCategories().get(0).getSubCategories().get(0).getQuestions());
    }

    @Test
    void moveQuestionUpShouldBeNoOpAtIndexZero() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        setQuestions(exam, 0, 0, "q1", "q2");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveQuestionUp(EXAM_ID, 0, 0, 0));
        verify(template, never()).save(any(Exam.class));
    }

    @Test
    void moveQuestionDownShouldSwap() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        setQuestions(exam, 0, 0, "q1", "q2", "q3");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveQuestionDown(EXAM_ID, 0, 0, 0));

        Exam saved = captureSavedExam();
        assertEquals(List.of("q2", "q1", "q3"),
                saved.getCategories().get(0).getSubCategories().get(0).getQuestions());
    }

    @Test
    void moveQuestionDownShouldBeNoOpAtLastIndex() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        setQuestions(exam, 0, 0, "q1", "q2");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.moveQuestionDown(EXAM_ID, 0, 0, 1));
        verify(template, never()).save(any(Exam.class));
    }

    @Test
    void moveQuestionUpShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.moveQuestionUp(EXAM_ID, 0, 0, 0));
    }

    @Test
    void moveQuestionDownShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.moveQuestionDown(EXAM_ID, 0, 0, 0));
    }

    // ============================================================
    // Pattern B：updateCategory / updateSubCategory
    // ============================================================

    @Test
    void updateCategoryShouldReplaceAtGivenIndex() {
        Exam exam = examWithCategories("old0", "old1");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        QuestionCategory replacement = new QuestionCategory();
        replacement.setDescription("new1");
        assertEquals(1L, dao.updateCategory(EXAM_ID, 1, replacement));

        Exam saved = captureSavedExam();
        assertEquals("old0", saved.getCategories().get(0).getDescription());
        assertEquals("new1", saved.getCategories().get(1).getDescription());
    }

    @Test
    void updateCategoryShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.updateCategory(EXAM_ID, 0, new QuestionCategory()));
    }

    @Test
    void updateSubCategoryShouldReplaceAtCorrectCoordinates() {
        Exam exam = examWithCategories("c0", "c1");
        setSubCategories(exam, 0, "s0a");
        setSubCategories(exam, 1, "s1a", "s1b");
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        QuestionSubCategory replacement = new QuestionSubCategory();
        replacement.setDescription("new-s1a");
        assertEquals(1L, dao.updateSubCategory(EXAM_ID, 1, 0, replacement));

        Exam saved = captureSavedExam();
        // c0 不变
        assertEquals("s0a", saved.getCategories().get(0).getSubCategories().get(0).getDescription());
        // c1[0] 替换、c1[1] 不变
        assertEquals("new-s1a", saved.getCategories().get(1).getSubCategories().get(0).getDescription());
        assertEquals("s1b", saved.getCategories().get(1).getSubCategories().get(1).getDescription());
    }

    @Test
    void updateSubCategoryShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.updateSubCategory(EXAM_ID, 0, 0, new QuestionSubCategory()));
    }

    // ============================================================
    // Pattern B：DiagnosisRule delete / update
    // ============================================================

    @Test
    void deleteDiagnosisRuleShouldRemoveAtGivenIndex() {
        Exam exam = simpleExam();
        exam.setDiagnosisRules(new LinkedList<>(List.of(
                rule("R0"), rule("R1"), rule("R2"))));
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.deleteDiagnosisRule(EXAM_ID, 1));

        Exam saved = captureSavedExam();
        assertEquals(2, saved.getDiagnosisRules().size());
        assertEquals("R0", saved.getDiagnosisRules().get(0).getAphasiaType());
        assertEquals("R2", saved.getDiagnosisRules().get(1).getAphasiaType());
    }

    @Test
    void deleteDiagnosisRuleShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.deleteDiagnosisRule(EXAM_ID, 0));
    }

    @Test
    void updateDiagnosisRuleShouldReplaceAtGivenIndex() {
        Exam exam = simpleExam();
        exam.setDiagnosisRules(new LinkedList<>(List.of(rule("R0"), rule("R1"))));
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1, dao.updateDiagnosisRule(EXAM_ID, 0, rule("R0-new")));

        Exam saved = captureSavedExam();
        assertEquals("R0-new", saved.getDiagnosisRules().get(0).getAphasiaType());
        assertEquals("R1", saved.getDiagnosisRules().get(1).getAphasiaType());
    }

    @Test
    void updateDiagnosisRuleShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0, dao.updateDiagnosisRule(EXAM_ID, 0, new DiagnosisRule()));
    }

    // ============================================================
    // Pattern B：TerminateRule add / update / delete
    // ============================================================

    @Test
    void addTerminateRuleShouldAppendToSubCategory() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        QuestionSubCategory sub = exam.getCategories().get(0).getSubCategories().get(0);
        sub.setTerminateRules(new LinkedList<>(List.of(terminateRule("R0"))));
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.addTerminateRule(EXAM_ID, 0, 0, terminateRule("R1")));

        Exam saved = captureSavedExam();
        List<TerminateRule> rules = saved.getCategories().get(0).getSubCategories().get(0).getTerminateRules();
        assertEquals(2, rules.size());
        assertEquals("R0", rules.get(0).getReason());
        assertEquals("R1", rules.get(1).getReason());
    }

    @Test
    void updateTerminateRuleShouldReplaceAtCorrectCoordinates() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        QuestionSubCategory sub = exam.getCategories().get(0).getSubCategories().get(0);
        sub.setTerminateRules(new LinkedList<>(List.of(terminateRule("R0"), terminateRule("R1"))));
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.updateTerminateRule(EXAM_ID, 0, 0, 1, terminateRule("R1-new")));

        Exam saved = captureSavedExam();
        List<TerminateRule> rules = saved.getCategories().get(0).getSubCategories().get(0).getTerminateRules();
        assertEquals("R0", rules.get(0).getReason());
        assertEquals("R1-new", rules.get(1).getReason());
    }

    @Test
    void deleteTerminateRuleShouldRemoveAtCorrectCoordinates() {
        Exam exam = examWithCategories("c0");
        setSubCategories(exam, 0, "s0");
        QuestionSubCategory sub = exam.getCategories().get(0).getSubCategories().get(0);
        sub.setTerminateRules(new LinkedList<>(List.of(terminateRule("R0"), terminateRule("R1"))));
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(exam);

        assertEquals(1L, dao.deleteTerminateRule(EXAM_ID, 0, 0, 0));

        Exam saved = captureSavedExam();
        List<TerminateRule> rules = saved.getCategories().get(0).getSubCategories().get(0).getTerminateRules();
        assertEquals(1, rules.size());
        assertEquals("R1", rules.get(0).getReason());
    }

    @Test
    void addTerminateRuleShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.addTerminateRule(EXAM_ID, 0, 0, new TerminateRule()));
    }

    @Test
    void updateTerminateRuleShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.updateTerminateRule(EXAM_ID, 0, 0, 0, new TerminateRule()));
    }

    @Test
    void deleteTerminateRuleShouldReturnZeroWhenExamNotFound() {
        when(template.findById(EXAM_ID, Exam.class)).thenReturn(null);
        assertEquals(0L, dao.deleteTerminateRule(EXAM_ID, 0, 0, 0));
    }

    // ============================================================
    // Helpers
    // ============================================================

    @SuppressWarnings("unchecked")
    private void stubFluentUpdateWithModifiedCount(long modifiedCount) {
        ExecutableUpdate<Exam> exec = mock(ExecutableUpdate.class);
        UpdateWithUpdate<Exam> withUpdate = mock(UpdateWithUpdate.class);
        TerminatingUpdate<Exam> terminating = mock(TerminatingUpdate.class);
        UpdateResult result = mock(UpdateResult.class);

        when(template.update(Exam.class)).thenReturn(exec);
        when(exec.matching(any(CriteriaDefinition.class))).thenReturn(withUpdate);
        when(withUpdate.apply(any(Update.class))).thenReturn(terminating);
        when(terminating.all()).thenReturn(result);
        when(result.getModifiedCount()).thenReturn(modifiedCount);
    }

    private Exam captureSavedExam() {
        ArgumentCaptor<Exam> captor = ArgumentCaptor.forClass(Exam.class);
        verify(template, times(1)).save(captor.capture());
        return captor.getValue();
    }

    private Exam simpleExam() {
        Exam exam = new Exam();
        exam.setId(EXAM_ID);
        exam.setName("套题");
        exam.setOwnerId("doctor-1");
        exam.setCategories(new LinkedList<>());
        exam.setDiagnosisRules(new LinkedList<>());
        return exam;
    }

    private Exam examWithCategories(String... descriptions) {
        Exam exam = simpleExam();
        for (String d : descriptions) {
            QuestionCategory cat = new QuestionCategory();
            cat.setDescription(d);
            cat.setSubCategories(new LinkedList<>());
            cat.setRules(new LinkedList<>());
            exam.getCategories().add(cat);
        }
        return exam;
    }

    private void setSubCategories(Exam exam, int categoryIndex, String... descriptions) {
        QuestionCategory cat = exam.getCategories().get(categoryIndex);
        List<QuestionSubCategory> subs = new LinkedList<>();
        for (String d : descriptions) {
            QuestionSubCategory sub = new QuestionSubCategory();
            sub.setDescription(d);
            sub.setQuestions(new LinkedList<>());
            sub.setTerminateRules(new LinkedList<>());
            sub.setEvalRules(new LinkedList<>());
            subs.add(sub);
        }
        cat.setSubCategories(subs);
    }

    private void setQuestions(Exam exam, int categoryIndex, int subCategoryIndex, String... questionIds) {
        exam.getCategories().get(categoryIndex).getSubCategories().get(subCategoryIndex)
                .setQuestions(new LinkedList<>(List.of(questionIds)));
    }

    private DiagnosisRule rule(String aphasiaType) {
        DiagnosisRule r = new DiagnosisRule();
        r.setAphasiaType(aphasiaType);
        return r;
    }

    private TerminateRule terminateRule(String reason) {
        TerminateRule r = new TerminateRule();
        r.setReason(reason);
        return r;
    }
}
