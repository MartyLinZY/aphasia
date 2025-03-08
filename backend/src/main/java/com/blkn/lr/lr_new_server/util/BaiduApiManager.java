package com.blkn.lr.lr_new_server.util;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.blkn.lr.lr_new_server.config.BaiduApiConfig;
import com.blkn.lr.lr_new_server.expection.BaiduApiFailException;
import com.blkn.lr.lr_new_server.expection.BaiduAuthorizeFailException;
import com.blkn.lr.lr_new_server.thirdparty.BaiduHttpUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.jetbrains.annotations.Nullable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

@Component
public class BaiduApiManager {

    @Autowired
    private RestTemplate restTemplate;

    String accessToken;

    public void authorize() throws IOException {
        MediaType mediaType = MediaType.parse("application/json");
        RequestBody body = RequestBody.create("", mediaType);
        String url = BaiduApiConfig.authorizeUrl;
        String api_key = BaiduApiConfig.apiKey;
        String secret = BaiduApiConfig.clientSecrete;
        Request request = new Request.Builder()
                .url(url + "?grant_type=client_credentials&client_id=" + api_key + "&client_secret="+secret)
                .method("POST", body)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .build();
        try (Response response = OkHttpManager.getClient().newCall(request).execute()) {
            assert (response.body() != null);
            // TODO: 考虑换成gson
            ObjectMapper mapper = new ObjectMapper();
            Map<String, String> jsonObject = mapper.readValue(response.body().bytes(), HashMap.class);
            accessToken = jsonObject.get("access_token");
            if (accessToken == null) {
                throw new BaiduAuthorizeFailException();
            }
            System.out.println("百度api token获取成功");
//            System.out.println(accessToken);
        }
    }

    @Nullable
    private JSONObject requestService(String url, JSONObject param) {
        ResponseEntity<JSONObject> responseEntity=restTemplate.postForEntity(url +accessToken,param,JSONObject.class);
        if (responseEntity.getStatusCode().value() == 200){
            JSONObject result= responseEntity.getBody();
            if (result.getInteger("error_code") != null) {
                System.out.println("error_msg:" + result.getString("error_msg"));
            }
            return result;
        }
        return null;
    }

    @Nullable
    private JSONObject requestTextService(String text, String url) {
        try {
            checkAndSetToken();
        } catch (IOException e) {
            throw new RuntimeException("百度API鉴权失败", e);
        }

        JSONObject param=new JSONObject();
        param.put("text",text);
        return requestService(url, param);
    }

    public JSONObject verbalAnalysis(String text){
        String verbal_analysiz_url= BaiduApiConfig.lexerUrl + "&access_token=";
        return requestTextService(text, verbal_analysiz_url);
    }

    public JSONObject dnn(String text) {
        String dnn_url= BaiduApiConfig.dnnUrl + "&access_token=";
        return requestTextService(text, dnn_url);
    }

    public Double shortTextSimilarity(String text1, String text2) {
        try {
            checkAndSetToken();
        } catch (IOException e) {
            throw new RuntimeException("百度API鉴权失败", e);
        }

        String url = BaiduApiConfig.shortTextSimUrl + "&access_token=";
        JSONObject param=new JSONObject();
        param.put("text_1",text1);
        param.put("text_2",text2);

        JSONObject result = requestService(url, param);
        if (result != null) {
            return result.getDouble("score");
        } else {
            return null;
        }
    }

    public String handWriteRecognize(byte[] imageBytes) throws BaiduApiFailException {
        try {
            checkAndSetToken();
        } catch (IOException e) {
            throw new RuntimeException("百度API鉴权失败", e);
        }

        byte[] imageBase64 = Base64.getEncoder().encode(imageBytes);
        String imageBase64Str = new String(imageBase64);
        String imgParam = URLEncoder.encode(imageBase64Str, StandardCharsets.UTF_8);

        String param = "image=" + imgParam;

        String result;
        try {
            result = BaiduHttpUtil.post(BaiduApiConfig.handWriteRecognizeUrl, accessToken, param);
        } catch (Exception e) {
            throw new BaiduApiFailException("手写识别错误");
        }

        JSONObject resultObj = JSON.parseObject(result);

        JSONArray results;
        if (resultObj != null) {
           results = resultObj.getJSONArray("words_result");
        } else {
            return null;
        }

        StringBuilder builder = new StringBuilder();

        for (int i = 0;i < results.size();i++) {
            builder.append(results.getJSONObject(i).get("words"));
        }

        return builder.toString();
    }

    String addTokenToUrl(String url) {
        return url + "&access_token" + accessToken;
    }

    ReentrantLock lock = new ReentrantLock();
    void checkAndSetToken() throws IOException {
        lock.lock();
        if (accessToken == null) {
            authorize();
        }
        lock.unlock();
    }
}
