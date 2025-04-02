package com.blkn.lr.lr_new_server.models.results;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ExamResult {
    String id;
    String ownerId;
    String resultText;
    Double finalScore;
    Date startTime;
    Date finishTime;
    Boolean isRecovery;
    Boolean isDisabled;
    String examName;
    List<CategoryResult> categoryResults;
}
