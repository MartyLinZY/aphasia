package com.blkn.lr.lr_new_server.models.rules.question;

import com.fasterxml.jackson.annotation.JsonProperty;
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
    // Jackson 默认把 boolean isHinted 序列化成 "hinted"（去 is 前缀），但前端读写 "isHinted"，
    // 导致提示条件的 isHinted 标志在前后端 JSON 往返中丢失 → 全部当 false → 提示后重答得分不更新
    // （提示后 result.isHinted=true，但没有 isHinted=true 的条件能匹配，保留旧分）。强制用 isHinted。
    @JsonProperty("isHinted")
    boolean isHinted;
    List<Map<String, Number>> ranges;
}
