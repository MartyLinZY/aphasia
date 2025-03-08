package com.blkn.lr.lr_new_server.models.rules.exam;


import com.blkn.lr.lr_new_server.pojo.ScoreRange;

import java.util.List;

public class DiagnoseByScoreRange extends DiagnosisRule {
    /// [ranges]的长度与[categoryIndices]的长度一致
    List<ScoreRange> ranges;

    String aphasiaType;

    String typeName;
}
