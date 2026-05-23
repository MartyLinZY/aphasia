package com.blkn.lr.lr_new_server.exception;

import com.blkn.lr.lr_new_server.controllers.AccountController;
import com.blkn.lr.lr_new_server.services.AccountServices;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GlobalExceptionHandlerTest {

    private MockMvc mockMvc;
    private AccountServices accountServices;

    @BeforeEach
    void setUp() {
        accountServices = Mockito.mock(AccountServices.class);
        AccountController accountController = new AccountController();
        ReflectionTestUtils.setField(accountController, "service", accountServices);

        mockMvc = MockMvcBuilders.standaloneSetup(accountController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void shouldReturnBusinessErrorResponseWhenBusinessExceptionThrown() throws Exception {
        when(accountServices.register(any())).thenThrow(new BusinessErrorException("用户已存在"));

        mockMvc.perform(post("/api/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identity\":\"doctor-1\",\"password\":\"pwd123\",\"role\":2}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("用户已存在"));
    }

    @Test
    void shouldReturnValidationErrorResponseWhenRegisterPayloadInvalid() throws Exception {
        mockMvc.perform(post("/api/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identity\":\"\",\"password\":\"\",\"role\":0}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").exists());

        verifyNoInteractions(accountServices);
    }
}
