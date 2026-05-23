package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.services.LLMService;
import com.blkn.lr.lr_new_server.services.TranslationService;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 验证各 Controller 的角色注解（@RequireRole）与请求体参数校验（@Valid）。
 */
class ControllerSecurityTest {

    // ---------- 角色注解覆盖 ----------

    @Test
    void resultControllerShouldBePatientOnly() {
        RequireRole role = ResultController.class.getAnnotation(RequireRole.class);
        assertNotNull(role, "ResultController 应带 @RequireRole");
        assertArrayEquals(new int[]{1}, role.value());
    }

    @Test
    void fileControllerShouldAllowBothRoles() {
        RequireRole role = FileController.class.getAnnotation(RequireRole.class);
        assertNotNull(role, "FileController 应带 @RequireRole");
        assertArrayEquals(new int[]{1, 2}, role.value());
    }

    @Test
    void translationControllerShouldAllowBothRoles() {
        RequireRole role = TranslationController.class.getAnnotation(RequireRole.class);
        assertNotNull(role, "TranslationController 应带 @RequireRole");
        assertArrayEquals(new int[]{1, 2}, role.value());
    }

    @Test
    void llmControllerShouldBeDoctorOnly() {
        RequireRole role = LLMController.class.getAnnotation(RequireRole.class);
        assertNotNull(role, "LLMController 应带 @RequireRole");
        assertArrayEquals(new int[]{2}, role.value());
    }

    // ---------- 参数校验 ----------

    @Test
    void diagnose1ShouldReturn400WhenConversationBlank() throws Exception {
        LLMService svc = Mockito.mock(LLMService.class);
        LLMController controller = new LLMController(svc);
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        // 空白对话 -> 校验失败 -> 400（此前抛 IllegalArgumentException 会落到 500）
        mockMvc.perform(post("/api/diagnose1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conversation\":\"   \"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void diagnose1ShouldPassWhenConversationPresent() throws Exception {
        LLMService svc = Mockito.mock(LLMService.class);
        when(svc.diagnose1(anyString())).thenReturn(Map.of("type", "运动性失语"));
        LLMController controller = new LLMController(svc);
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        mockMvc.perform(post("/api/diagnose1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conversation\":\"医生：你好\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void translateShouldReturn400WhenTextBlank() throws Exception {
        TranslationService svc = Mockito.mock(TranslationService.class);
        TranslationController controller = new TranslationController(svc);
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        mockMvc.perform(post("/api/translate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"\"}"))
                .andExpect(status().isBadRequest());
    }
}
