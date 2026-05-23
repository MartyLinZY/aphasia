package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dao.ExamResultDao;
import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.question.QuestionDto;
import com.blkn.lr.lr_new_server.exception.GlobalExceptionHandler;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import com.blkn.lr.lr_new_server.services.ExamServices;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 验证大 DTO（Exam/Question/Result）的字段校验与嵌套级联校验（@Valid）。
 * 通过 standaloneSetup + mock service，校验失败的请求在进入方法体前即返回 400。
 */
class DtoValidationTest {

    private MockMvc examMvc;
    private MockMvc resultMvc;
    private ExamServices examServices;
    private ExamResultDao resultDao;

    @BeforeEach
    void setUp() {
        examServices = Mockito.mock(ExamServices.class);
        ExamController examController = new ExamController();
        ReflectionTestUtils.setField(examController, "examServices", examServices);
        examMvc = MockMvcBuilders.standaloneSetup(examController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        resultDao = Mockito.mock(ExamResultDao.class);
        ResultController resultController = new ResultController();
        ReflectionTestUtils.setField(resultController, "resultDao", resultDao);
        ReflectionTestUtils.setField(resultController, "questionDao", Mockito.mock(QuestionDao.class));
        resultMvc = MockMvcBuilders.standaloneSetup(resultController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    // ---------- createExam ----------

    @Test
    void createExamShouldRejectBlankName() throws Exception {
        examMvc.perform(post("/api/exams")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"   \",\"categories\":[]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createExamShouldRejectNullCategories() throws Exception {
        examMvc.perform(post("/api/exams")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"测评A\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createExamShouldRejectNestedCategoryWithNullSubCategories() throws Exception {
        // 级联校验：category 缺少 subCategories
        examMvc.perform(post("/api/exams")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"测评A\",\"categories\":[{\"description\":\"亚项\"}]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createExamShouldPassWithValidPayload() throws Exception {
        when(examServices.createExam(any(), any())).thenReturn(new ExamDto());
        examMvc.perform(post("/api/exams")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"测评A\",\"categories\":[]}"))
                .andExpect(status().isOk());
    }

    // ---------- addQuestion ----------

    private static final String ADD_Q = "/api/exams/e1/categories/0/subCategories/0/question";

    @Test
    void addQuestionShouldRejectBlankTypeName() throws Exception {
        examMvc.perform(post(ADD_Q)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"questionText\":\"看图说话\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void addQuestionShouldPassWithTypeName() throws Exception {
        when(examServices.addQuestion(any(), any(), anyInt(), anyInt(), any())).thenReturn(new QuestionDto());
        examMvc.perform(post(ADD_Q)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"typeName\":\"AudioQuestion\",\"questionText\":\"看图说话\"}"))
                .andExpect(status().isOk());
    }

    // ---------- saveResult ----------

    @Test
    void saveResultShouldRejectNullCategoryResults() throws Exception {
        resultMvc.perform(post("/api/examRecord")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"examName\":\"测评A\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void saveResultShouldPassWithEmptyCategoryResults() throws Exception {
        ExamResult saved = new ExamResult();
        saved.setCategoryResults(List.of());
        when(resultDao.save(any())).thenReturn(saved);

        resultMvc.perform(post("/api/examRecord")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"examName\":\"测评A\",\"categoryResults\":[]}"))
                .andExpect(status().isOk());
    }
}
