package com.blkn.lr.lr_new_server;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@Slf4j
@SpringBootApplication
@EnableCaching
public class LRNewApplication {
    public static void main(String[] args) {
        SpringApplication.run(LRNewApplication.class, args);
        log.info("run successfully");
//        System.out.println(System.getProperty("user.dir"));
    }
}




