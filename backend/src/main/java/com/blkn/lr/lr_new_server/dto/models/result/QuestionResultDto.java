package com.blkn.lr.lr_new_server.dto.models.result;

import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.results.QuestionResult;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuestionResultDto {
    QuestionDto sourceQuestion;
    Double finalScore;
    Integer answerTime;
    Boolean isHinted;
    Map<String, String> extraResults;
    String typeName;

    public QuestionResultDto(QuestionResult result, QuestionDaoImpl questionDao) {
        Question q = questionDao.findById(result.getSourceQuestion());
        sourceQuestion = new QuestionDto(q);
        finalScore = result.getFinalScore();
        answerTime = result.getAnswerTime();;
        isHinted = result.getIsHinted();
        extraResults = result.getExtraResults();
        typeName = result.getTypeName();
    }

    public QuestionResult toModel() {
        QuestionResult result = new QuestionResult();
        result.setSourceQuestion(sourceQuestion.getId());
        result.setFinalScore(finalScore);
        result.setAnswerTime(answerTime);
        result.setIsHinted(isHinted);
        result.setExtraResults(extraResults);
        result.setTypeName(typeName);
        return result;
    }
}
