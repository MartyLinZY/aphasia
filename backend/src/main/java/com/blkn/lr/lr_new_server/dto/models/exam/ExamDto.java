package com.blkn.lr.lr_new_server.dto.models.exam;

import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.exam.ExamEvalRule;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonInclude;
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
    List<QuestionCategoryDto> categories;

    // 诊断规则
    List<DiagnosisRule> diagnosisRules;

    // 评分规则 - 暂不使用
    List<ExamEvalRule> rules;

    public ExamDto(Exam exam, QuestionDaoImpl questionDao) {
        id = exam.getId();
        name = exam.getName();
        description = exam.getDescription();
//        isPublished = getIsPublished();
//        isRecovery = getIsRecovery();
        isPublished = exam.isPublished();
        isRecovery = exam.isRecovery();
        isDisabled = exam.isDisabled();
        categories = exam.getCategories().stream().map(e -> new QuestionCategoryDto(e, questionDao)).toList();
        diagnosisRules = exam.getDiagnosisRules();
        rules = exam.getRules();
    }

    public Exam toModel(String ownerId) {
        Exam model = new Exam();

        if (id != null) {
            model.setId(id);
        }

        model.setOwnerId(ownerId);

        model.setName(name);
        model.setDescription(description);
        model.setPublished(isPublished);
        model.setRecovery(isRecovery);
        model.setDisabled(isDisabled);
        model.setCategories(categories.stream().map(QuestionCategoryDto::toModel).toList());
        model.setDiagnosisRules(diagnosisRules);
        model.setRules(rules);

        return model;
    }
}
