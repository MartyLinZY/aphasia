package com.blkn.lr.lr_new_server.models.results;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuestionResult {
    String sourceQuestion;
    Double finalScore;
    Integer answerTime;
    Boolean isHinted;
    Map<String, String> extraResults;
    String typeName;
}
