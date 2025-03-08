package com.blkn.lr.lr_new_server.dto.flytek.audio;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AudioRecognizeParams {
    List<Byte> data;
}
