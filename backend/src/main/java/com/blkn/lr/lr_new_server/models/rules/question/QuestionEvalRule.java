package com.blkn.lr.lr_new_server.models.rules.question;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class QuestionEvalRule {
    String typeName;

    /// 本题的满分
    Double fullScore;

    /// 答题限时，以秒为单位
    Double timeLimit;

    /// 作答情况不满足已设置的任意打分条件（[conditions]）时题目的得分
    Double defaultScore;

    /// 打分条件，打分规则由[evaluate]实现，一般是遍历打分规则直到找到第一个满足条件规则然后为作答赋分
    List<EvalCondition> conditions;

    /// 提示规则列表
    List<HintRule> hintRules; // 提示必须逐个触发，但一般就一个提示规则

    // 部分题型的模糊评分
    Boolean enableFuzzyEvaluation;

    // 关键词列表
    List<String> keywords;

    // 单个关键词
    String keyword;

    // 作答是否需要和答案顺序一致
    Boolean enforceOrder;

    // 文本相似度判分时计为满分的相似度阈值
    Double fullScoreThreshold;

    // 长文本答案
    String answerText;

    // 特定词性词语个数 - 暂未使用
    Integer wordType;

    // 选项列表
    List<Choice> choices;

    // 正确选项列表
    List<Integer> correctChoices;

    // 可操作区域和物体列表
    List<ItemSlot> slots;

    List<CommandActions> actions;

    /// 患者进行了额外的无效动作时的扣分值
    Double invalidActionPunishment;

    /// 动作拆分模式
    Boolean detailMode;

    /// 系统生成的正确操作对应文本
    String commandText;

    // 场景图片
    String imageUrl;

    // 场景中答案所在区域
    List<List<Double>> coordinates;
}
