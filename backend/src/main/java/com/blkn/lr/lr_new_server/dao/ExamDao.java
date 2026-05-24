package com.blkn.lr.lr_new_server.dao;

import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;

import java.util.List;

/**
 * 套题数据访问抽象。Controller / Service 应依赖本接口而非具体实现。
 */
public interface ExamDao {
    Exam save(Exam newModel);

    Exam findPublishedExamById(String examId);

    List<Exam> getExamsByDoctorId(String targetUID, boolean isRecovery);

    long addCategoryIntoExam(String examId, QuestionCategory model);

    long deleteExam(String examId);

    long deleteCategoryFromExam(String examId, int categoryIndex);

    long moveCategoryUp(String examId, int categoryIndex);

    long moveCategoryDown(String examId, int categoryIndex);

    long addSubCategoryIntoExam(String examId, int categoryIndex, QuestionSubCategory model);

    long deleteSubCategoryFromExam(String examId, int categoryIndex, int subCategoryIndex);

    long moveSubCategoryUp(String examId, int categoryIndex, int subCategoryIndex);

    long moveSubCategoryDown(String examId, int categoryIndex, int subCategoryIndex);

    long addQuestionIntoExam(String examId, int categoryIndex, int subCategoryIndex, String questionId);

    String deleteQuestion(String examId, int categoryIndex, int subCategoryIndex, int questionIndex);

    long moveQuestionUp(String examId, int categoryIndex, int subCategoryIndex, int questionIndex);

    long moveQuestionDown(String examId, int categoryIndex, int subCategoryIndex, int questionIndex);

    long updateCategory(String examId, int categoryIndex, QuestionCategory newCategory);

    long updateExamName(String examId, String newName);

    long updateExamDesc(String examId, String desc);

    long updateSubCategory(String examId, int categoryIndex, int subCategoryIndex, QuestionSubCategory subCategory);

    long addDiagnosisRule(String examId, DiagnosisRule rule);

    long deleteDiagnosisRule(String examId, int ruleIndex);

    int updateDiagnosisRule(String examId, int ruleIndex, DiagnosisRule rule);

    long addTerminateRule(String examId, int categoryIndex, int subCategoryIndex, TerminateRule rule);

    long updateTerminateRule(String examId, int categoryIndex, int subCategoryIndex, int ruleIndex, TerminateRule rule);

    long deleteTerminateRule(String examId, int categoryIndex, int subCategoryIndex, int ruleIndex);

    long publishExam(String examId);
}
