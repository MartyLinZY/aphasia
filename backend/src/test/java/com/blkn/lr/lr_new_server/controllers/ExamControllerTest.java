package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionSubCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.services.ExamServices;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * ExamController 路由 + 路径参数绑定 + uid 属性提取 + 边界分支测试。
 *
 * <p>不重复 DtoValidationTest 已覆盖的 @Valid 400 路径。这里关心：
 * <ol>
 *   <li>每个 endpoint 路由能命中、PathVariable 正确解析、最终调到 Service 的对应方法；</li>
 *   <li>3 个 owner-check 分支（getExamsByDoctorId / getRecoveriesByDoctorId / 自己 uid != path uid 时抛 BusinessErrorException）；</li>
 *   <li>deleteExam 的零返回检查（Service 不抛但 Controller 抛）；</li>
 *   <li>uid 从 request attribute 提取——createExam / addQuestion / updateQuestion 都依赖。</li>
 * </ol>
 *
 * <p>standaloneSetup + mock Service：不加载 Spring context、不跑 RequireRole 拦截器（拦截器有自己的单元测试），
 * 也不跑 Token 校验。聚焦 Controller 自身代码路径。
 */
class ExamControllerTest {

    private MockMvc mvc;
    private ExamServices examServices;

    private static final String UID = "doctor-1";
    private static final String EXAM_ID = "e1";

