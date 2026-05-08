package com.blkn.lr.lr_new_server.interceptor;

import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.expection.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.util.TokenUtil;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FullProcessFlowTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new FullProcessController())
                .setControllerAdvice(new GlobalExceptionHandler())
                .addInterceptors(new TokenInterceptor())
                .build();
    }

    @Test
    void shouldPassThroughFullFlowFromAuthToBusinessHandling() throws Exception {
        String patientToken = TokenUtil.getToken("patient-uid", 1);
        String doctorToken = TokenUtil.getToken("doctor-uid", 2);

        // 1) 无 token，先被鉴权拦截（401）
        executeDoctorAction(null, "{\"content\":\"hello\"}")
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        // 2) 患者 token 访问医生接口，被角色权限拦截（403）
        executeDoctorAction(patientToken, "{\"content\":\"hello\"}")
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(403))
                .andExpect(jsonPath("$.message").value("权限不足"));

        // 3) 医生 token 但参数非法，触发 @Valid + 全局异常处理（400）
        executeDoctorAction(doctorToken, "{\"content\":\"\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").exists());

        // 4) 医生 token + 业务异常，触发 BusinessErrorException 统一返回（400）
        executeDoctorAction(doctorToken, "{\"content\":\"biz-error\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("模拟业务异常"));

        // 5) 医生 token + 合法参数，正常执行（200）
        executeDoctorAction(doctorToken, "{\"content\":\"run-through\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.msg").value("ok"));
    }

    private ResultActions executeDoctorAction(String token, String body) throws Exception {
        var builder = post("/api/e2e/doctor-action")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body);
        if (token != null) {
            builder.header("Token", token);
        }
        return mockMvc.perform(builder);
    }

    @RestController
    @RequestMapping("/api/e2e")
    static class FullProcessController {
        @PostMapping("/doctor-action")
        @RequireRole({2})
        Map<String, String> doctorAction(@Valid @RequestBody FlowRequest request) {
            if ("biz-error".equals(request.getContent())) {
                throw new BusinessErrorException("模拟业务异常");
            }
            return Map.of("msg", "ok");
        }
    }

    static class FlowRequest {
        @NotBlank(message = "content不能为空")
        private String content;

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }
    }
}
