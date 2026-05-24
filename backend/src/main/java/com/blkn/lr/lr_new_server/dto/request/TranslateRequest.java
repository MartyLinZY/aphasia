package com.blkn.lr.lr_new_server.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 文本补全/翻译接口的请求体：{ "text": "..." }
 */
@Data
@NoArgsConstructor
public class TranslateRequest {

    @NotBlank(message = "待翻译文本不能为空")
    private String text;
}
