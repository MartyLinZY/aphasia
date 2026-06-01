package com.blkn.lr.lr_new_server.dto.models.result;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
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

    @NotNull(message = "questionResults不能为null")
    @Valid
    List<QuestionResultDto> questionResults;
}
