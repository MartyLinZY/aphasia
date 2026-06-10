package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.models.result.ExamResultDto;
import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.services.ResultServices;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Objects;

@RestController
@RequestMapping("/api")
@RequireRole({1})
@RequiredArgsConstructor
public class ResultController {
    private final ResultServices resultServices;

    @GetMapping("/patient/{uid}/examRecords")
    List<ExamResultDto> getExamResultsByUserId(@PathVariable("uid") String uid, HttpServletRequest request) {
        checkUid(request, uid);
        return resultServices.getResultsByUserId(uid, false);
    }

    @GetMapping("/patient/{uid}/recoveryRecords")
    List<ExamResultDto> getRecoveryResultsByUserId(@PathVariable("uid") String uid, HttpServletRequest request) {
        checkUid(request, uid);
        return resultServices.getResultsByUserId(uid, true);
    }

    @PostMapping("/examRecord")
    ExamResultDto saveResult(@Valid @RequestBody ExamResultDto resultDto, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");
        return resultServices.saveResult(resultDto, uid);
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
        resultServices.deleteResult(uid, recordId);

        return Map.of("msg", "ok");
    }
}
