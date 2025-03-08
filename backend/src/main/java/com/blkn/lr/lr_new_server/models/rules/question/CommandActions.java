package com.blkn.lr.lr_new_server.models.rules.question;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CommandActions {
    // 第一个物体在可操作区域中的index
    Integer sourceSlotIndex;
    // 第一个物体的操作
    String firstAction;
    // 第二个物体在可操作区域中的index
    Integer targetSlotIndex;
    // 第一个物体在第二个物体上的操作
    String secondAction;
}
