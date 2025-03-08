package com.blkn.lr.lr_new_server.models.exam;

import com.blkn.lr.lr_new_server.models.rules.category.ExamCategoryEvalRule;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuestionCategory {
    String description;
    List<QuestionSubCategory> subCategories;
    List<ExamCategoryEvalRule> rules;
}