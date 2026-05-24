package com.blkn.lr.lr_new_server.util;

import okhttp3.OkHttpClient;

import java.util.concurrent.TimeUnit;

public class OkHttpManager {
    // 共享给讯飞 WebSocket（ASR/TTS）与百度鉴权使用：必须有超时兜底，
    // 否则任何第三方端宕机 / 网络抖动会让请求线程永久阻塞。
    private static class InstanceHolder {
        static final OkHttpClient HTTP_CLIENT = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .build();
    }

    private OkHttpManager() {}

    static OkHttpClient getClient() {
        return InstanceHolder.HTTP_CLIENT;
    }
}
