package com.blkn.lr.lr_new_server.dto.models.exam;

import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.rules.subcategory.ExamSubCategoryEvalRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class QuestionSubCategoryDto {
    String description;
    // question的id列表
    List<QuestionDto> questions;
    List<TerminateRule> terminateRules;
    List<ExamSubCategoryEvalRule> evalRules;

    QuestionSubCategoryDto(QuestionSubCategory subCategory, QuestionDaoImpl questionDao) {
        description = subCategory.getDescription();

        questions = subCategory.getQuestions().stream().map(id -> {
          Question q = questionDao.findById(id);
          return new QuestionDto(q);
        }).toList();

        terminateRules = subCategory.getTerminateRules();
        evalRules = subCategory.getEvalRules();
    }

    public QuestionSubCategory toModel() {
        QuestionSubCategory model = new QuestionSubCategory();

        model.setDescription(description);
        model.setQuestions(questions.stream().map(QuestionDto::getId).toList());
        model.setTerminateRules(terminateRules);
        model.setEvalRules(evalRules);

        return model;
    }
}
