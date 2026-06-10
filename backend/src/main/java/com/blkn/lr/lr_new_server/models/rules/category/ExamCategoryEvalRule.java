package com.blkn.lr.lr_new_server.models.rules.category;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ExamCategoryEvalRule {
    // factory dispatch key，缺失会让前端 fromJson 失败。
    @NotBlank
    String typeName;
}
