package com.blkn.lr.lr_new_server.dto.models.result;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
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
    Boolean isDisabled;
    String examName;

    @NotNull(message = "categoryResults不能为null")
    @Valid
    List<CategoryResultDto> categoryResults;
}
