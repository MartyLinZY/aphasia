package com.blkn.lr.lr_new_server.models.rules.exam;

import com.fasterxml.jackson.annotation.JsonInclude;
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
    String typeName;
    List<Integer> categoryIndices;

    List<Map<String, Double>> ranges;

    String aphasiaType;
}
