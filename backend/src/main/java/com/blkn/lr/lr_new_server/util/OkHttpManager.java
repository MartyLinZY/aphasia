package com.blkn.lr.lr_new_server.util;

import okhttp3.OkHttpClient;

public class OkHttpManager {
    private static class InstanceHolder {
        static final OkHttpClient HTTP_CLIENT = new OkHttpClient().newBuilder().build();
    }

    private OkHttpManager() {}

    static OkHttpClient getClient() {
        return InstanceHolder.HTTP_CLIENT;
    }
}
