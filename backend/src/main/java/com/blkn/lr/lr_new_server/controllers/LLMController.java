package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.request.ConversationRequest;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.services.LLMService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@Slf4j
@RequireRole({2})
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class LLMController {
    private final LLMService llmService;

    /**
     * 客观特征诊断：返回是否失语、严重度、加权分、特征向量与证据特征。
     * （旧 /diagnose1 大模型一锤子判类型已删除——实测类型无效、误诊率高；
     *   旧困惑度实现也已废弃，方向被语料证伪。端点名暂留 diagnose2。）
     *
     * @param req 医患对话内容 { "conversation": "..." }
     * @return { "hasAphasia": bool, "severity": "...", "score": ..., "features": {...}, "evidence": [...] }
     * @throws Exception 调用异常
     */
    @PostMapping("/diagnose2")
    public Map<String, Object> diagnose2(@Valid @RequestBody ConversationRequest req) throws Exception {
        log.debug("diagnose2 called");
        return llmService.diagnose2(req.getConversation());
    }

    /**
     * 大模型修复患者的话
     *
     * @param jsonConversation 医患对话内容 { "conversation": "..." }
     * @return 修复后的对话 { "repairedConversation": ... }
     * @throws Exception 调用异常
     */
    @PostMapping("/repair")
    public Map<String, Object> repair(@Valid @RequestBody ConversationRequest req) throws Exception {
        log.debug("repair called");
        return llmService.repair(req.getConversation());
    }
}