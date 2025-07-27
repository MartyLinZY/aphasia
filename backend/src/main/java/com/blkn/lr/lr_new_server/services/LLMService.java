package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.util.PythonInvoker;
import org.springframework.stereotype.Service;
import java.util.Map;

/**
 * 服务类：封装对话诊断业务逻辑，调用Python诊断脚本
 */
@Service
public class LLMService {
    /**
     * 大模型诊断患病类型与严重程度(diagnose1)
     * 
     * @param conversation 医患对话内容
     * @return 包含type(患病类型)和severity(严重程度)的Map
     * @throws Exception 调用异常
     */
    public Map<String, Object> diagnose1(String conversation) throws Exception {
        return PythonInvoker.invokeDiagnose("diagnose1", conversation);
    }

    /**
     * 大模型计算患者话的困惑度(diagnose2)
     * 
     * @param conversation 医患对话内容
     * @return 包含perplexity(困惑度)的Map
     * @throws Exception 调用异常
     */
    public Map<String, Object> diagnose2(String conversation) throws Exception {
        return PythonInvoker.invokeDiagnose("diagnose2", conversation);
    }

    /**
     * 大模型修复患者的话(repair)
     *
     * @param conversation 医患对话内容
     * @return 包含repairedConversation(修复后的话)的Map
     * @throws Exception 调用异常
     */
    public Map<String, Object> repair(String conversation) throws Exception {
        return PythonInvoker.invokeRepair(conversation);
    }
}