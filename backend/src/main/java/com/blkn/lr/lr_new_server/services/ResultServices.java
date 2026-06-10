package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dao.ExamResultDao;
import com.blkn.lr.lr_new_server.dto.models.result.ExamResultDto;
import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.mapper.ExamResultMapper;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ResultServices {
    private final ExamResultDao resultDao;
    private final ExamResultMapper examResultMapper;

    public List<ExamResultDto> getResultsByUserId(String ownerId, boolean isRecovery) {
        return resultDao.findByOwnerId(ownerId, isRecovery).stream()
                .map(examResultMapper::toDto)
                .toList();
    }

    public ExamResultDto saveResult(ExamResultDto resultDto, String ownerId) {
        ExamResult updated = resultDao.save(examResultMapper.toModel(resultDto, ownerId));
        if (updated == null) {
            throw new BusinessErrorException("保存id为" + resultDto.getId() + "的作答结果失败");
        }
        return examResultMapper.toDto(updated);
    }

    public void deleteResult(String ownerId, String resultId) {
        resultDao.deleteByIdWithOwnerId(ownerId, resultId);
    }
}
