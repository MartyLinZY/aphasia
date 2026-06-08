package com.blkn.lr.lr_new_server.dto.apiproxy;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
public class PinyinMatchResult {
    boolean matched;
    double similarity;
    String expectedPinyin;
    String actualPinyin;
}
