package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.request.ConversationRequest;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.services.LLMService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@Slf4j
@RequireRole({2})
@RestController
@RequestMapping("/api")
public class LLMController {
    @Autowired
    private LLMService llmService;

    /**
     * 大模型诊断患病类型与严重程度
     * 
     * @param jsonConversation 医患对话内容 { "conversation": "..." }
     * @return 诊断结果 { "type": "...", "severity": "..." }
     * @throws Exception 调用异常
     */
    @PostMapping("/diagnose1")
    public Map<String, Object> diagnose1(@Valid @RequestBody ConversationRequest req) throws Exception {
        log.debug("diagnose1 called");
        return llmService.diagnose1(req.getConversation());
    }

    /**
     * 大模型计算患者话的困惑度
     * 
     * @param jsonConversation 医患对话内容 { "conversation": "..." }
     * @return 困惑度 { "perplexity": ... }
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