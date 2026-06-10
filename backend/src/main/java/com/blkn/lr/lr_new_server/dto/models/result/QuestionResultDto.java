package com.blkn.lr.lr_new_server.dto.models.result;

import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuestionResultDto {
    @NotNull(message = "sourceQuestion不能为null")
    @Valid
    QuestionDto sourceQuestion;
    Double finalScore;
    Integer answerTime;
    Boolean isHinted;
    Map<String, String> extraResults;
    String typeName;
}