    @BeforeEach
    void setUp() {
        examServices = mock(ExamServices.class);
        ExamController controller = new ExamController(examServices);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    // ============================================================
    // getExamById / getExamsByDoctorId / getRecoveriesByDoctorId
    // ============================================================

    @Test
    void getExamByIdShouldRouteAndReturnServiceResult() throws Exception {
        ExamDto dto = new ExamDto();
        dto.setName("套题A");
        when(examServices.getExamById(EXAM_ID)).thenReturn(dto);

        mvc.perform(get("/api/exams/" + EXAM_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("套题A"));
    }

    @Test
    void getExamsByDoctorIdShouldPassWhenUidMatches() throws Exception {
        when(examServices.getExamsByDoctorId(UID, false)).thenReturn(List.of());

        mvc.perform(get("/api/doctors/" + UID + "/exams").requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(examServices).getExamsByDoctorId(UID, false);
    }

    @Test
    void getExamsByDoctorIdShouldThrowWhenUidMismatch() throws Exception {
        mvc.perform(get("/api/doctors/other-doctor/exams").requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
        // 不该触达 Service
        verify(examServices, org.mockito.Mockito.never()).getExamsByDoctorId(any(), org.mockito.ArgumentMatchers.anyBoolean());
    }

    @Test
    void getRecoveriesByDoctorIdShouldPassRecoveryFlagTrueWhenUidMatches() throws Exception {
        when(examServices.getExamsByDoctorId(UID, true)).thenReturn(List.of());

        mvc.perform(get("/api/doctors/" + UID + "/recoveries").requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(examServices).getExamsByDoctorId(UID, true);
    }

    @Test
    void getRecoveriesByDoctorIdShouldThrowWhenUidMismatch() throws Exception {
        mvc.perform(get("/api/doctors/other/recoveries").requestAttr("uid", UID))
                .andExpect(status().is4xxClientError());
    }

    // ============================================================
    // createExam —— uid 属性提取
    // ============================================================

    @Test
    void createExamShouldExtractUidFromRequestAttribute() throws Exception {
        when(examServices.createExam(any(), eq(UID))).thenReturn(new ExamDto());

        mvc.perform(post("/api/exams")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"测评A\",\"categories\":[]}")
                        .requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(examServices).createExam(any(), eq(UID));
    }

    // ============================================================
    // updateExamName / updateExamDesc / publishExam —— PATCH 简单透传
    // ============================================================

    @Test
    void updateExamNameShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/name/newName123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.msg").value("ok"));
        verify(examServices).updateExamName(EXAM_ID, "newName123");
    }

    @Test
    void updateExamDescShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/desc/somedesc"))
                .andExpect(status().isOk());
        verify(examServices).updateExamDesc(EXAM_ID, "somedesc");
    }

    @Test
    void publishExamShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1"))
                .andExpect(status().isOk());
        verify(examServices).publishExam(EXAM_ID);
    }

    // ============================================================
    // deleteExam —— 零返回检查（Controller 抛而非 Service）
    // ============================================================

    @Test
    void deleteExamShouldReturnOkWhenServiceReturnsPositive() throws Exception {
        when(examServices.deleteExam(EXAM_ID)).thenReturn(1L);
        mvc.perform(delete("/api/exams/e1"))
                .andExpect(status().isOk());
    }

    @Test
    void deleteExamShouldThrowWhenServiceReturnsZero() throws Exception {
        // ExamServices.deleteExam 不抛异常，零返回由 Controller 兜底
        when(examServices.deleteExam(EXAM_ID)).thenReturn(0L);
        mvc.perform(delete("/api/exams/e1"))
                .andExpect(status().is4xxClientError());
    }

    // ============================================================
    // Category 路由
    // ============================================================

    @Test
    void addCategoryShouldRoute() throws Exception {
        when(examServices.addCategory(any(), eq(EXAM_ID))).thenReturn(new QuestionCategoryDto());

        mvc.perform(post("/api/exams/e1/category")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"description\":\"亚项A\",\"subCategories\":[]}"))
                .andExpect(status().isOk());
    }

    @Test
    void updateCategoryShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"description\":\"新名\",\"subCategories\":[]}"))
                .andExpect(status().isOk());
        verify(examServices).updateCategory(eq(EXAM_ID), eq(2), any());
    }

    @Test
    void deleteCategoryShouldRoute() throws Exception {
        mvc.perform(delete("/api/exams/e1/categories/3")).andExpect(status().isOk());
        verify(examServices).deleteCategory(EXAM_ID, 3);
    }

    @Test
    void moveCategoryUpShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/1/up")).andExpect(status().isOk());
        verify(examServices).moveCategoryUp(EXAM_ID, 1);
    }

    @Test
    void moveCategoryDownShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/1/down")).andExpect(status().isOk());
        verify(examServices).moveCategoryDown(EXAM_ID, 1);
    }

    // ============================================================
    // SubCategory 路由
    // ============================================================

    @Test
    void addSubCategoryShouldRoute() throws Exception {
        mvc.perform(post("/api/exams/e1/categories/0/subCategory")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"description\":\"S\",\"questions\":[]}"))
                .andExpect(status().isOk());
        verify(examServices).addSubCategoryIntoExam(eq(EXAM_ID), eq(0), any());
    }

    @Test
    void updateSubCategoryShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/subCategories/2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"description\":\"S\",\"questions\":[]}"))
                .andExpect(status().isOk());
        verify(examServices).updateSubCategory(eq(EXAM_ID), eq(0), eq(2), any());
    }

    @Test
    void deleteSubCategoryShouldRoute() throws Exception {
        mvc.perform(delete("/api/exams/e1/categories/0/subCategories/2")).andExpect(status().isOk());
        verify(examServices).deleteSubCategoryFromExam(EXAM_ID, 0, 2);
    }

    @Test
    void moveSubCategoryUpShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/subCategories/2/up")).andExpect(status().isOk());
        verify(examServices).moveSubCategoryUp(EXAM_ID, 0, 2);
    }

    @Test
    void moveSubCategoryDownShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/subCategories/2/down")).andExpect(status().isOk());
        verify(examServices).moveSubCategoryDown(EXAM_ID, 0, 2);
    }

    // ============================================================
    // Question 路由（含 uid 属性提取）
    // ============================================================

    @Test
    void addQuestionShouldExtractUidAndForwardToService() throws Exception {
        when(examServices.addQuestion(eq(UID), eq(EXAM_ID), anyInt(), anyInt(), any())).thenReturn(new QuestionDto());

        mvc.perform(post("/api/exams/e1/categories/0/subCategories/0/question")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"AudioQuestion\"}")
                        .requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(examServices).addQuestion(eq(UID), eq(EXAM_ID), eq(0), eq(0), any());
    }

    @Test
    void updateQuestionShouldExtractUidAndForwardToService() throws Exception {
        when(examServices.updateQuestion(any(), eq(UID))).thenReturn(new QuestionDto());

        mvc.perform(patch("/api/questions/q-7")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"AudioQuestion\"}")
                        .requestAttr("uid", UID))
                .andExpect(status().isOk());
        verify(examServices).updateQuestion(any(), eq(UID));
    }

    @Test
    void deleteQuestionShouldRoute() throws Exception {
        mvc.perform(delete("/api/exams/e1/categories/0/subCategories/0/questions/3")).andExpect(status().isOk());
        verify(examServices).deleteQuestion(EXAM_ID, 0, 0, 3);
    }

    @Test
    void moveQuestionUpShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/subCategories/0/questions/3/up")).andExpect(status().isOk());
        verify(examServices).moveQuestionUp(EXAM_ID, 0, 0, 3);
    }

    @Test
    void moveQuestionDownShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/subCategories/0/questions/3/down")).andExpect(status().isOk());
        verify(examServices).moveQuestionDown(EXAM_ID, 0, 0, 3);
    }

    // ============================================================
    // DiagnoseRule 路由
    // ============================================================

    @Test
    void addDiagnoseRuleShouldRoute() throws Exception {
        mvc.perform(post("/api/exams/e1/diagnosisRule")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"RangeRule\"}"))
                .andExpect(status().isOk());
        verify(examServices).addDiagnoseRule(eq(EXAM_ID), any());
    }

    @Test
    void updateDiagnoseRuleShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/diagnosisRules/2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"RangeRule\"}"))
                .andExpect(status().isOk());
        verify(examServices).updateDiagnoseRule(eq(EXAM_ID), eq(2), any());
    }

    @Test
    void deleteDiagnoseRuleShouldRoute() throws Exception {
        mvc.perform(delete("/api/exams/e1/diagnosisRules/2")).andExpect(status().isOk());
        verify(examServices).deleteDiagnoseRule(EXAM_ID, 2);
    }

    // ============================================================
    // TerminateRule 路由
    // ============================================================

    @Test
    void addTerminateRuleShouldRoute() throws Exception {
        mvc.perform(post("/api/exams/e1/categories/0/subCategories/0/terminateRule")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"ErrorCountRule\",\"errorCountThreshold\":3}"))
                .andExpect(status().isOk());
        verify(examServices).addTerminateRule(eq(EXAM_ID), eq(0), eq(0), any());
    }

    @Test
    void updateTerminateRuleShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/subCategories/0/terminateRules/2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"ErrorCountRule\"}"))
                .andExpect(status().isOk());
        verify(examServices).updateTerminateRule(eq(EXAM_ID), eq(0), eq(0), eq(2), any());
    }

    @Test
    void deleteTerminateRuleShouldRoute() throws Exception {
        mvc.perform(delete("/api/exams/e1/categories/0/subCategories/0/terminateRules/2")).andExpect(status().isOk());
        verify(examServices).deleteTerminateRule(EXAM_ID, 0, 0, 2);
    }

    // ============================================================
    // CategoryEvalRule 路由（类别级评分规则）
    // ============================================================

    @Test
    void addCategoryEvalRuleShouldRoute() throws Exception {
        mvc.perform(post("/api/exams/e1/categories/0/evalRule")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"ExamEvalByCategoryScoreSum\"}"))
                .andExpect(status().isOk());
        verify(examServices).addCategoryEvalRule(eq(EXAM_ID), eq(0), any());
    }

    @Test
    void updateCategoryEvalRuleShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/evalRules/2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"ExamEvalByCategoryScoreSum\"}"))
                .andExpect(status().isOk());
        verify(examServices).updateCategoryEvalRule(eq(EXAM_ID), eq(0), eq(2), any());
    }

    @Test
    void deleteCategoryEvalRuleShouldRoute() throws Exception {
        mvc.perform(delete("/api/exams/e1/categories/0/evalRules/2")).andExpect(status().isOk());
        verify(examServices).deleteCategoryEvalRule(EXAM_ID, 0, 2);
    }

    // ============================================================
    // SubCategoryEvalRule 路由（子类别级评分规则）
    // ============================================================

    @Test
    void addSubCategoryEvalRuleShouldRoute() throws Exception {
        mvc.perform(post("/api/exams/e1/categories/0/subCategories/1/evalRule")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"EvalSubCategoryByQuestionScoreSum\"}"))
                .andExpect(status().isOk());
        verify(examServices).addSubCategoryEvalRule(eq(EXAM_ID), eq(0), eq(1), any());
    }

    @Test
    void updateSubCategoryEvalRuleShouldRoute() throws Exception {
        mvc.perform(patch("/api/exams/e1/categories/0/subCategories/1/evalRules/2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"EvalSubCategoryByQuestionScoreSum\"}"))
                .andExpect(status().isOk());
        verify(examServices).updateSubCategoryEvalRule(eq(EXAM_ID), eq(0), eq(1), eq(2), any());
    }

    @Test
    void deleteSubCategoryEvalRuleShouldRoute() throws Exception {
        mvc.perform(delete("/api/exams/e1/categories/0/subCategories/1/evalRules/2")).andExpect(status().isOk());
        verify(examServices).deleteSubCategoryEvalRule(EXAM_ID, 0, 1, 2);
    }
}
