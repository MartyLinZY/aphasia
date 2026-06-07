package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.services.TranslationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class TranslationControllerTest {

    private MockMvc mvc;
    private TranslationService service;

    @BeforeEach
    void setUp() {
        service = mock(TranslationService.class);
        TranslationController controller = new TranslationController(service);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void translateShouldPassThroughText() throws Exception {
        when(service.translate("我要 水")).thenReturn("我要喝水。");

        mvc.perform(post("/api/translate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"我要 水\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.translatedText").value("我要喝水。"));
        verify(service).translate("我要 水");
    }

    @Test
    void translateShouldReturnEmptyStringWhenServiceReturnsNull() throws Exception {
        // Service 没配 apiKey 时会回退到原文（不会返 null），但 Controller 仍兜底 null→""
        when(service.translate("foo")).thenReturn(null);

        mvc.perform(post("/api/translate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"foo\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.translatedText").value(""));
    }

    @Test
    void translateShouldRejectMissingText() throws Exception {
        // TranslateRequest.text 有 @NotBlank（DtoValidationTest 已覆盖，这里再补一条最小重复以保留路由）
        mvc.perform(post("/api/translate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().is4xxClientError());
    }
}
