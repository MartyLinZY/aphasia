package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionSubCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.models.rules.category.ExamCategoryEvalRule;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.ExamSubCategoryEvalRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import com.blkn.lr.lr_new_server.services.ExamServices;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Objects;

@RestController
@RequestMapping("/api")
@RequireRole({2})
@RequiredArgsConstructor
public class ExamController {
    private final ExamServices examServices;

    @GetMapping("/exams/{examId}")
    @RequireRole({1, 2})
    ExamDto getExamById(@PathVariable String examId) {
        return examServices.getExamById(examId);
    }

    @GetMapping("/doctors/{uid}/exams")
    List<ExamDto> getExamsByDoctorId(@PathVariable("uid") String targetUID, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        if (!Objects.equals(uid, targetUID)) {
            throw new BusinessErrorException("用户" + uid + "尝试获取" + targetUID + "用户的套题");
        }

        return examServices.getExamsByDoctorId(targetUID, false);
    }

    @GetMapping("/doctors/{uid}/recoveries")
    List<ExamDto> getRecoveriesByDoctorId(@PathVariable("uid") String targetUID, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        if (!Objects.equals(uid, targetUID)) {
            throw new BusinessErrorException("用户" + uid + "尝试获取" + targetUID + "用户的套题");
        }

        return examServices.getExamsByDoctorId(targetUID, true);
    }


    @PostMapping("/exams")
    ExamDto createExam(@Valid @RequestBody ExamDto newExam, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        return examServices.createExam(newExam, uid);
    }


