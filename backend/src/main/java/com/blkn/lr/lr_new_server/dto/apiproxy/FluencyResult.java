package com.blkn.lr.lr_new_server.dto.apiproxy;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class FluencyResult {
    double fluency;
    String detail;
    String content;
}
