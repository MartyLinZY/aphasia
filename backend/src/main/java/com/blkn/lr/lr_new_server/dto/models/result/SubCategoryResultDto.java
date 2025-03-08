package com.blkn.lr.lr_new_server.dto.models.result;

import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.models.results.SubCategoryResult;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class SubCategoryResultDto {
    String name;
    Double finalScore;
    String terminateReason;
    List<QuestionResultDto> questionResults;

    public SubCategoryResultDto(SubCategoryResult subCategoryResult, QuestionDaoImpl questionDao) {
        name = subCategoryResult.getName();
        finalScore = subCategoryResult.getFinalScore();
        terminateReason = subCategoryResult.getTerminateReason();
        questionResults = subCategoryResult.getQuestionResults().stream().map(e -> new QuestionResultDto(e, questionDao)).toList();
    }

    public SubCategoryResult toModel() {
        SubCategoryResult result = new SubCategoryResult();
        result.setName(name);
        result.setFinalScore(finalScore);
        result.setTerminateReason(terminateReason);
        result.setQuestionResults(questionResults.stream().map(QuestionResultDto::toModel).toList());
        return result;
    }
}