    @PatchMapping("/exams/{examId}/name/{newName}")
    Map<String, String> updateExamName(@PathVariable String examId, @PathVariable String newName) {
        examServices.updateExamName(examId, newName);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/desc/{desc}")
    Map<String, String> updateExamDesc(@PathVariable String examId, @PathVariable String desc) {
        examServices.updateExamDesc(examId, desc);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}")
    Map<String, String> publishExam(@PathVariable String examId) {
        examServices.publishExam(examId);
        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}")
    Map<String, String> deleteExam(@PathVariable String examId) {
        if (examServices.deleteExam(examId) <= 0) {
            throw new BusinessErrorException("删除id为" + examId + "的套题失败");
        }
        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/category")
    QuestionCategoryDto addCategory(@Valid @RequestBody QuestionCategoryDto newCategory, @PathVariable("examId") String examId) {
        return examServices.addCategory(newCategory, examId);
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}")
    Map<String, String> updateCategory(@Valid @RequestBody QuestionCategoryDto newCategory, @PathVariable int categoryIndex, @PathVariable("examId") String examId) {
        examServices.updateCategory(examId, categoryIndex, newCategory);
        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/categories/{categoryIndex}")
    public Map<String, String> deleteCategory(@PathVariable String examId, @PathVariable int categoryIndex) {
        examServices.deleteCategory(examId, categoryIndex);

        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/up")
    public Map<String, String> moveCategoryUp(@PathVariable String examId, @PathVariable int categoryIndex) {
        examServices.moveCategoryUp(examId, categoryIndex);

        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/down")
    public Map<String, String> moveCategoryDown(@PathVariable String examId, @PathVariable int categoryIndex) {
        examServices.moveCategoryDown(examId, categoryIndex);
        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/categories/{categoryIndex}/subCategory")
    public Map<String, String> addSubCategoryIntoExam(@PathVariable String examId, @PathVariable int categoryIndex, @Valid @RequestBody QuestionSubCategoryDto dto) {
        examServices.addSubCategoryIntoExam(examId, categoryIndex, dto);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}")
    Map<String, String> updateSubCategory(@Valid @RequestBody QuestionSubCategoryDto newCategory, @PathVariable int categoryIndex, @PathVariable("examId") String examId, @PathVariable int subCategoryIndex) {
        examServices.updateSubCategory(examId, categoryIndex, subCategoryIndex, newCategory);
        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}")
    public Map<String, String> deleteSubCategoryFromExam(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex) {
        examServices.deleteSubCategoryFromExam(examId, categoryIndex, subCategoryIndex);
        return Map.of("msg", "ok");
    }

    @PatchMapping ("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/up")
    public Map<String, String> moveSubCategoryUp(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex) {
        examServices.moveSubCategoryUp(examId, categoryIndex, subCategoryIndex);
        return Map.of("msg", "ok");
    }


    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/down")
    public Map<String, String> moveSubCategoryDown(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex) {
        examServices.moveSubCategoryDown(examId, categoryIndex, subCategoryIndex);
        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{id}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/question")
    QuestionDto addQuestion(@Valid @RequestBody QuestionDto newQuestion,
                            @PathVariable("id") String examId,
                            @PathVariable("categoryIndex") int cateIndex,
                            @PathVariable("subCategoryIndex") int subCateIndex,
                            HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        return examServices.addQuestion(uid, examId, cateIndex, subCateIndex, newQuestion);
    }

    @PatchMapping("/questions/{questionId}")
    QuestionDto updateQuestion(@Valid @RequestBody QuestionDto newQuestion,
                            @PathVariable String questionId,
                            HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        return examServices.updateQuestion(newQuestion, uid);
    }

    @DeleteMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/questions/{questionIndex}")
    public Map<String, String> deleteQuestion(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int questionIndex) {
        examServices.deleteQuestion(examId, categoryIndex, subCategoryIndex, questionIndex);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/questions/{questionIndex}/up")
    public Map<String, String> moveQuestionUp(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int questionIndex) {
        examServices.moveQuestionUp(examId, categoryIndex, subCategoryIndex, questionIndex);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/questions/{questionIndex}/down")
    public Map<String, String> moveQuestionDown(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int questionIndex) {
        examServices.moveQuestionDown(examId, categoryIndex, subCategoryIndex, questionIndex);
        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/diagnosisRule")
    public Map<String, String> addDiagnoseRule(@PathVariable String examId, @Valid @RequestBody DiagnosisRule rule) {
        examServices.addDiagnoseRule(examId, rule);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/diagnosisRules/{ruleIndex}")
    public Map<String, String> updateDiagnoseRule(@PathVariable String examId, @PathVariable int ruleIndex, @Valid @RequestBody DiagnosisRule rule) {
        examServices.updateDiagnoseRule(examId, ruleIndex, rule);
        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/diagnosisRules/{ruleIndex}")
    public Map<String, String> deleteDiagnoseRule(@PathVariable String examId, @PathVariable int ruleIndex) {
        examServices.deleteDiagnoseRule(examId, ruleIndex);
        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/terminateRule")
    public Map<String, String> addTerminateRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @Valid @RequestBody TerminateRule rule) {
        examServices.addTerminateRule(examId, categoryIndex, subCategoryIndex, rule);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/terminateRules/{ruleIndex}")
    public Map<String, String> updateTerminateRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int ruleIndex, @Valid @RequestBody TerminateRule rule) {
        examServices.updateTerminateRule(examId, categoryIndex, subCategoryIndex, ruleIndex, rule);
        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/terminateRules/{ruleIndex}")
    public Map<String, String> deleteTerminateRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int ruleIndex) {
        examServices.deleteTerminateRule(examId, categoryIndex, subCategoryIndex, ruleIndex);
        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/categories/{categoryIndex}/evalRule")
    public Map<String, String> addCategoryEvalRule(@PathVariable String examId, @PathVariable int categoryIndex, @Valid @RequestBody ExamCategoryEvalRule rule) {
        examServices.addCategoryEvalRule(examId, categoryIndex, rule);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/evalRules/{ruleIndex}")
    public Map<String, String> updateCategoryEvalRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int ruleIndex, @Valid @RequestBody ExamCategoryEvalRule rule) {
        examServices.updateCategoryEvalRule(examId, categoryIndex, ruleIndex, rule);
        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/categories/{categoryIndex}/evalRules/{ruleIndex}")
    public Map<String, String> deleteCategoryEvalRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int ruleIndex) {
        examServices.deleteCategoryEvalRule(examId, categoryIndex, ruleIndex);
        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/evalRule")
    public Map<String, String> addSubCategoryEvalRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @Valid @RequestBody ExamSubCategoryEvalRule rule) {
        examServices.addSubCategoryEvalRule(examId, categoryIndex, subCategoryIndex, rule);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/evalRules/{ruleIndex}")
    public Map<String, String> updateSubCategoryEvalRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int ruleIndex, @Valid @RequestBody ExamSubCategoryEvalRule rule) {
        examServices.updateSubCategoryEvalRule(examId, categoryIndex, subCategoryIndex, ruleIndex, rule);
        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/evalRules/{ruleIndex}")
    public Map<String, String> deleteSubCategoryEvalRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int ruleIndex) {
        examServices.deleteSubCategoryEvalRule(examId, categoryIndex, subCategoryIndex, ruleIndex);
        return Map.of("msg", "ok");
    }
}
