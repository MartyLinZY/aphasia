package com.blkn.lr.lr_new_server.dto.models.exam;

import com.blkn.lr.lr_new_server.models.rules.category.ExamCategoryEvalRule;
import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
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

    @NotNull(message = "subCategories不能为null")
    @Valid
    List<QuestionSubCategoryDto> subCategories;
    List<ExamCategoryEvalRule> rules;
}
