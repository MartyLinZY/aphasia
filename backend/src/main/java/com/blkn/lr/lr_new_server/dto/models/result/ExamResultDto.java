package com.blkn.lr.lr_new_server.dto.models.result;

import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ExamResultDto {
    String id;
    String resultText;
    Double finalScore;
    Date startTime;
    Date finishTime;
    Boolean isRecovery;
    String examName;
    List<CategoryResultDto> categoryResults;

    public ExamResultDto(ExamResult examResult, QuestionDaoImpl questionDao) {
        id = examResult.getId();
        resultText = examResult.getResultText();
        finalScore = examResult.getFinalScore();
        startTime = examResult.getStartTime();
        finishTime = examResult.getFinishTime();
        isRecovery = examResult.getIsRecovery();
        examName = examResult.getExamName();
        categoryResults = examResult.getCategoryResults().stream().map(e -> new CategoryResultDto(e, questionDao)).toList();
    }

    public ExamResult toModel(String ownerId) {
        ExamResult model = new ExamResult();
        model.setId(id);
        model.setOwnerId(ownerId);
        model.setResultText(resultText);
        model.setFinalScore(finalScore);
        model.setStartTime(startTime);
        model.setFinishTime(finishTime);
        model.setIsRecovery(isRecovery);
        model.setExamName(examName);
        model.setCategoryResults(categoryResults.stream().map(CategoryResultDto::toModel).toList());
        return model;
    }
}
