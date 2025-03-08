package com.blkn.lr.lr_new_server.dto.models.exam;

import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.rules.category.ExamCategoryEvalRule;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class QuestionCategoryDto {
    String description;
    List<QuestionSubCategoryDto> subCategories;
    List<ExamCategoryEvalRule> rules;

    QuestionCategoryDto(QuestionCategory category, QuestionDaoImpl questionDao) {
        description = category.getDescription();
        subCategories = category.getSubCategories().stream().map(e -> new QuestionSubCategoryDto(e, questionDao)).toList();
        rules = category.getRules();
    }

    public QuestionCategory toModel() {
        QuestionCategory category = new QuestionCategory();

        category.setDescription(description);
        category.setSubCategories(subCategories.stream().map(QuestionSubCategoryDto::toModel).toList());
        category.setRules(rules);

        return category;
    }
}