package com.blkn.lr.lr_new_server.dto.apiproxy;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
public class AudioFromTextRequest {
    // 空 text → 讯飞 TTS 会返同步失败；>100 字符的合成也无业务意义且会拖长 30s 超时窗。
    @NotBlank
    @Size(max = 100)
    String text;
}
