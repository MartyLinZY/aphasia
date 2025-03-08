package com.blkn.lr.lr_new_server.util;

import com.blkn.lr.lr_new_server.config.FlyTekApiConfig;
import com.blkn.lr.lr_new_server.config.StaticResourcesConfig;
import com.blkn.lr.lr_new_server.thirdparty.FlyTekAudioRecognizer;
import com.blkn.lr.lr_new_server.thirdparty.FlyTekAudioSynthesiser;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.WebSocket;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.FileNotFoundException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Future;

public class FlyTekManager {
    private static class InstanceHolder {
        static final FlyTekManager instance = new FlyTekManager();
    }

    private FlyTekManager() {}

    static public FlyTekManager getInstance() {
        return InstanceHolder.instance;
    }

    public Future<String> recognizeAudio(byte[] pcm16bitsData) throws Exception {
        String authedUrl = getAuthUrl(FlyTekApiConfig.audioRecognizeUrl, FlyTekApiConfig.apiKey, FlyTekApiConfig.clientSecrete);
        OkHttpClient client = OkHttpManager.getClient();
        Request request = new Request.Builder().url(authedUrl).build();
        CompletableFuture<String> future = new CompletableFuture<>();
        WebSocket webSocket = client.newWebSocket(request, new FlyTekAudioRecognizer(pcm16bitsData, future::complete));
        return future;
    }

    public Future<String> synthesisAudioFromText(String text, String uid, String serverPort) throws MalformedURLException, NoSuchAlgorithmException, InvalidKeyException, FileNotFoundException {
        String authedUrl = getAuthUrl(FlyTekApiConfig.audioSynthesisUrl, FlyTekApiConfig.apiKey, FlyTekApiConfig.clientSecrete);
        OkHttpClient client = OkHttpManager.getClient();
        Request request = new Request.Builder().url(authedUrl).build();
        CompletableFuture<String> future = new CompletableFuture<>();

        String fileName = (text.length() > 20 ? text.substring(0, 20) : text) + ".mp3";
        String destFilePath = StaticResourcesConfig.getAudioDirPath(uid) + fileName;
        String fileUrlPath = StaticResourcesConfig.getUrlPrefix(serverPort) + StaticResourcesConfig.getAudioUrlPath(uid, fileName);

        client.newWebSocket(request, new FlyTekAudioSynthesiser(FlyTekApiConfig.appId, text, destFilePath, () -> future.complete(fileUrlPath)));
        return future;
    }

    static String getAuthUrl(String hostUrl, String apiKey, String apiSecret) throws InvalidKeyException, NoSuchAlgorithmException, MalformedURLException {
        URL url = new URL(hostUrl);
        // 时间
        SimpleDateFormat format = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss z", Locale.US);
        format.setTimeZone(TimeZone.getTimeZone("GMT"));
        String date = format.format(new Date());
        // 拼接
        String preStr = "host: " + url.getHost() + "\n" +
                "date: " + date + "\n" +
                "GET " + url.getPath() + " HTTP/1.1";
        //System.out.println(preStr);
        // SHA256加密
        Mac mac = Mac.getInstance("hmacsha256");
        SecretKeySpec spec = new SecretKeySpec(apiSecret.getBytes(StandardCharsets.UTF_8), "hmacsha256");
        mac.init(spec);
        byte[] hexDigits = mac.doFinal(preStr.getBytes(StandardCharsets.UTF_8));
        // Base64加密
        String sha = Base64.getEncoder().encodeToString(hexDigits);
        // 拼接
        String authorization = String.format("api_key=\"%s\", algorithm=\"%s\", headers=\"%s\", signature=\"%s\"", apiKey, "hmac-sha256", "host date request-line", sha);
        // 拼接地址
        HttpUrl httpUrl = Objects.requireNonNull(HttpUrl.parse("https://" + url.getHost() + url.getPath())).newBuilder().//
                addQueryParameter("authorization", Base64.getEncoder().encodeToString(authorization.getBytes(StandardCharsets.UTF_8))).//
                addQueryParameter("date", date).//
                addQueryParameter("host", url.getHost()).//
                build();

        // 将包含鉴权token的url转换为ws/wss协议后返回
        return httpUrl.toString().replace("http://", "ws://").replace("https://", "wss://");
    }
}
