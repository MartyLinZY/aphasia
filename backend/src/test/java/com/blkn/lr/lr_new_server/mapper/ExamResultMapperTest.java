package com.blkn.lr.lr_new_server.mapper;

import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.dto.models.result.ExamResultDto;
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.results.CategoryResult;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import com.blkn.lr.lr_new_server.models.results.QuestionResult;
import com.blkn.lr.lr_new_server.models.results.SubCategoryResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Collection;
import java.util.LinkedList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ExamResultMapperTest {

    private QuestionDao questionDao;
    private ExamResultMapper examResultMapper;

    @BeforeEach
    void setUp() {
        questionDao = mock(QuestionDao.class);
        examResultMapper = new ExamResultMapper(questionDao, new QuestionMapper());
    }

    @Test
    void toDtoShouldBatchFetchAllQuestionsInOneCall() {
        Question q1 = question("q1", "题1");
        Question q2 = question("q2", "题2");
        when(questionDao.findAllByIds(any())).thenReturn(List.of(q1, q2));

        ExamResult result = resultWithQuestions(List.of("q1", "q2"));

        ExamResultDto dto = examResultMapper.toDto(result);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Collection<String>> captor = ArgumentCaptor.forClass(Collection.class);
        verify(questionDao, times(1)).findAllByIds(captor.capture());
        verify(questionDao, never()).findById(any());
        assertTrue(captor.getValue().containsAll(List.of("q1", "q2")));

        var qResults = dto.getCategoryResults().get(0).getSubResults().get(0).getQuestionResults();
        assertEquals("题1", qResults.get(0).getSourceQuestion().getQuestionText());
        assertEquals("题2", qResults.get(1).getSourceQuestion().getQuestionText());
    }

    @Test
    void toDtoShouldUsePlaceholderForMissingQuestions() {
        when(questionDao.findAllByIds(any())).thenReturn(List.of());

        ExamResult result = resultWithQuestions(List.of("q-deleted"));

        ExamResultDto dto = examResultMapper.toDto(result);

        var sourceDto = dto.getCategoryResults().get(0).getSubResults().get(0)
                .getQuestionResults().get(0).getSourceQuestion();
        assertEquals("原问题已删除", sourceDto.getAlias());
    }

    private Question question(String id, String text) {
        Question q = new Question();
        q.setId(id);
        q.setQuestionText(text);
        q.setTypeName("AudioQuestion");
        return q;
    }

    private ExamResult resultWithQuestions(List<String> questionIds) {
        ExamResult result = new ExamResult();
        result.setExamName("测试");

        LinkedList<QuestionResult> qrs = new LinkedList<>();
        for (String id : questionIds) {
            QuestionResult qr = new QuestionResult();
            qr.setSourceQuestion(id);
            qr.setTypeName("AudioQuestion");
            qrs.add(qr);
        }

        SubCategoryResult sub = new SubCategoryResult();
        sub.setName("子项");
        sub.setQuestionResults(qrs);

        CategoryResult cat = new CategoryResult();
        cat.setName("亚项");
        LinkedList<SubCategoryResult> subs = new LinkedList<>();
        subs.add(sub);
        cat.setSubResults(subs);

        LinkedList<CategoryResult> cats = new LinkedList<>();
        cats.add(cat);
        result.setCategoryResults(cats);
        return result;
    }
}
