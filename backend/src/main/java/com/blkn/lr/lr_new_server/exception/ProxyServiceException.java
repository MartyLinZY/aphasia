package com.blkn.lr.lr_new_server.exception;

/**
 * /api/proxy/* 上游服务（讯飞 ASR/TTS、百度 OCR、Dashscope Qwen 等）调用失败时抛出。
 * 由 {@link GlobalExceptionHandler} 统一映射为 HTTP 502。
 */
public class ProxyServiceException extends Exception {
    public ProxyServiceException(String message) {
        super(message);
    }

    public ProxyServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}
