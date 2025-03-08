package com.blkn.lr.lr_new_server.models.rules.question;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Choice {
    String imageUrl;
    String imageAssetPath;
    String text;
}
