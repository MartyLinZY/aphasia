package com.blkn.lr.lr_new_server.models.exam;

import com.blkn.lr.lr_new_server.models.rules.subcategory.ExamSubCategoryEvalRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuestionSubCategory {
    String description;
    // question的id列表
    List<String> questions;
    List<TerminateRule> terminateRules;
    List<ExamSubCategoryEvalRule> evalRules;
}
