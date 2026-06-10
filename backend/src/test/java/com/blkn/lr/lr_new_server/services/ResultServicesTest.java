package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dao.ExamResultDao;
import com.blkn.lr.lr_new_server.dto.models.result.ExamResultDto;
import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.mapper.ExamResultMapper;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * ResultServices 单元测试。
 *
 * <p>3 个方法都很薄：list/stream 映射 + 单条保存（null 抛业务异常） + 直传删除。
 * 4 个依赖（ExamResultDao / ExamResultMapper）全部 Mockito 桩。
 */
class ResultServicesTest {

    private static final String OWNER_ID = "patient-1";

    private ExamResultDao resultDao;
    private ExamResultMapper mapper;
    private ResultServices service;

    @BeforeEach
    void setUp() {
        resultDao = mock(ExamResultDao.class);
        mapper = mock(ExamResultMapper.class);
        service = new ResultServices(resultDao, mapper);
    }

    @Test
    void getResultsByUserIdShouldMapEachThroughMapper() {
        ExamResult r1 = new ExamResult();
        ExamResult r2 = new ExamResult();
        ExamResultDto d1 = new ExamResultDto();
        ExamResultDto d2 = new ExamResultDto();
        when(resultDao.findByOwnerId(OWNER_ID, false)).thenReturn(List.of(r1, r2));
        when(mapper.toDto(r1)).thenReturn(d1);
        when(mapper.toDto(r2)).thenReturn(d2);

        assertEquals(List.of(d1, d2), service.getResultsByUserId(OWNER_ID, false));
    }

    @Test
    void getResultsByUserIdShouldPassRecoveryFlagThrough() {
        when(resultDao.findByOwnerId(OWNER_ID, true)).thenReturn(List.of());
        assertEquals(0, service.getResultsByUserId(OWNER_ID, true).size());
        verify(resultDao).findByOwnerId(OWNER_ID, true);
    }

    @Test
    void saveResultHappyPathShouldReturnMappedDto() {
        ExamResultDto inputDto = new ExamResultDto();
        ExamResult toSave = new ExamResult();
        ExamResult saved = new ExamResult();
        ExamResultDto returnedDto = new ExamResultDto();

        when(mapper.toModel(inputDto, OWNER_ID)).thenReturn(toSave);
        when(resultDao.save(toSave)).thenReturn(saved);
        when(mapper.toDto(saved)).thenReturn(returnedDto);

        assertSame(returnedDto, service.saveResult(inputDto, OWNER_ID));
    }

    @Test
    void saveResultShouldThrowWhenDaoReturnsNull() {
        ExamResultDto inputDto = new ExamResultDto();
        inputDto.setId("res-99");
        when(mapper.toModel(any(), eq(OWNER_ID))).thenReturn(new ExamResult());
        when(resultDao.save(any())).thenReturn(null);

        BusinessErrorException e = assertThrows(BusinessErrorException.class,
                () -> service.saveResult(inputDto, OWNER_ID));
        assertEquals("保存id为res-99的作答结果失败", e.getMessage());
    }

    @Test
    void deleteResultShouldDelegateToDao() {
        service.deleteResult(OWNER_ID, "res-7");
        verify(resultDao).deleteByIdWithOwnerId(OWNER_ID, "res-7");
    }

    // 编译期 helper：避免引入 Mockito.eq import 污染上面 stub
    private static <T> T eq(T value) {
        return org.mockito.ArgumentMatchers.eq(value);
    }
}
