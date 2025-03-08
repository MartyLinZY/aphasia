package com.blkn.lr.lr_new_server.models.rules.question;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class HintRule {
    /// 提示文本
    String hintText;
    /// 提示语音文件URL
    String hintAudioUrl;
    /// 提示图片文件URL
    String hintImageUrl;
    /// 提示图片文件asset路径
    String hintImageAssetPath;
    /// 触发提示的分数下限
    double scoreLowBound;
    /// 触发提示的分数上限
    double scoreHighBound;
    /// 调整值，见[scoreAdjustType]的注释
    double adjustValue;
    /// 触发提示后的正确作答得分的调整方式，0表示不调整，1表示减去[adjustValue]（最终不低于0分），2表示设为[adjustValue] - 暂不支持修改，默认为1
    int scoreAdjustType;
}
