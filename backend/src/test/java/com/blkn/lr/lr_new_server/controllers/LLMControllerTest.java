package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.services.LLMService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * LLMController 路由测试。2 个 endpoint（diagnose2 / repair）都是 conversation → LLMService 透传，
 * @Valid 体外校验由 GlobalExceptionHandler 拦 400。（diagnose1 已删除）
 */
class LLMControllerTest {

    private MockMvc mvc;
    private LLMService llmService;

    @BeforeEach
    void setUp() {
        llmService = mock(LLMService.class);
        LLMController controller = new LLMController(llmService);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void diagnose2ShouldDelegateConversationToService() throws Exception {
        when(llmService.diagnose2("医患对话"))
                .thenReturn(Map.of("hasAphasia", true, "severity", "中度", "score", 4.5));

        mvc.perform(post("/api/diagnose2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conversation\":\"医患对话\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hasAphasia").value(true))
                .andExpect(jsonPath("$.severity").value("中度"))
                .andExpect(jsonPath("$.score").value(4.5));
        verify(llmService).diagnose2("医患对话");
    }

    @Test
    void repairShouldDelegateConversationToService() throws Exception {
        when(llmService.repair("我...水...")).thenReturn(Map.of("repairedConversation", "我想喝水。"));

        mvc.perform(post("/api/repair")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conversation\":\"我...水...\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.repairedConversation").value("我想喝水。"));
    }

    @Test
    void diagnose2ShouldRejectMissingConversation() throws Exception {
        // ConversationRequest.conversation 有 @NotBlank
        mvc.perform(post("/api/diagnose2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void diagnose2ShouldRejectBlankConversation() throws Exception {
        mvc.perform(post("/api/diagnose2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conversation\":\"   \"}"))
                .andExpect(status().is4xxClientError());
    }
}
