package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dao.impl.ExamDaoImpl;
import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionSubCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.expection.NotFoundException;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import com.blkn.lr.lr_new_server.services.ExamServices;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Objects;

@RestController
@RequestMapping("/api")
public class ExamController {
    @Autowired
    private ExamServices examServices;

    @Autowired
    private ExamDaoImpl examDao;

    @GetMapping("/exams/{examId}")
    ExamDto getExamById(@PathVariable String examId) {
        Exam exam = examDao.findPublishedExamById(examId);

        if (exam == null) {
            throw new NotFoundException();
        }

        return new ExamDto(exam, questionDao);
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
    ExamDto createExam(@RequestBody ExamDto newExam, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        return examServices.createExam(newExam, uid);
    }


    @PatchMapping("/exams/{examId}/name/{newName}")
    Map<String, String> updateExamName(@PathVariable String examId, @PathVariable String newName) {
        if (examDao.updateExamName(examId, newName) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新套题名称失败");
        }

        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/desc/{desc}")
    Map<String, String> updateExamDesc(@PathVariable String examId, @PathVariable String desc) {
        if (examDao.updateExamDesc(examId, desc) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新套题简介失败");
        }

        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}")
    Map<String, String> publishExam(@PathVariable String examId) {
        if (examDao.publishExam(examId) <= 0) {
            throw new BusinessErrorException("发布id为" + examId + "的套题失败");
        }

        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/category")
    QuestionCategoryDto addCategory(@RequestBody QuestionCategoryDto newCategory, @PathVariable("examId") String examId) {
        return examServices.addCategory(newCategory, examId);
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}")
    Map<String, String> updateCategory(@RequestBody QuestionCategoryDto newCategory, @PathVariable int categoryIndex, @PathVariable("examId") String examId) {
        if (examDao.updateCategory(examId, categoryIndex, newCategory.toModel()) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新亚项"+ categoryIndex + "失败");
        }
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
    public Map<String, String> addSubCategoryIntoExam(@PathVariable String examId, @PathVariable int categoryIndex, @RequestBody QuestionSubCategoryDto dto) {
        examServices.addSubCategoryIntoExam(examId, categoryIndex, dto);
        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}")
    Map<String, String> updateSubCategory(@RequestBody QuestionSubCategoryDto newCategory, @PathVariable int categoryIndex, @PathVariable("examId") String examId, @PathVariable int subCategoryIndex) {
        if (examDao.updateSubCategory(examId, categoryIndex, subCategoryIndex, newCategory.toModel()) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下更新子项"+ subCategoryIndex +"失败");
        }
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
    QuestionDto addQuestion(@RequestBody QuestionDto newQuestion,
                            @PathVariable("id") String examId,
                            @PathVariable("categoryIndex") int cateIndex,
                            @PathVariable("subCategoryIndex") int subCateIndex,
                            HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        return examServices.addQuestion(uid, examId, cateIndex, subCateIndex, newQuestion);
    }

    @Autowired
    private QuestionDaoImpl questionDao;
    @PatchMapping("/questions/{questionId}")
    QuestionDto updateQuestion(@RequestBody QuestionDto newQuestion,
                            @PathVariable String questionId,
                            HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        return new QuestionDto(questionDao.save(newQuestion.toModel(uid)));
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
    public Map<String, String> addDiagnoseRule(@PathVariable String examId, @RequestBody DiagnosisRule rule) {
        if (examDao.addDiagnosisRule(examId, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中新增诊断规则失败");
        }

        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/diagnosisRules/{ruleIndex}")
    public Map<String, String> updateDiagnoseRule(@PathVariable String examId, @PathVariable int ruleIndex, @RequestBody DiagnosisRule rule) {
        if (examDao.updateDiagnosisRule(examId, ruleIndex, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新第"+ ruleIndex+ "个诊断规则失败");
        }

        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/diagnosisRules/{ruleIndex}")
    public Map<String, String> deleteDiagnoseRule(@PathVariable String examId, @PathVariable int ruleIndex) {
        if (examDao.deleteDiagnosisRule(examId, ruleIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中删除第"+ ruleIndex+ "个诊断规则失败");
        }

        return Map.of("msg", "ok");
    }

    @PostMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/terminateRule")
    public Map<String, String> addTerminateRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @RequestBody TerminateRule rule) {
        if (examDao.addTerminateRule(examId, categoryIndex, subCategoryIndex, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下新增中止规则失败");
        }

        return Map.of("msg", "ok");
    }

    @PatchMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/terminateRules/{ruleIndex}")
    public Map<String, String> updateTerminateRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int ruleIndex, @RequestBody TerminateRule rule) {
        if (examDao.updateTerminateRule(examId, categoryIndex, subCategoryIndex, ruleIndex, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下更新第" + ruleIndex + "个中止规则失败");
        }

        return Map.of("msg", "ok");
    }

    @DeleteMapping("/exams/{examId}/categories/{categoryIndex}/subCategories/{subCategoryIndex}/terminateRules/{ruleIndex}")
    public Map<String, String> deleteTerminateRule(@PathVariable String examId, @PathVariable int categoryIndex, @PathVariable int subCategoryIndex, @PathVariable int ruleIndex) {
        if (examDao.deleteTerminateRule(examId, categoryIndex, subCategoryIndex, ruleIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下删除第" + ruleIndex + "个中止规则失败");
        }

        return Map.of("msg", "ok");
    }


}
