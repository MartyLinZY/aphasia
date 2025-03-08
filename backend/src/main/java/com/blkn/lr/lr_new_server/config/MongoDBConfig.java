package com.blkn.lr.lr_new_server.config;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.core.MongoTemplate;


@Configuration
public class MongoDBConfig {
    static final String DB_URL = "mongodb://localhost:27017";
    static final String DB_NAME = "LrNew";

    @Bean
    MongoClient mongoClient() {
        return MongoClients.create();
    }

    @Bean
    MongoTemplate mongoTemplate(MongoClient mongoClient) {
        return new MongoTemplate(mongoClient, DB_NAME);
    }
}
