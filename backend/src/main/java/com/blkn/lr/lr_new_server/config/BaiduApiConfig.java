package com.blkn.lr.lr_new_server.config;

public class BaiduApiConfig {
    // 百度云开放平台api相关
    public static final String authorizeUrl = "https://aip.baidubce.com/oauth/2.0/token";
    public static final String appId = "";
    public static final String clientSecrete = "";
    public static final String apiKey = "";

    public static final String lexerUrl = "https://aip.baidubce.com/rpc/2.0/nlp/v1/lexer?charset=UTF-8";
    public static final String dnnUrl = "https://aip.baidubce.com/rpc/2.0/nlp/v2/dnnlm_cn?charset=UTF-8";
    public static final String shortTextSimUrl = "https://aip.baidubce.com/rpc/2.0/nlp/v2/simnet?charset=UTF-8";
    public static final String handWriteRecognizeUrl = "https://aip.baidubce.com/rest/2.0/ocr/v1/handwriting";
}
