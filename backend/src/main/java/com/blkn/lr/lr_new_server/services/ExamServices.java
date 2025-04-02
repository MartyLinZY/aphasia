package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dao.impl.ExamDaoImpl;
import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionSubCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;

import java.util.List;

import static org.springframework.data.mongodb.core.query.Criteria.where;

@Service
public class ExamServices {
    @Autowired
    private ExamDaoImpl examDao;

    @Autowired
    private QuestionDaoImpl questionDao;

    public ExamDto createExam(ExamDto dto, String uid) {
//        printAsJson(dto);
        Exam created = examDao.save(dto.toModel(uid));

//        printAsJson(created);

        return new ExamDto(created, questionDao);
    }


    private <T> void printAsJson (T createdModel) {
        ObjectWriter ow = new ObjectMapper().writer().withDefaultPrettyPrinter();

        try {
            System.out.println(ow.writeValueAsString(createdModel));
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
    }

    public List<ExamDto> getExamsByDoctorId(String targetUID, boolean isRecovery) {
        List<Exam> exams = examDao.getExamsByDoctorId(targetUID, isRecovery);
//        printAsJson(exams);

        return exams.stream().map(e -> new ExamDto(e, questionDao)).toList();
    }

    public long deleteExam(String examId) {
        return examDao.deleteExam(examId);
    }

    public QuestionCategoryDto addCategory(QuestionCategoryDto newCategory, String examId) {
        if (examDao.addCategoryIntoExam(examId, newCategory.toModel()) > 0) {
            return newCategory;
        } else {
            throw new BusinessErrorException("在id为" + examId + "的套题中新增亚项失败");
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
        if (examDao.addSubCategoryIntoExam(examId, categoryIndex, dto.toModel()) > 0) {
            return dto;
        }

        throw new BusinessErrorException("在id为" + examId + "的套题中亚项"+ categoryIndex + "下新增子项失败");

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

    public QuestionDto addQuestionIntoExam(String examId, int categoryIndex, int subCategoryIndex, QuestionDto newQuestion, String uid) {
        Question newModel = newQuestion.toModel(uid);

        Question created = questionDao.save(newModel);
        if (created == null) {
            throw new BusinessErrorException("创建题目失败");
        }

        String questionId = created.getId();
        examDao.addQuestionIntoExam(examId, categoryIndex, subCategoryIndex, questionId);

        return new QuestionDto(created);
    }

    public QuestionDto addQuestion(String uid, String examId, int cateIndex, int subCateIndex, QuestionDto dto) {
        // 保存问题
        Question newModel = dto.toModel(uid);
        Question createdModel = questionDao.save(newModel);

//        printAsJson(createdModel);

        // 将问题加入到指定的套题中

        if (examDao.addQuestionIntoExam(examId, cateIndex, subCateIndex, createdModel.getId()) <= 0) {
            throw new BusinessErrorException("将问题插入套题失败，请检查");
        }

        return new QuestionDto(createdModel);
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

}
