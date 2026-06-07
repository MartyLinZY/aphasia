package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dao.ExamDao;
import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionSubCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.exception.NotFoundException;
import com.blkn.lr.lr_new_server.mapper.ExamMapper;
import com.blkn.lr.lr_new_server.mapper.QuestionMapper;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * ExamServices 单元测试。
 *
 * <p>ExamServices 在项 12（2026-06-01）那轮把 Controller 里 13+ 个直调 DAO 的位置下沉而来，
 * 但当时没补 Service 层测试 —— JaCoCo 报告里这个类是后端最大盲区（3.7%，512 instructions）。
 *
 * <p>本类几乎所有方法都是同一个 pattern：
 * <pre>
 *   if (dao.xxx(...) &lt;= 0) throw new BusinessErrorException("拼接的中文提示");
 * </pre>
 * 关心的是两件事：
 * <ol>
 *   <li>happy path：DAO 返回 &gt; 0 时，不抛异常，必要时返回值穿透；</li>
 *   <li>sad path：DAO 返回 0 时，抛 BusinessErrorException —— 异常 message 里嵌入了
 *       examId / 各级 index / ruleIndex，是日志检索的唯一线索，**需要锁住**，
 *       不然下次重构改错 message 模板，问题排查会断链。</li>
 * </ol>
 *
 * <p>4 个依赖（ExamDao / QuestionDao / ExamMapper / QuestionMapper）全部 Mockito 桩；
 * 重点是 ExamServices 自身的编排逻辑，不重复 ExamDaoImplTest 已经覆盖的 DAO 行为，
 * 也不重复 ExamMapperTest 已经覆盖的 mapper 批量预 fetch 行为。
 */
class ExamServicesTest {

    private static final String EXAM_ID = "exam-1";
    private static final String UID = "doctor-1";

    private ExamDao examDao;
    private QuestionDao questionDao;
    private ExamMapper examMapper;
    private QuestionMapper questionMapper;
    private ExamServices service;

    @BeforeEach
    void setUp() {
        examDao = mock(ExamDao.class);
        questionDao = mock(QuestionDao.class);
        examMapper = mock(ExamMapper.class);
        questionMapper = mock(QuestionMapper.class);
        service = new ExamServices(examDao, questionDao, examMapper, questionMapper);
    }

    // ============================================================
    // getExamById / createExam / getExamsByDoctorId
    // ============================================================

    @Test
    void getExamByIdShouldReturnMappedDtoWhenFound() {
        Exam exam = new Exam();
        ExamDto dto = new ExamDto();
        when(examDao.findPublishedExamById(EXAM_ID)).thenReturn(exam);
        when(examMapper.toDto(exam)).thenReturn(dto);

        assertSame(dto, service.getExamById(EXAM_ID));
    }

    @Test
    void getExamByIdShouldThrowNotFoundWhenExamMissing() {
        when(examDao.findPublishedExamById(EXAM_ID)).thenReturn(null);

        assertThrows(NotFoundException.class, () -> service.getExamById(EXAM_ID));
        verify(examMapper, never()).toDto(any(Exam.class));
    }

    @Test
    void createExamShouldRoundTripThroughMapperAndDao() {
        ExamDto inputDto = new ExamDto();
        Exam toSave = new Exam();
        Exam saved = new Exam();
        ExamDto returnedDto = new ExamDto();

        when(examMapper.toModel(inputDto, UID)).thenReturn(toSave);
        when(examDao.save(toSave)).thenReturn(saved);
        when(examMapper.toDto(saved)).thenReturn(returnedDto);

        assertSame(returnedDto, service.createExam(inputDto, UID));
        verify(examDao).save(toSave);
    }

    @Test
    void getExamsByDoctorIdShouldMapEachExamThroughExamMapper() {
        Exam e1 = new Exam();
        Exam e2 = new Exam();
        ExamDto d1 = new ExamDto();
        ExamDto d2 = new ExamDto();
        when(examDao.getExamsByDoctorId(UID, false)).thenReturn(List.of(e1, e2));
        when(examMapper.toDto(e1)).thenReturn(d1);
        when(examMapper.toDto(e2)).thenReturn(d2);

        List<ExamDto> result = service.getExamsByDoctorId(UID, false);

        assertEquals(List.of(d1, d2), result);
    }

    @Test
    void getExamsByDoctorIdShouldPassRecoveryFlagThrough() {
        when(examDao.getExamsByDoctorId(UID, true)).thenReturn(List.of());

        assertEquals(0, service.getExamsByDoctorId(UID, true).size());
        verify(examDao).getExamsByDoctorId(UID, true);
    }

