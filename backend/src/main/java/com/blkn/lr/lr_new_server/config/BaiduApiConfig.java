package com.blkn.lr.lr_new_server.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class BaiduApiConfig {
    // 百度云开放平台api相关
    private static final String AUTHORIZE_URL = "https://aip.baidubce.com/oauth/2.0/token";
    private static final String LEXER_URL = "https://aip.baidubce.com/rpc/2.0/nlp/v1/lexer?charset=UTF-8";
    private static final String DNN_URL = "https://aip.baidubce.com/rpc/2.0/nlp/v2/dnnlm_cn?charset=UTF-8";
    private static final String SHORT_TEXT_SIM_URL = "https://aip.baidubce.com/rpc/2.0/nlp/v2/simnet?charset=UTF-8";
    private static final String HAND_WRITE_RECOGNIZE_URL = "https://aip.baidubce.com/rest/2.0/ocr/v1/handwriting";

    @Value("${baidu.api.app-id:}")
    private String appId;

    @Value("${baidu.api.client-secret:}")
    private String clientSecret;

    @Value("${baidu.api.key:}")
    private String apiKey;

    public String getAuthorizeUrl() {
        return AUTHORIZE_URL;
    }

    public String getLexerUrl() {
        return LEXER_URL;
    }

    public String getDnnUrl() {
        return DNN_URL;
    }

    public String getShortTextSimUrl() {
        return SHORT_TEXT_SIM_URL;
    }

    public String getHandWriteRecognizeUrl() {
        return HAND_WRITE_RECOGNIZE_URL;
    }

    public String getAppId() {
        return appId;
    }

    public String getClientSecret() {
        return clientSecret;
    }

    public String getApiKey() {
        return apiKey;
    }
}
