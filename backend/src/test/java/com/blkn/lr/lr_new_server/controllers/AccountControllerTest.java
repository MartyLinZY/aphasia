package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.common.UserDto;
import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.services.AccountServices;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * AccountController 路由测试。
 * <p>login: 关心从 header（Token / identity / password）正确读取并传给 Service。
 * register: 关心 @Valid body 透传到 Service。
 */
class AccountControllerTest {

    private MockMvc mvc;
    private AccountServices service;

    @BeforeEach
    void setUp() {
        service = mock(AccountServices.class);
        AccountController controller = new AccountController(service);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void loginShouldReadAllThreeHeadersAndForwardToService() throws Exception {
        when(service.login(eq("tok"), eq("alice"), eq("pwd"))).thenReturn(new UserDto());

        mvc.perform(post("/api/auth")
                        .header("Token", "tok")
                        .header("identity", "alice")
                        .header("password", "pwd"))
                .andExpect(status().isOk());

        verify(service).login("tok", "alice", "pwd");
    }

    @Test
    void loginShouldPassNullsWhenHeadersMissing() throws Exception {
        when(service.login(null, null, null)).thenReturn(new UserDto());

        mvc.perform(post("/api/auth")).andExpect(status().isOk());
        verify(service).login(null, null, null);
    }

    @Test
    void registerShouldForwardBodyToService() throws Exception {
        when(service.register(any())).thenReturn(new UserDto());

        mvc.perform(post("/api/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identity\":\"bob\",\"password\":\"pwd\",\"role\":1}"))
                .andExpect(status().isOk());

        verify(service).register(any());
    }
}
