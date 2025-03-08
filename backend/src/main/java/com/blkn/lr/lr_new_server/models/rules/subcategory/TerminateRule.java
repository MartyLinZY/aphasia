package com.blkn.lr.lr_new_server.models.rules.subcategory;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TerminateRule {
    String reason;
    Double equivalentScore;
    String typeName;

    // 连续答错题数阈值
    Integer errorCountThreshold;
}
