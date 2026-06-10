package com.blkn.lr.lr_new_server.models.rules.exam;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DiagnosisRule {
    // typeName 是 factory dispatch 的 key——空值落库后前端 fromJson 会抛
    // UnimplementedError("无法识别的xxx类型")，必须拦在入口。
    @NotBlank
    String typeName;
    List<Integer> categoryIndices;

    List<Map<String, Double>> ranges;

    String aphasiaType;
}
