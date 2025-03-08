package com.blkn.lr.lr_new_server.dto.models.question;

import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.rules.question.QuestionEvalRule;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuestionDto {
    String id;
    // 题目别名
    String alias;
    // 题干文本
    String questionText;
    // 题干音频
    String audioUrl;
    // 题干图片
    String imageUrl;
    // 题干图片展示时间，以秒为单位，除了-1表示始终显示题干图片外需要为正整数
    int omitImageAfterSeconds;
    // 题目类型（前端类名）
    String typeName;

    QuestionEvalRule evalRule;

    public QuestionDto(Question q) {
        if (q != null) {
            id = q.getId();
            alias = q.getAlias();
            questionText = q.getQuestionText();
            audioUrl = q.getAudioUrl();
            imageUrl = q.getImageUrl();
            omitImageAfterSeconds = q.getOmitImageAfterSeconds();
            typeName = q.getTypeName();
            evalRule = q.getEvalRule();
        } else {
            alias = "原问题已删除";
            questionText = "";
            omitImageAfterSeconds = -1;
            typeName = "AudioQuestion";
        }
    }

    public Question toModel(String ownerId) {
        Question model = new Question();

        if (id != null) {
            model.setId(id);
        }

        model.setOwnerId(ownerId);

        model.setAlias(alias);
        model.setQuestionText(questionText);
        model.setAudioUrl(audioUrl);
        model.setImageUrl(imageUrl);
        model.setOmitImageAfterSeconds(omitImageAfterSeconds);
        model.setTypeName(typeName);
        model.setEvalRule(evalRule);

        return model;
    }
}
