package com.blkn.lr.lr_new_server.interceptor;

import com.blkn.lr.lr_new_server.util.TokenUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class RequireRoleInterceptorTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new DummyRoleController())
                .addInterceptors(new TokenInterceptor())
                .build();
    }

    @Test
    void shouldRejectPatientTokenForDoctorOnlyApi() throws Exception {
        String patientToken = TokenUtil.getToken("patient-uid", 1);

        mockMvc.perform(post("/api/test/role/doctor-only")
                        .header("Token", patientToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"hello\":\"world\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(403))
                .andExpect(jsonPath("$.message").value("权限不足"));
    }

    @Test
    void shouldAllowDoctorTokenForDoctorOnlyApi() throws Exception {
        String doctorToken = TokenUtil.getToken("doctor-uid", 2);

        mockMvc.perform(post("/api/test/role/doctor-only")
                        .header("Token", doctorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"hello\":\"world\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.msg").value("ok"));
    }

    @RestController
    @RequestMapping("/api/test/role")
    static class DummyRoleController {
        @PostMapping("/doctor-only")
        @RequireRole({2})
        Map<String, String> doctorOnly(@RequestBody Map<String, Object> body) {
            return Map.of("msg", "ok");
        }
    }
}
