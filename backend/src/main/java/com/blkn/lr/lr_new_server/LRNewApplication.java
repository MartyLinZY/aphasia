package com.blkn.lr.lr_new_server;

import com.blkn.lr.lr_new_server.util.BaiduApiManager;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

import java.io.IOException;


@SpringBootApplication
@EnableCaching
public class LRNewApplication {
    public static void main(String[] args) {
        SpringApplication.run(LRNewApplication.class, args);

        System.out.println("run successfully");
//        System.out.println(System.getProperty("user.dir"));
    }
}




