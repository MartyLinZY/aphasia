package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.config.StaticResourcesConfig;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.expection.FileIOException;
import org.jetbrains.annotations.NotNull;
import org.springframework.stereotype.Repository;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Repository
public class FileDao {

    private File saveToFile(String destPath, MultipartFile file) {
        File destFile = new File(destPath);
        if (destFile.exists() && !destFile.delete()) {
            throw new BusinessErrorException("文件已存在，且覆盖已有文件失败");
        }

        try {
            destFile.getParentFile().mkdirs();

            file.transferTo(destFile);
            return destFile;
        } catch (IOException e) {
            throw new FileIOException("保存文件至" + destPath +"失败", e);
        }
    }

    public File createImageFile(MultipartFile file, String uid) {
        return saveToFile(StaticResourcesConfig.getImageDirPath(uid) + file.getOriginalFilename(), file);
    }

    public File createAudioFile(MultipartFile file, String uid) {
        return saveToFile(StaticResourcesConfig.getAudioDirPath(uid) + file.getOriginalFilename(), file);
    }

    public List<String> getAllImageUrlPaths(String uid) {
        String dirPath = StaticResourcesConfig.getImageDirPath(uid);
        return getFileNames(dirPath).stream().map(e -> StaticResourcesConfig.getImageUrlPath(uid, e)).toList();
    }

    public List<String> getAllAudioUrlPaths(String uid) {
        String dirPath = StaticResourcesConfig.getAudioDirPath(uid);
        return getFileNames(dirPath).stream().map(e -> StaticResourcesConfig.getAudioUrlPath(uid, e)).toList();
    }

    @NotNull
    private List<String> getFileNames(String dirPath) {
        File dir = new File(dirPath);
        File[] files = dir.listFiles();

        List<String> fileNames = new ArrayList<>();
        for (File f : files) {
            fileNames.add(f.getName());
        }

        return fileNames;
    }
}
