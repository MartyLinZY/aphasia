package com.blkn.lr.lr_new_server.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class StaticResourcesConfigTest {

    @Test
    void getImageUrlPath() {
        String testUrl = StaticResourcesConfig.getImageUrlPath("<uid>", "testFile");
        System.out.println(testUrl);
//        assertEquals(testUrl, "http://");
    }
}