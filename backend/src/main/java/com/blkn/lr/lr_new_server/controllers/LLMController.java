package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.services.LLMService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

/**
 * 控制器：对话智能诊断接口
 */
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
    public Map<String, Object> diagnose1(@RequestBody Map<String, String> jsonConversation) throws Exception {
        String conversation = jsonConversation.get("conversation");
        if (conversation == null || conversation.trim().isEmpty()) {
            throw new IllegalArgumentException("医患对话内容不能为空");
        }
        System.out.println("diagnose1 controller called");
        return llmService.diagnose1(conversation);
    }

    /**
     * 大模型计算患者话的困惑度
     * 
     * @param jsonConversation 医患对话内容 { "conversation": "..." }
     * @return 困惑度 { "perplexity": ... }
     * @throws Exception 调用异常
     */
    @PostMapping("/diagnose2")
    public Map<String, Object> diagnose2(@RequestBody Map<String, String> jsonConversation) throws Exception {
        String conversation = jsonConversation.get("conversation");
        if (conversation == null || conversation.trim().isEmpty()) {
            throw new IllegalArgumentException("医患对话内容不能为空");
        }
        System.out.println("diagnose2 controller called");
        return llmService.diagnose2(conversation);
    }

    /**
     * 大模型修复患者的话
     *
     * @param jsonConversation 医患对话内容 { "conversation": "..." }
     * @return 修复后的对话 { "repairedConversation": ... }
     * @throws Exception 调用异常
     */
    @PostMapping("/repair")
    public Map<String, Object> repair(@RequestBody Map<String, String> jsonConversation) throws Exception {
        String conversation = jsonConversation.get("conversation");
        if (conversation == null || conversation.trim().isEmpty()) {
            throw new IllegalArgumentException("医患对话内容不能为空");
        }
        System.out.println("repair controller called");
        return llmService.repair(conversation);
    }
}