    // ============================================================
    // deleteExam（不抛异常的特例 —— 直接 return long）
    // ============================================================

    @Test
    void deleteExamShouldPassThroughDaoCount() {
        when(examDao.deleteExam(EXAM_ID)).thenReturn(1L);
        assertEquals(1L, service.deleteExam(EXAM_ID));
    }

    @Test
    void deleteExamShouldPassThroughZeroWithoutThrowing() {
        // deleteExam 是唯一一个不在零结果时抛异常的方法（Controller 层自行决定如何处理 0）
        when(examDao.deleteExam(EXAM_ID)).thenReturn(0L);
        assertEquals(0L, service.deleteExam(EXAM_ID));
    }

    // ============================================================
    // updateExamName / updateExamDesc / publishExam
    // ============================================================

    @Test
    void updateExamNameHappyPath() {
        when(examDao.updateExamName(EXAM_ID, "新名")).thenReturn(1L);
        service.updateExamName(EXAM_ID, "新名");
        verify(examDao).updateExamName(EXAM_ID, "新名");
    }

    @Test
    void updateExamNameShouldThrowWhenDaoReturnsZero() {
        when(examDao.updateExamName(EXAM_ID, "新名")).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.updateExamName(EXAM_ID, "新名"));
        assertEquals("在id为" + EXAM_ID + "的套题中更新套题名称失败", e.getMessage());
    }

    @Test
    void updateExamDescHappyPath() {
        when(examDao.updateExamDesc(EXAM_ID, "新简介")).thenReturn(1L);
        service.updateExamDesc(EXAM_ID, "新简介");
    }

    @Test
    void updateExamDescShouldThrowWhenDaoReturnsZero() {
        when(examDao.updateExamDesc(EXAM_ID, "新简介")).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.updateExamDesc(EXAM_ID, "新简介"));
        assertEquals("在id为" + EXAM_ID + "的套题中更新套题简介失败", e.getMessage());
    }

    @Test
    void publishExamHappyPath() {
        when(examDao.publishExam(EXAM_ID)).thenReturn(1L);
        service.publishExam(EXAM_ID);
    }

    @Test
    void publishExamShouldThrowWhenDaoReturnsZero() {
        when(examDao.publishExam(EXAM_ID)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.publishExam(EXAM_ID));
        assertEquals("发布id为" + EXAM_ID + "的套题失败", e.getMessage());
    }

    // ============================================================
    // Category：add / update / delete / move
    // ============================================================

    @Test
    void addCategoryHappyPathShouldReturnInputDto() {
        QuestionCategoryDto dto = new QuestionCategoryDto();
        QuestionCategory model = new QuestionCategory();
        when(examMapper.categoryToModel(dto)).thenReturn(model);
        when(examDao.addCategoryIntoExam(EXAM_ID, model)).thenReturn(1L);

        assertSame(dto, service.addCategory(dto, EXAM_ID));
    }

    @Test
    void addCategoryShouldThrowWhenDaoReturnsZero() {
        QuestionCategoryDto dto = new QuestionCategoryDto();
        when(examMapper.categoryToModel(dto)).thenReturn(new QuestionCategory());
        when(examDao.addCategoryIntoExam(eq(EXAM_ID), any())).thenReturn(0L);

        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.addCategory(dto, EXAM_ID));
        assertEquals("在id为" + EXAM_ID + "的套题中新增亚项失败", e.getMessage());
    }

    @Test
    void updateCategoryHappyPath() {
        QuestionCategoryDto dto = new QuestionCategoryDto();
        QuestionCategory model = new QuestionCategory();
        when(examMapper.categoryToModel(dto)).thenReturn(model);
        when(examDao.updateCategory(EXAM_ID, 2, model)).thenReturn(1L);

        service.updateCategory(EXAM_ID, 2, dto);
        verify(examDao).updateCategory(EXAM_ID, 2, model);
    }

    @Test
    void updateCategoryShouldThrowWithIndexInMessage() {
        when(examMapper.categoryToModel(any())).thenReturn(new QuestionCategory());
        when(examDao.updateCategory(eq(EXAM_ID), eq(2), any())).thenReturn(0L);

        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.updateCategory(EXAM_ID, 2, new QuestionCategoryDto()));
        assertEquals("在id为" + EXAM_ID + "的套题中更新亚项2失败", e.getMessage());
    }

    @Test
    void deleteCategoryHappyPath() {
        when(examDao.deleteCategoryFromExam(EXAM_ID, 0)).thenReturn(1L);
        service.deleteCategory(EXAM_ID, 0);
    }

    @Test
    void deleteCategoryShouldThrowWithIndexInMessage() {
        when(examDao.deleteCategoryFromExam(EXAM_ID, 0)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.deleteCategory(EXAM_ID, 0));
        assertEquals("在id为" + EXAM_ID + "的套题中删除亚项0失败", e.getMessage());
    }

    @Test
    void moveCategoryUpHappyPath() {
        when(examDao.moveCategoryUp(EXAM_ID, 1)).thenReturn(1L);
        service.moveCategoryUp(EXAM_ID, 1);
    }

    @Test
    void moveCategoryUpShouldThrowWhenDaoReturnsZero() {
        when(examDao.moveCategoryUp(EXAM_ID, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.moveCategoryUp(EXAM_ID, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中上移亚项1失败", e.getMessage());
    }

    @Test
    void moveCategoryDownHappyPath() {
        when(examDao.moveCategoryDown(EXAM_ID, 1)).thenReturn(1L);
        service.moveCategoryDown(EXAM_ID, 1);
    }

    @Test
    void moveCategoryDownShouldThrowWhenDaoReturnsZero() {
        when(examDao.moveCategoryDown(EXAM_ID, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.moveCategoryDown(EXAM_ID, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中下移亚项1失败", e.getMessage());
    }

    // ============================================================
    // SubCategory：add / update / delete / move
    // ============================================================

    @Test
    void addSubCategoryHappyPathShouldReturnInputDto() {
        QuestionSubCategoryDto dto = new QuestionSubCategoryDto();
        QuestionSubCategory model = new QuestionSubCategory();
        when(examMapper.subCategoryToModel(dto)).thenReturn(model);
        when(examDao.addSubCategoryIntoExam(EXAM_ID, 0, model)).thenReturn(1L);

        assertSame(dto, service.addSubCategoryIntoExam(EXAM_ID, 0, dto));
    }

    @Test
    void addSubCategoryShouldThrowWithCategoryIndexInMessage() {
        when(examMapper.subCategoryToModel(any())).thenReturn(new QuestionSubCategory());
        when(examDao.addSubCategoryIntoExam(eq(EXAM_ID), eq(3), any())).thenReturn(0L);

        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.addSubCategoryIntoExam(EXAM_ID, 3, new QuestionSubCategoryDto()));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项3下新增子项失败", e.getMessage());
    }

    @Test
    void updateSubCategoryHappyPath() {
        QuestionSubCategoryDto dto = new QuestionSubCategoryDto();
        QuestionSubCategory model = new QuestionSubCategory();
        when(examMapper.subCategoryToModel(dto)).thenReturn(model);
        when(examDao.updateSubCategory(EXAM_ID, 1, 2, model)).thenReturn(1L);

        service.updateSubCategory(EXAM_ID, 1, 2, dto);
    }

    @Test
    void updateSubCategoryShouldThrowWithBothIndicesInMessage() {
        when(examMapper.subCategoryToModel(any())).thenReturn(new QuestionSubCategory());
        when(examDao.updateSubCategory(eq(EXAM_ID), eq(1), eq(2), any())).thenReturn(0L);

        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.updateSubCategory(EXAM_ID, 1, 2, new QuestionSubCategoryDto()));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项1下更新子项2失败", e.getMessage());
    }

    @Test
    void deleteSubCategoryHappyPath() {
        when(examDao.deleteSubCategoryFromExam(EXAM_ID, 0, 1)).thenReturn(1L);
        service.deleteSubCategoryFromExam(EXAM_ID, 0, 1);
    }

    @Test
    void deleteSubCategoryShouldThrowWithBothIndicesInMessage() {
        when(examDao.deleteSubCategoryFromExam(EXAM_ID, 0, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.deleteSubCategoryFromExam(EXAM_ID, 0, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下删除子项1失败", e.getMessage());
    }

    @Test
    void moveSubCategoryUpHappyPath() {
        when(examDao.moveSubCategoryUp(EXAM_ID, 0, 1)).thenReturn(1L);
        service.moveSubCategoryUp(EXAM_ID, 0, 1);
    }

    @Test
    void moveSubCategoryUpShouldThrowWithBothIndicesInMessage() {
        when(examDao.moveSubCategoryUp(EXAM_ID, 0, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.moveSubCategoryUp(EXAM_ID, 0, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下上移子项1失败", e.getMessage());
    }

    @Test
    void moveSubCategoryDownHappyPath() {
        when(examDao.moveSubCategoryDown(EXAM_ID, 0, 1)).thenReturn(1L);
        service.moveSubCategoryDown(EXAM_ID, 0, 1);
    }

    @Test
    void moveSubCategoryDownShouldThrowWithBothIndicesInMessage() {
        when(examDao.moveSubCategoryDown(EXAM_ID, 0, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.moveSubCategoryDown(EXAM_ID, 0, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下下移子项1失败", e.getMessage());
    }

    // ============================================================
    // Question：add / update / delete / move
    // ============================================================

    @Test
    void addQuestionHappyPathShouldSaveQuestionThenLinkIntoExam() {
        QuestionDto dto = new QuestionDto();
        Question toSave = new Question();
        Question saved = new Question();
        saved.setId("q-new");
        QuestionDto returnedDto = new QuestionDto();

        when(questionMapper.toModel(dto, UID)).thenReturn(toSave);
        when(questionDao.save(toSave)).thenReturn(saved);
        when(examDao.addQuestionIntoExam(EXAM_ID, 0, 0, "q-new")).thenReturn(1L);
        when(questionMapper.toDto(saved)).thenReturn(returnedDto);

        assertSame(returnedDto, service.addQuestion(UID, EXAM_ID, 0, 0, dto));
    }

    @Test
    void addQuestionShouldThrowIfExamLinkFailsAfterQuestionSaved() {
        // 半提交隐患：questionDao.save 已经把题写进 questions collection，
        // 但 examDao.addQuestionIntoExam 失败 —— 此时抛异常，外层不会回滚
        // questionDao.save。这条测试明确锁定当前行为，方便未来如果决定加事务
        // 时立刻 fail 提醒。
        QuestionDto dto = new QuestionDto();
        Question saved = new Question();
        saved.setId("q-orphan");
        when(questionMapper.toModel(dto, UID)).thenReturn(new Question());
        when(questionDao.save(any())).thenReturn(saved);
        when(examDao.addQuestionIntoExam(EXAM_ID, 0, 0, "q-orphan")).thenReturn(0L);

        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.addQuestion(UID, EXAM_ID, 0, 0, dto));
        assertEquals("将问题插入套题失败，请检查", e.getMessage());
        verify(questionDao).save(any());
    }

    @Test
    void updateQuestionShouldRoundTripThroughMapperAndDao() {
        QuestionDto dto = new QuestionDto();
        Question toSave = new Question();
        Question saved = new Question();
        QuestionDto returnedDto = new QuestionDto();

        when(questionMapper.toModel(dto, UID)).thenReturn(toSave);
        when(questionDao.save(toSave)).thenReturn(saved);
        when(questionMapper.toDto(saved)).thenReturn(returnedDto);

        assertSame(returnedDto, service.updateQuestion(dto, UID));
    }

    @Test
    void deleteQuestionShouldCascadeDeleteFromQuestionsCollection() {
        // 双 DAO 串联：先从 exam 树里 pop 出 questionId，再用这个 id 从
        // questions 集合删 Question 文档。覆盖断了哪一段都会成孤儿/悬挂。
        when(examDao.deleteQuestion(EXAM_ID, 0, 0, 0)).thenReturn("q-removed");

        service.deleteQuestion(EXAM_ID, 0, 0, 0);

        verify(examDao).deleteQuestion(EXAM_ID, 0, 0, 0);
        verify(questionDao).deleteById("q-removed");
    }

    @Test
    void deleteQuestionShouldThrowAndSkipCascadeWhenExamReturnsNull() {
        // exam 路径找不到这道题（null）→ 抛异常，不走 questionDao.deleteById
        // —— 不然会基于 null id 调用 deleteById，产生意外行为
        when(examDao.deleteQuestion(EXAM_ID, 0, 0, 0)).thenReturn(null);

        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.deleteQuestion(EXAM_ID, 0, 0, 0));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下子项0下删除题目0失败", e.getMessage());
        verify(questionDao, never()).deleteById(anyString());
    }

    @Test
    void moveQuestionUpHappyPath() {
        when(examDao.moveQuestionUp(EXAM_ID, 0, 0, 1)).thenReturn(1L);
        service.moveQuestionUp(EXAM_ID, 0, 0, 1);
    }

    @Test
    void moveQuestionUpShouldThrowWithFullCoordinatesInMessage() {
        when(examDao.moveQuestionUp(EXAM_ID, 0, 0, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.moveQuestionUp(EXAM_ID, 0, 0, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下子项0下上移题目1失败", e.getMessage());
    }

    @Test
    void moveQuestionDownHappyPath() {
        when(examDao.moveQuestionDown(EXAM_ID, 0, 0, 1)).thenReturn(1L);
        service.moveQuestionDown(EXAM_ID, 0, 0, 1);
    }

    @Test
    void moveQuestionDownShouldThrowWithFullCoordinatesInMessage() {
        when(examDao.moveQuestionDown(EXAM_ID, 0, 0, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.moveQuestionDown(EXAM_ID, 0, 0, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下子项0下下移题目1失败", e.getMessage());
    }

    // ============================================================
    // DiagnoseRule：add / update / delete
    // ============================================================

    @Test
    void addDiagnoseRuleHappyPath() {
        DiagnosisRule rule = new DiagnosisRule();
        when(examDao.addDiagnosisRule(EXAM_ID, rule)).thenReturn(1L);
        service.addDiagnoseRule(EXAM_ID, rule);
    }

    @Test
    void addDiagnoseRuleShouldThrowWhenDaoReturnsZero() {
        when(examDao.addDiagnosisRule(eq(EXAM_ID), any())).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.addDiagnoseRule(EXAM_ID, new DiagnosisRule()));
        assertEquals("在id为" + EXAM_ID + "的套题中新增诊断规则失败", e.getMessage());
    }

    @Test
    void updateDiagnoseRuleHappyPath() {
        DiagnosisRule rule = new DiagnosisRule();
        when(examDao.updateDiagnosisRule(EXAM_ID, 2, rule)).thenReturn(1);
        service.updateDiagnoseRule(EXAM_ID, 2, rule);
    }

    @Test
    void updateDiagnoseRuleShouldThrowWithRuleIndexInMessage() {
        when(examDao.updateDiagnosisRule(eq(EXAM_ID), eq(2), any())).thenReturn(0);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.updateDiagnoseRule(EXAM_ID, 2, new DiagnosisRule()));
        assertEquals("在id为" + EXAM_ID + "的套题中更新第2个诊断规则失败", e.getMessage());
    }

    @Test
    void deleteDiagnoseRuleHappyPath() {
        when(examDao.deleteDiagnosisRule(EXAM_ID, 1)).thenReturn(1L);
        service.deleteDiagnoseRule(EXAM_ID, 1);
    }

    @Test
    void deleteDiagnoseRuleShouldThrowWithRuleIndexInMessage() {
        when(examDao.deleteDiagnosisRule(EXAM_ID, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.deleteDiagnoseRule(EXAM_ID, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中删除第1个诊断规则失败", e.getMessage());
    }

    // ============================================================
    // TerminateRule：add / update / delete
    // ============================================================

    @Test
    void addTerminateRuleHappyPath() {
        TerminateRule rule = new TerminateRule();
        when(examDao.addTerminateRule(EXAM_ID, 0, 0, rule)).thenReturn(1L);
        service.addTerminateRule(EXAM_ID, 0, 0, rule);
    }

    @Test
    void addTerminateRuleShouldThrowWithBothIndicesInMessage() {
        when(examDao.addTerminateRule(eq(EXAM_ID), eq(0), eq(0), any())).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.addTerminateRule(EXAM_ID, 0, 0, new TerminateRule()));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下子项0下新增中止规则失败", e.getMessage());
    }

    @Test
    void updateTerminateRuleHappyPath() {
        TerminateRule rule = new TerminateRule();
        when(examDao.updateTerminateRule(EXAM_ID, 0, 0, 1, rule)).thenReturn(1L);
        service.updateTerminateRule(EXAM_ID, 0, 0, 1, rule);
    }

    @Test
    void updateTerminateRuleShouldThrowWithFullCoordinatesInMessage() {
        when(examDao.updateTerminateRule(eq(EXAM_ID), eq(0), eq(0), eq(1), any())).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.updateTerminateRule(EXAM_ID, 0, 0, 1, new TerminateRule()));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下子项0下更新第1个中止规则失败", e.getMessage());
    }

    @Test
    void deleteTerminateRuleHappyPath() {
        when(examDao.deleteTerminateRule(EXAM_ID, 0, 0, 1)).thenReturn(1L);
        service.deleteTerminateRule(EXAM_ID, 0, 0, 1);
    }

    @Test
    void deleteTerminateRuleShouldThrowWithFullCoordinatesInMessage() {
        when(examDao.deleteTerminateRule(EXAM_ID, 0, 0, 1)).thenReturn(0L);
        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.deleteTerminateRule(EXAM_ID, 0, 0, 1));
        assertEquals("在id为" + EXAM_ID + "的套题中亚项0下子项0下删除第1个中止规则失败", e.getMessage());
    }
}
