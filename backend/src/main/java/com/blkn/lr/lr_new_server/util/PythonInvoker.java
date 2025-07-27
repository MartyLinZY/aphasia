package com.blkn.lr.lr_new_server.util;

import com.blkn.lr.lr_new_server.config.AppSetting;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Map;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;

/**
 * 工具类：用于调用Python脚本diagnose.py，并解析其JSON输出
 */
public class PythonInvoker {
    private static final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 调用diagnose.py进行大模型诊断
     * 
     * @param mode diagnose1(患病类型与严重程度) 或 diagnose2(困惑度)
     * @param conversation 医患对话内容
     * @return 解析后的Map类型的结果
     * @throws Exception 调用或解析异常
     */
    public static Map<String, Object> invokeDiagnose(String mode, String conversation) throws Exception {
        // String jsonConversation = objectMapper.writeValueAsString(conversation); // 将conversation转换为JSON格式的字符串

        // 组装命令：D:\\python\\python.exe D:\\codes\\aphasia\\LLM\\diagnose.py "mode" "对话内容"
        ProcessBuilder pb = new ProcessBuilder(
            AppSetting.PYTHON_PATH,
            AppSetting.DIAGNOSE_PY_PATH,
            mode,
            conversation);
        pb.redirectErrorStream(true); // 合并标准输出和错误输出
        Process process = pb.start();

        // 读取输出
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream(), "UTF-8"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line);
            }
        }
        int exitCode = process.waitFor();
        String result = output.toString();
        System.out.println("result: " + result);

        // 解析JSON
        try {
            Map<String, Object> map = objectMapper.readValue(result, new TypeReference<Map<String, Object>>() {});
            return map;
        } catch (Exception e) {
            throw new RuntimeException("Python诊断脚本diagnose.py输出解析失败: " + result, e);
        }
    }

    /**
     * 调用repair.py进行大模型修复
     *
     * @param conversation 医患对话内容
     * @return 解析后的Map类型的结果
     * @throws Exception 调用或解析异常
     */
    public static Map<String, Object> invokeRepair(String conversation) throws Exception {

        // 组装命令：D:\\python\\python.exe D:\\codes\\aphasia\\LLM\\repair.py "对话内容"
        ProcessBuilder pb = new ProcessBuilder(
            AppSetting.PYTHON_PATH,
            AppSetting.REPAIR_PY_PATH,
            conversation);
        pb.redirectErrorStream(true); // 合并标准输出和错误输出
        Process process = pb.start();

        // 读取输出
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream(), "UTF-8"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line);
            }
        }
        int exitCode = process.waitFor();
        String result = output.toString();
        System.out.println("result: " + result);

        // 解析JSON
        try {
            Map<String, Object> map = objectMapper.readValue(result, new TypeReference<Map<String, Object>>() {});
            return map;
        } catch (Exception e) {
            throw new RuntimeException("Python修复脚本repair.py输出解析失败: " + result, e);
        }
    }
}