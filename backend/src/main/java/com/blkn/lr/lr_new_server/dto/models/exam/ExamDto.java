package com.blkn.lr.lr_new_server.dto.models.exam;

import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.exam.ExamEvalRule;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ExamDto {
    String id;

    // 测评名称
    @NotBlank(message = "测评名称不能为空")
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
    @NotNull(message = "categories不能为null")
    @Valid
    List<QuestionCategoryDto> categories;

    // 诊断规则
    List<DiagnosisRule> diagnosisRules;

    // 评分规则 - 暂不使用
    List<ExamEvalRule> rules;
}
