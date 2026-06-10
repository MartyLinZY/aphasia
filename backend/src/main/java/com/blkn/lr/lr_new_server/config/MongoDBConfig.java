package com.blkn.lr.lr_new_server.config;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.core.MongoTemplate;


@Configuration
public class MongoDBConfig {
    // host/port 走配置：spring.data.mongodb.host 可由 MONGO_HOST 环境变量覆盖。
    // 默认 127.0.0.1 与原先硬编码的 localhost 行为一致；容器化时注入服务名 mongo。
    // 仍是无认证连接（与原 MongoClients.create() 默认行为相同）。
    @Value("${spring.data.mongodb.host:127.0.0.1}")
    private String host;
    @Value("${spring.data.mongodb.port:27017}")
    private int port;

    static final String DB_NAME = "LrNew";

    @Bean
    MongoClient mongoClient() {
        return MongoClients.create("mongodb://" + host + ":" + port);
    }

    @Bean
    MongoTemplate mongoTemplate(MongoClient mongoClient) {
        return new MongoTemplate(mongoClient, DB_NAME);
    }
}
