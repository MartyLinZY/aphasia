package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dao.impl.ExamResultDaoImpl;
import com.blkn.lr.lr_new_server.dao.impl.QuestionDaoImpl;
import com.blkn.lr.lr_new_server.dto.models.exam.ExamDto;
import com.blkn.lr.lr_new_server.dto.models.result.ExamResultDto;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Objects;

@RestController
@RequestMapping("/api")
public class ResultController {
    @Autowired
    ExamResultDaoImpl resultDao;

    @Autowired
    QuestionDaoImpl questionDao;

    @GetMapping("/patient/{uid}/examRecords")
    List<ExamResultDto> getExamResultsByUserId(@PathVariable("uid") String uid, HttpServletRequest request) {
        checkUid(request, uid);
        return resultDao.findByOwnerId(uid, false).stream().map(e -> new ExamResultDto(e, questionDao)).toList();
    }

    @GetMapping("/patient/{uid}/recoveryRecords")
    List<ExamResultDto> getRecoveryResultsByUserId(@PathVariable("uid") String uid, HttpServletRequest request) {
        checkUid(request, uid);
        return resultDao.findByOwnerId(uid, true).stream().map(e -> new ExamResultDto(e, questionDao)).toList();
    }

    @PostMapping("/examRecord")
    ExamResultDto saveResult(@RequestBody ExamResultDto resultDto, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        ExamResult updated = resultDao.save(resultDto.toModel(uid));
        if (updated == null) {
            throw new BusinessErrorException("保存id为" + resultDto.getId() + "的作答结果失败");
        }

        return new ExamResultDto(updated, questionDao);
    }

    void checkUid(HttpServletRequest request, String uid1) {
        String uid = (String) request.getAttribute("uid");

        if (!Objects.equals(uid, uid1)) {
            throw new BusinessErrorException("用户" + uid + "尝试操作" + uid1 + "用户的历史记录");
        }
    }

    @DeleteMapping("/examRecord/{recordId}")
    Map<String, String> deleteResult(@PathVariable String recordId, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");
       resultDao.deleteByIdWithOwnerId(uid, recordId);

        return Map.of("msg", "ok");
    }
}
