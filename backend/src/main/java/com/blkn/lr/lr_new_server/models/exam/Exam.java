package com.blkn.lr.lr_new_server.models.exam;

import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.exam.ExamEvalRule;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Exam{
    String id;

    // 属主用户
    String ownerId;

    // 测评名称
    String name;

    // 测评简介
    String description;

    // 是否为康复套题
    boolean isRecovery;

    // 是否已发布
    boolean isPublished;

    // 是否已删除
    boolean isDisabled;

    // 亚项列表
    List<QuestionCategory> categories;

    // 诊断规则
    List<DiagnosisRule> diagnosisRules;

    // 评分规则 - 暂不使用
    List<ExamEvalRule> rules;
}
