package com.blkn.lr.lr_new_server.mapper;

import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.dto.models.result.CategoryResultDto;
import com.blkn.lr.lr_new_server.dto.models.result.ExamResultDto;
import com.blkn.lr.lr_new_server.dto.models.result.QuestionResultDto;
import com.blkn.lr.lr_new_server.dto.models.result.SubCategoryResultDto;
import com.blkn.lr.lr_new_server.models.results.CategoryResult;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import com.blkn.lr.lr_new_server.models.results.QuestionResult;
import com.blkn.lr.lr_new_server.models.results.SubCategoryResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ExamResultMapper {
    private final QuestionDao questionDao;
    private final QuestionMapper questionMapper;

    public ExamResultDto toDto(ExamResult examResult) {
        ExamResultDto dto = new ExamResultDto();
        dto.setId(examResult.getId());
        dto.setResultText(examResult.getResultText());
        dto.setFinalScore(examResult.getFinalScore());
        dto.setStartTime(examResult.getStartTime());
        dto.setFinishTime(examResult.getFinishTime());
        dto.setIsRecovery(examResult.getIsRecovery());
        dto.setIsDisabled(examResult.getIsDisabled());
        dto.setExamName(examResult.getExamName());
        dto.setCategoryResults(examResult.getCategoryResults().stream()
                .map(this::categoryResultToDto)
                .toList());
        return dto;
    }

    public ExamResult toModel(ExamResultDto dto, String ownerId) {
        ExamResult model = new ExamResult();
        model.setId(dto.getId());
        model.setOwnerId(ownerId);
        model.setResultText(dto.getResultText());
        model.setFinalScore(dto.getFinalScore());
        model.setStartTime(dto.getStartTime());
        model.setFinishTime(dto.getFinishTime());
        model.setIsRecovery(dto.getIsRecovery());
        model.setIsDisabled(dto.getIsDisabled());
        model.setExamName(dto.getExamName());
        model.setCategoryResults(dto.getCategoryResults().stream()
                .map(this::categoryResultToModel)
                .toList());
        return model;
    }

    public CategoryResultDto categoryResultToDto(CategoryResult cr) {
        CategoryResultDto dto = new CategoryResultDto();
        dto.setName(cr.getName());
        dto.setFinalScore(cr.getFinalScore());
        dto.setSubResults(cr.getSubResults().stream().map(this::subCategoryResultToDto).toList());
        return dto;
    }

    public CategoryResult categoryResultToModel(CategoryResultDto dto) {
        CategoryResult model = new CategoryResult();
        model.setName(dto.getName());
        model.setFinalScore(dto.getFinalScore());
        model.setSubResults(dto.getSubResults().stream().map(this::subCategoryResultToModel).toList());
        return model;
    }

    public SubCategoryResultDto subCategoryResultToDto(SubCategoryResult sr) {
        SubCategoryResultDto dto = new SubCategoryResultDto();
        dto.setName(sr.getName());
        dto.setFinalScore(sr.getFinalScore());
        dto.setTerminateReason(sr.getTerminateReason());
        dto.setQuestionResults(sr.getQuestionResults().stream()
                .map(this::questionResultToDto)
                .toList());
        return dto;
    }

    public SubCategoryResult subCategoryResultToModel(SubCategoryResultDto dto) {
        SubCategoryResult model = new SubCategoryResult();
        model.setName(dto.getName());
        model.setFinalScore(dto.getFinalScore());
        model.setTerminateReason(dto.getTerminateReason());
        model.setQuestionResults(dto.getQuestionResults().stream()
                .map(this::questionResultToModel)
                .toList());
        return model;
    }

    public QuestionResultDto questionResultToDto(QuestionResult qr) {
        QuestionResultDto dto = new QuestionResultDto();
        dto.setSourceQuestion(questionMapper.toDto(questionDao.findById(qr.getSourceQuestion())));
        dto.setFinalScore(qr.getFinalScore());
        dto.setAnswerTime(qr.getAnswerTime());
        dto.setIsHinted(qr.getIsHinted());
        dto.setExtraResults(qr.getExtraResults());
        dto.setTypeName(qr.getTypeName());
        return dto;
    }

    public QuestionResult questionResultToModel(QuestionResultDto dto) {
        QuestionResult model = new QuestionResult();
        model.setSourceQuestion(dto.getSourceQuestion().getId());
        model.setFinalScore(dto.getFinalScore());
        model.setAnswerTime(dto.getAnswerTime());
        model.setIsHinted(dto.getIsHinted());
        model.setExtraResults(dto.getExtraResults());
        model.setTypeName(dto.getTypeName());
        return model;
    }
}
