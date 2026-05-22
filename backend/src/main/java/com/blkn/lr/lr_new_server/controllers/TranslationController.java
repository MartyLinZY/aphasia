package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.request.TranslateRequest;
import com.blkn.lr.lr_new_server.interceptor.RequireRole;
import com.blkn.lr.lr_new_server.services.TranslationService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
@RequireRole({1, 2})
public class TranslationController {

    @Autowired
    private TranslationService translationService;

    /**
     * 对文本进行补全/猜测含义并翻译，适用于失语症患者不完整表达。
     *
     * @param req 请求体，包含 "text" 字段
     * @return 响应体，包含 "translatedText" 字段
     */
    @PostMapping("/translate")
    public Map<String, String> translate(@Valid @RequestBody TranslateRequest req) {
        String translated = translationService.translate(req.getText());
        return Map.of("translatedText", translated != null ? translated : "");
    }
}
