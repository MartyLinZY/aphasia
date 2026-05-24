package com.blkn.lr.lr_new_server.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * LLM 诊断/修复接口的请求体：{ "conversation": "..." }
 */
@Data
@NoArgsConstructor
public class ConversationRequest {

    @NotBlank(message = "医患对话内容不能为空")
    private String conversation;
}
