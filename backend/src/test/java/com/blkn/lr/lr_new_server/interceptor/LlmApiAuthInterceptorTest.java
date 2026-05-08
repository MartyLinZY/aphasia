package com.blkn.lr.lr_new_server.interceptor;

import com.blkn.lr.lr_new_server.controllers.LLMController;
import com.blkn.lr.lr_new_server.services.LLMService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class LlmApiAuthInterceptorTest {

    private MockMvc mockMvc;
    private LLMService llmService;

    @BeforeEach
    void setUp() {
        llmService = Mockito.mock(LLMService.class);
        LLMController controller = new LLMController();
        ReflectionTestUtils.setField(controller, "llmService", llmService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .addInterceptors(new TokenInterceptor())
                .build();
    }

    @Test
    void shouldReturn401WhenNoTokenForDiagnose1() throws Exception {
        mockMvc.perform(post("/api/diagnose1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conversation\":\"测试会话\"}"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(llmService);
    }

    @Test
    void shouldReturn403WhenInvalidTokenForDiagnose1() throws Exception {
        mockMvc.perform(post("/api/diagnose1")
                        .header("Token", "invalid-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conversation\":\"测试会话\"}"))
                .andExpect(status().isForbidden());

        verifyNoInteractions(llmService);
    }
}
