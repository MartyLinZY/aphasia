package com.blkn.lr.lr_new_server.config;

import org.springframework.boot.web.context.WebServerInitializedEvent;
import org.springframework.context.ApplicationListener;

public class ServerEnvironmentAware implements ApplicationListener<WebServerInitializedEvent> {
    public static int port;
    @Override
    public void onApplicationEvent(WebServerInitializedEvent event) {
        port = event.getWebServer().getPort();
    }
}
