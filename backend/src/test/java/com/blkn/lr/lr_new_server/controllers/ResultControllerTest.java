package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.models.result.ExamResultDto;
import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.services.ResultServices;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * ResultController 路由 + uid owner-check 测试。
 * 4 个 endpoint，关键关注 checkUid 在 list/recovery 上的拒访路径。
 */
class ResultControllerTest {

    private MockMvc mvc;
    private ResultServices service;
    private static final String UID = "patient-1";

    @BeforeEach
    void setUp() {
        service = mock(ResultServices.class);
        ResultController controller = new ResultController(service);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void getExamResultsShouldPassWhenUidMatches() throws Exception {
        when(service.getResultsByUserId(UID, false)).thenReturn(List.of());

        mvc.perform(get("/api/patient/" + UID + "/examRecords").requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(service).getResultsByUserId(UID, false);
    }

    @Test
    void getExamResultsShouldThrowWhenUidMismatch() throws Exception {
        mvc.perform(get("/api/patient/other-patient/examRecords").requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
        verify(service, never()).getResultsByUserId(any(), org.mockito.ArgumentMatchers.anyBoolean());
    }

    @Test
    void getRecoveryResultsShouldPassRecoveryTrueWhenUidMatches() throws Exception {
        when(service.getResultsByUserId(UID, true)).thenReturn(List.of());

        mvc.perform(get("/api/patient/" + UID + "/recoveryRecords").requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(service).getResultsByUserId(UID, true);
    }

    @Test
    void getRecoveryResultsShouldThrowWhenUidMismatch() throws Exception {
        mvc.perform(get("/api/patient/other/recoveryRecords").requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void saveResultShouldExtractUidAndForwardToService() throws Exception {
        ExamResultDto saved = new ExamResultDto();
        saved.setCategoryResults(List.of());
        when(service.saveResult(any(), eq(UID))).thenReturn(saved);

        mvc.perform(post("/api/examRecord")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"examName\":\"t\",\"categoryResults\":[]}")
                        .requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(service).saveResult(any(), eq(UID));
    }

    @Test
    void deleteResultShouldExtractUidAndForwardToService() throws Exception {
        mvc.perform(delete("/api/examRecord/rec-9").requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(service).deleteResult(UID, "rec-9");
    }
}
