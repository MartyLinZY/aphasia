package com.blkn.lr.lr_new_server.config;

public class FlyTekApiConfig {
    public static final String appId = "";
    public static final String clientSecrete = "";
    public static final String apiKey = "";

    /// 这里必须是http/https，否则URL()无法识别
    public static final String audioRecognizeUrl = "https://iat-api.xfyun.cn/v2/iat";
    public static final String audioSynthesisUrl = "https://tts-api.xfyun.cn/v2/tts";
}