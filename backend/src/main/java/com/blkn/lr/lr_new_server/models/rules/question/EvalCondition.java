package com.blkn.lr.lr_new_server.models.rules.question;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class EvalCondition {
    double score;
    boolean isHinted;
    List<Map<String, Number>> ranges;
}
