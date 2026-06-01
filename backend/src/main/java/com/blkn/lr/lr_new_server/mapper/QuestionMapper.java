package com.blkn.lr.lr_new_server.mapper;

import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.models.question.Question;
import org.springframework.stereotype.Component;

@Component
public class QuestionMapper {

    public QuestionDto toDto(Question q) {
        QuestionDto dto = new QuestionDto();
        if (q != null) {
            dto.setId(q.getId());
            dto.setAlias(q.getAlias());
            dto.setQuestionText(q.getQuestionText());
            dto.setAudioUrl(q.getAudioUrl());
            dto.setImageUrl(q.getImageUrl());
            dto.setOmitImageAfterSeconds(q.getOmitImageAfterSeconds());
            dto.setTypeName(q.getTypeName());
            dto.setEvalRule(q.getEvalRule());
        } else {
            // 原题已被删除：返回占位 DTO（保留答题记录的可读性）
            dto.setAlias("原问题已删除");
            dto.setQuestionText("");
            dto.setOmitImageAfterSeconds(-1);
            dto.setTypeName("AudioQuestion");
        }
        return dto;
    }

    public Question toModel(QuestionDto dto, String ownerId) {
        Question model = new Question();
        if (dto.getId() != null) {
            model.setId(dto.getId());
        }
        model.setOwnerId(ownerId);
        model.setAlias(dto.getAlias());
        model.setQuestionText(dto.getQuestionText());
        model.setAudioUrl(dto.getAudioUrl());
        model.setImageUrl(dto.getImageUrl());
        model.setOmitImageAfterSeconds(dto.getOmitImageAfterSeconds());
        model.setTypeName(dto.getTypeName());
        model.setEvalRule(dto.getEvalRule());
        return model;
    }
}
