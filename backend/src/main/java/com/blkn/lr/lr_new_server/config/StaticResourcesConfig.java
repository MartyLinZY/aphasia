package com.blkn.lr.lr_new_server.config;


import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;
import java.io.IOException;

@Configuration
public class StaticResourcesConfig implements WebMvcConfigurer {
    public static final String IMAGE_DIR = "images";
    public static final String AUDIO_DIR = "audio";

    static public String getImageUrlPath(String uid, String fileName) {
        return "/" + StaticResourcesConfig.IMAGE_DIR + "/" + uid + "/" + fileName;
    }

    static public String getImageDirPath(String uid) {
        String workingDir = System.getProperty("user.dir");
        return workingDir + File.separator + StaticResourcesConfig.IMAGE_DIR + File.separator + uid + File.separator;
    }

    static public String getAudioUrlPath(String uid, String fileName) {
        return "/" + StaticResourcesConfig.AUDIO_DIR + "/" + uid + "/" + fileName;
    }

    static public String getAudioDirPath(String uid) {
        String workingDir = System.getProperty("user.dir");
        return workingDir + File.separator + StaticResourcesConfig.AUDIO_DIR + File.separator + uid + File.separator;
    }

    static public String getUrlPrefix(String port) {
        return "http://" + AppSetting.HOSTNAME + ":" + port;
    }

//    public static final String RESOURCES_DIR = "resources";

//    public static final String IMAGE_PATH = "/images";
//    public static final String VIDEO_PATH = "/videos";
//    public static final String RESOURCES_PATH = "/resources";
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String workingDir = System.getProperty("user.dir");

        File imgDir = new File(workingDir + File.separator + IMAGE_DIR);
        File videoDir = new File(workingDir + File.separator + AUDIO_DIR);
//        File resourceDir = new File(workingDir + File.separator + RESOURCES_DIR);

        if (!imgDir.exists()) {
            imgDir.mkdirs();
        }

        if (!videoDir.exists()) {
            videoDir.mkdirs();
        }

//        if (!resourceDir.exists()) {
//            resourceDir.mkdirs();
//        }

        if (!registry.hasMappingForPattern("/" + IMAGE_DIR + "/**")) {
            try {
//                System.out.println(imgDir.getCanonicalPath());
                registry.addResourceHandler("/" + IMAGE_DIR + "/**")
                        .addResourceLocations("file:" + imgDir.getCanonicalPath() + File.separator);
            } catch (IOException e) {
                e.printStackTrace();
            }
        } else {
            System.err.println();
        }

        if (!registry.hasMappingForPattern("/" + AUDIO_DIR + "/**")) {
            try {
                registry.addResourceHandler("/" + AUDIO_DIR + "/**")
                        .addResourceLocations("file:" + videoDir.getCanonicalPath() + File.separator);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

//        if (!registry.hasMappingForPattern(RESOURCES_PATH +"/**")) {
//            try {
//                registry.addResourceHandler(RESOURCES_PATH +"/**")
//                        .addResourceLocations("file:" + resourceDir.getCanonicalPath() + File.separator);
//            } catch (IOException e) {
//                e.printStackTrace();
//            }
//        }
    }
}
