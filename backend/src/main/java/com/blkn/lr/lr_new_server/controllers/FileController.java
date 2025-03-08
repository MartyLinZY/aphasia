package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.config.AppSetting;
import com.blkn.lr.lr_new_server.config.StaticResourcesConfig;
import com.blkn.lr.lr_new_server.dao.impl.FileDao;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.Objects;

@RestController
@RequestMapping("/api")
public class FileController {
    @Autowired
    private FileDao fileDao;

    @Autowired
    Environment environment;

    @PostMapping("/image")
    Map<String, String> uploadImages(@RequestParam("file") MultipartFile file, HttpServletRequest request) {
        return uploadFile(file, request);
    }

    @PostMapping("/audio")
    Map<String, String> uploadAudio(@RequestParam("file") MultipartFile file, HttpServletRequest request) {
        return uploadFile(file, request);
    }

    private Map<String, String> uploadFile(MultipartFile file, HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");

        String contentType = Objects.requireNonNull(file.getContentType());
        String accessUrl = StaticResourcesConfig.getUrlPrefix(environment.getProperty("server.port"));
        String fileName;
        if (contentType.contains("audio/")) {
            fileName = fileDao.createAudioFile(file, uid).getName();
            accessUrl += StaticResourcesConfig.getAudioUrlPath(uid, fileName);
        } else if (contentType.contains("image/")){
            fileName = fileDao.createImageFile(file, uid).getName();
            accessUrl += StaticResourcesConfig.getImageUrlPath(uid, fileName);
        } else {
            throw new BusinessErrorException("不支持的文件类型");
        }

        return Map.of("url", accessUrl, "name", fileName);
    }

    @GetMapping("/images")
    List<Map<String, String>> getAllImageInfo(HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");
        String urlPrefix = "http://" + AppSetting.HOSTNAME + ":" + environment.getProperty("server.port");

        return fileDao.getAllImageUrlPaths(uid).stream().map(e -> {
            String[] tokens = e.split("/");
            String fileName = tokens[tokens.length - 1];

            return Map.of("name", fileName, "url", urlPrefix + e);
        }).toList();
    }

    @GetMapping("/audios")
    List<Map<String, String>> getAllAudioInfo(HttpServletRequest request) {
        String uid = (String) request.getAttribute("uid");
        String urlPrefix = "http://" + AppSetting.HOSTNAME + ":" + environment.getProperty("server.port");

        return fileDao.getAllAudioUrlPaths(uid).stream().map(e -> {
            String[] tokens = e.split("/");
            String fileName = tokens[tokens.length - 1];

            return Map.of("name", fileName, "url", urlPrefix + e);
        }).toList();
    }
}
