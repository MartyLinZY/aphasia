package com.blkn.lr.lr_new_server.dto.models.question;

import com.blkn.lr.lr_new_server.models.rules.question.QuestionEvalRule;
import jakarta.validation.constraints.NotBlank;
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
    @NotBlank(message = "题目类型typeName不能为空")
    String typeName;

    QuestionEvalRule evalRule;
}
