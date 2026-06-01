package com.blkn.lr.lr_new_server.mapper;

import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionCategoryDto;
import com.blkn.lr.lr_new_server.dto.models.exam.QuestionSubCategoryDto;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.question.Question;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class ExamMapper {
    private final QuestionDao questionDao;
    private final QuestionMapper questionMapper;

    public ExamDto toDto(Exam exam) {
        // 单次批量拉取整个 exam 树引用的所有 question，避免逐题 findById 造成的 N+1
        Map<String, Question> questionMap = prefetchQuestions(exam);

        ExamDto dto = new ExamDto();
        dto.setId(exam.getId());
        dto.setName(exam.getName());
        dto.setDescription(exam.getDescription());
        dto.setPublished(exam.isPublished());
        dto.setRecovery(exam.isRecovery());
        dto.setDisabled(exam.isDisabled());
        dto.setCategories(exam.getCategories().stream()
                .map(c -> categoryToDto(c, questionMap))
                .toList());
        dto.setDiagnosisRules(exam.getDiagnosisRules());
        dto.setRules(exam.getRules());
        return dto;
    }

    public Exam toModel(ExamDto dto, String ownerId) {
        Exam model = new Exam();
        if (dto.getId() != null) {
            model.setId(dto.getId());
        }
        model.setOwnerId(ownerId);
        model.setName(dto.getName());
        model.setDescription(dto.getDescription());
        model.setPublished(dto.isPublished());
        model.setRecovery(dto.isRecovery());
        model.setDisabled(dto.isDisabled());
        model.setCategories(dto.getCategories().stream().map(this::categoryToModel).toList());
        model.setDiagnosisRules(dto.getDiagnosisRules());
        model.setRules(dto.getRules());
        return model;
    }

    public QuestionCategory categoryToModel(QuestionCategoryDto dto) {
        QuestionCategory model = new QuestionCategory();
        model.setDescription(dto.getDescription());
        model.setSubCategories(dto.getSubCategories().stream().map(this::subCategoryToModel).toList());
        model.setRules(dto.getRules());
        return model;
    }

    public QuestionSubCategory subCategoryToModel(QuestionSubCategoryDto dto) {
        QuestionSubCategory model = new QuestionSubCategory();
        model.setDescription(dto.getDescription());
        model.setQuestions(dto.getQuestions().stream().map(q -> q.getId()).toList());
        model.setTerminateRules(dto.getTerminateRules());
        model.setEvalRules(dto.getEvalRules());
        return model;
    }

    private Map<String, Question> prefetchQuestions(Exam exam) {
        var ids = exam.getCategories().stream()
                .flatMap(c -> c.getSubCategories().stream())
                .flatMap(s -> s.getQuestions().stream())
                .toList();
        return questionDao.findAllByIds(ids).stream()
                .collect(Collectors.toMap(Question::getId, Function.identity()));
    }

    private QuestionCategoryDto categoryToDto(QuestionCategory category, Map<String, Question> questionMap) {
        QuestionCategoryDto dto = new QuestionCategoryDto();
        dto.setDescription(category.getDescription());
        dto.setSubCategories(category.getSubCategories().stream()
                .map(s -> subCategoryToDto(s, questionMap))
                .toList());
        dto.setRules(category.getRules());
        return dto;
    }

    private QuestionSubCategoryDto subCategoryToDto(QuestionSubCategory subCategory, Map<String, Question> questionMap) {
        QuestionSubCategoryDto dto = new QuestionSubCategoryDto();
        dto.setDescription(subCategory.getDescription());
        dto.setQuestions(subCategory.getQuestions().stream()
                .map(id -> questionMapper.toDto(questionMap.get(id)))
                .toList());
        dto.setTerminateRules(subCategory.getTerminateRules());
        dto.setEvalRules(subCategory.getEvalRules());
        return dto;
    }
}
