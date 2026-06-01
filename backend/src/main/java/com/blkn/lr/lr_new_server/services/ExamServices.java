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
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ExamServices {
    private final ExamDao examDao;
    private final QuestionDao questionDao;
    private final ExamMapper examMapper;
    private final QuestionMapper questionMapper;

    public ExamDto getExamById(String examId) {
        Exam exam = examDao.findPublishedExamById(examId);
        if (exam == null) {
            throw new NotFoundException();
        }
        return examMapper.toDto(exam);
    }

    public ExamDto createExam(ExamDto dto, String uid) {
        Exam created = examDao.save(examMapper.toModel(dto, uid));
        return examMapper.toDto(created);
    }

    public List<ExamDto> getExamsByDoctorId(String targetUID, boolean isRecovery) {
        return examDao.getExamsByDoctorId(targetUID, isRecovery).stream()
                .map(examMapper::toDto)
                .toList();
    }

    public long deleteExam(String examId) {
        return examDao.deleteExam(examId);
    }

    public void updateExamName(String examId, String newName) {
        if (examDao.updateExamName(examId, newName) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新套题名称失败");
        }
    }

    public void updateExamDesc(String examId, String desc) {
        if (examDao.updateExamDesc(examId, desc) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新套题简介失败");
        }
    }

    public void publishExam(String examId) {
        if (examDao.publishExam(examId) <= 0) {
            throw new BusinessErrorException("发布id为" + examId + "的套题失败");
        }
    }

    public QuestionCategoryDto addCategory(QuestionCategoryDto newCategory, String examId) {
        if (examDao.addCategoryIntoExam(examId, examMapper.categoryToModel(newCategory)) > 0) {
            return newCategory;
        } else {
            throw new BusinessErrorException("在id为" + examId + "的套题中新增亚项失败");
        }
    }

    public void updateCategory(String examId, int categoryIndex, QuestionCategoryDto newCategory) {
        if (examDao.updateCategory(examId, categoryIndex, examMapper.categoryToModel(newCategory)) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新亚项"+ categoryIndex + "失败");
        }
    }

    public void deleteCategory(String examId, int categoryIndex) {
        if (examDao.deleteCategoryFromExam(examId, categoryIndex) <= 0) {
           throw new BusinessErrorException("在id为" + examId + "的套题中删除亚项"+ categoryIndex + "失败");
        }
    }

    public void moveCategoryUp(String examId, int categoryIndex) {
        if (examDao.moveCategoryUp(examId, categoryIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中上移亚项"+ categoryIndex + "失败");
        }
    }

    public void moveCategoryDown(String examId, int categoryIndex) {
        if (examDao.moveCategoryDown(examId, categoryIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中下移亚项"+ categoryIndex + "失败");
        }
    }

    public QuestionSubCategoryDto addSubCategoryIntoExam(String examId, int categoryIndex, QuestionSubCategoryDto dto) {
        if (examDao.addSubCategoryIntoExam(examId, categoryIndex, examMapper.subCategoryToModel(dto)) > 0) {
            return dto;
        }
        throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下新增子项失败");
    }

    public void updateSubCategory(String examId, int categoryIndex, int subCategoryIndex, QuestionSubCategoryDto newSubCategory) {
        if (examDao.updateSubCategory(examId, categoryIndex, subCategoryIndex, examMapper.subCategoryToModel(newSubCategory)) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下更新子项"+ subCategoryIndex +"失败");
        }
    }

    public void deleteSubCategoryFromExam(String examId, int categoryIndex, int subCategoryIndex) {
        if (examDao.deleteSubCategoryFromExam(examId, categoryIndex, subCategoryIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下删除子项" + subCategoryIndex + "失败");
        }
    }

    public void moveSubCategoryUp(String examId, int categoryIndex, int subCategoryIndex) {
        if (examDao.moveSubCategoryUp(examId, categoryIndex, subCategoryIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下上移子项" + subCategoryIndex + "失败");
        }
    }

    public void moveSubCategoryDown(String examId, int categoryIndex, int subCategoryIndex) {
        if (examDao.moveSubCategoryDown(examId, categoryIndex, subCategoryIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下下移子项" + subCategoryIndex + "失败");
        }
    }

    public QuestionDto addQuestion(String uid, String examId, int cateIndex, int subCateIndex, QuestionDto dto) {
        Question created = questionDao.save(questionMapper.toModel(dto, uid));

        if (examDao.addQuestionIntoExam(examId, cateIndex, subCateIndex, created.getId()) <= 0) {
            throw new BusinessErrorException("将问题插入套题失败，请检查");
        }

        return questionMapper.toDto(created);
    }

    public QuestionDto updateQuestion(QuestionDto dto, String uid) {
        Question saved = questionDao.save(questionMapper.toModel(dto, uid));
        return questionMapper.toDto(saved);
    }

    public void deleteQuestion(String examId, int categoryIndex, int subCategoryIndex, int questionIndex) {
        String removeId = examDao.deleteQuestion(examId, categoryIndex, subCategoryIndex, questionIndex);
        if (removeId == null) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下删除题目" + questionIndex + "失败");
        }

        questionDao.deleteById(removeId);
    }

    public void moveQuestionUp(String examId, int categoryIndex, int subCategoryIndex, int questionIndex) {
        if (examDao.moveQuestionUp(examId, categoryIndex, subCategoryIndex, questionIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下上移题目" + questionIndex + "失败");
        }
    }

    public void moveQuestionDown(String examId, int categoryIndex, int subCategoryIndex, int questionIndex) {
        if (examDao.moveQuestionDown(examId, categoryIndex, subCategoryIndex, questionIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下下移题目" + questionIndex + "失败");
        }
    }

    public void addDiagnoseRule(String examId, DiagnosisRule rule) {
        if (examDao.addDiagnosisRule(examId, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中新增诊断规则失败");
        }
    }

    public void updateDiagnoseRule(String examId, int ruleIndex, DiagnosisRule rule) {
        if (examDao.updateDiagnosisRule(examId, ruleIndex, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中更新第"+ ruleIndex+ "个诊断规则失败");
        }
    }

    public void deleteDiagnoseRule(String examId, int ruleIndex) {
        if (examDao.deleteDiagnosisRule(examId, ruleIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中删除第"+ ruleIndex+ "个诊断规则失败");
        }
    }

    public void addTerminateRule(String examId, int categoryIndex, int subCategoryIndex, TerminateRule rule) {
        if (examDao.addTerminateRule(examId, categoryIndex, subCategoryIndex, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下新增中止规则失败");
        }
    }

    public void updateTerminateRule(String examId, int categoryIndex, int subCategoryIndex, int ruleIndex, TerminateRule rule) {
        if (examDao.updateTerminateRule(examId, categoryIndex, subCategoryIndex, ruleIndex, rule) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下更新第" + ruleIndex + "个中止规则失败");
        }
    }

    public void deleteTerminateRule(String examId, int categoryIndex, int subCategoryIndex, int ruleIndex) {
        if (examDao.deleteTerminateRule(examId, categoryIndex, subCategoryIndex, ruleIndex) <= 0) {
            throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下子项" + subCategoryIndex + "下删除第" + ruleIndex + "个中止规则失败");
        }
    }
}
