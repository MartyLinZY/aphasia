package com.blkn.lr.lr_new_server.dto.models.result;

import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.models.results.CategoryResult;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CategoryResultDto {
    String name;
    Double finalScore;

    @NotNull(message = "subResults不能为null")
    @Valid
    List<SubCategoryResultDto> subResults;

    public CategoryResultDto(CategoryResult categoryResult, QuestionDao questionDao) {
        name = categoryResult.getName();
        finalScore = categoryResult.getFinalScore();
        subResults = categoryResult.getSubResults().stream().map(e -> new SubCategoryResultDto(e, questionDao)).toList();
    }

    public CategoryResult toModel() {
        CategoryResult categoryResult = new CategoryResult();
        categoryResult.setName(name);
        categoryResult.setFinalScore(finalScore);
        categoryResult.setSubResults(subResults.stream().map(SubCategoryResultDto::toModel).toList());
        return categoryResult;
    }
}
