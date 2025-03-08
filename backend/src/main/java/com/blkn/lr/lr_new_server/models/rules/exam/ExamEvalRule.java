package com.blkn.lr.lr_new_server.models.rules.exam;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ExamEvalRule {

    List<Integer> categoryIndices;

    String resultDimensionName;

    String typeName;
}
