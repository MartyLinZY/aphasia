package com.blkn.lr.lr_new_server.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@Getter
public class AppSetting {
    // 用于拼接返回给前端的静态资源 URL（音频 / 图片）。
    // 部署时通过 APP_HOST 环境变量或 application.properties 覆盖 localhost。
    @Value("${app.host:localhost}")
    private String host;
}
