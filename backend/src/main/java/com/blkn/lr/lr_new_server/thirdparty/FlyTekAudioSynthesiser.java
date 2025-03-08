package com.blkn.lr.lr_new_server.thirdparty;

import com.google.gson.Gson;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import org.jetbrains.annotations.NotNull;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

public class FlyTekAudioSynthesiser extends WebSocketListener {
    // 合成文本编码格式
    public static final String TTE = "UTF8"; // 小语种必须使用UNICODE编码作为值
    // 发音人参数。到控制台-我的应用-语音合成-添加试用或购买发音人，添加后即显示该发音人参数值，若试用未添加的发音人会报错11200
    public static final String VCN = "xiaoyan";

    private final Gson gson = new Gson();

    private String appId;

    private String text;

    private final Runnable onComplete;

    private OutputStream outputStream;
    private String destFilePath;


    public FlyTekAudioSynthesiser(String appId, String text, String destFilePath, Runnable onComplete) throws FileNotFoundException {
        this.appId = appId;
        this.onComplete = onComplete;
        this.destFilePath = destFilePath;
        this.outputStream = new FileOutputStream(destFilePath);
        this.text = text;
    }

    @Override
    public void onOpen(@NotNull WebSocket webSocket, @NotNull Response response) {
        super.onOpen(webSocket, response);
        System.out.println("ws建立连接成功，发送文本...");
        new Thread(()->{
            //连接成功，开始发送数据
            String requestJson = "{\n" +
                    "  \"common\": {\n" +
                    "    \"app_id\": \"" + appId + "\"\n" +
                    "  },\n" +
                    "  \"business\": {\n" +
                    "    \"aue\": \"lame\",\n" +
                    "    \"sfl\": 1,\n" +
                    "    \"tte\": \"" + TTE + "\",\n" +
                    "    \"ent\": \"intp65\",\n" +
                    "    \"vcn\": \"" + VCN + "\",\n" +
                    "    \"pitch\": 45,\n" +
                    "    \"speed\": 44\n" +
                    "  },\n" +
                    "  \"data\": {\n" +
                    "    \"status\": 2,\n" +
                    "    \"text\": \"" + Base64.getEncoder().encodeToString(text.getBytes(StandardCharsets.UTF_8)) + "\"\n" +
                    //"    \"text\": \"" + Base64.getEncoder().encodeToString(TEXT.getBytes("UTF-16LE")) + "\"\n" +
                    "  }\n" +
                    "}";
            webSocket.send(requestJson);
        }).start();
    }

    @Override
    public void onMessage(@NotNull WebSocket webSocket, @NotNull String text) {
        super.onMessage(webSocket, text);
        JsonParse myJsonParse = gson.fromJson(text, JsonParse.class);
        if (myJsonParse.code != 0) {
            System.out.println("发生错误，错误码为：" + myJsonParse.code);
            System.out.println("本次请求的sid为：" + myJsonParse.sid);
        }
        if (myJsonParse.data != null) {
            try {
                byte[] textBase64Decode = Base64.getDecoder().decode(myJsonParse.data.audio);
                outputStream.write(textBase64Decode);
                outputStream.flush();
            } catch (Exception e) {
                e.printStackTrace();
            }
            if (myJsonParse.data.status == 2) {
                try {
                    outputStream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                System.out.println("本次请求的sid==>" + myJsonParse.sid);
                System.out.println("合成成功，文件保存路径为==>" + destFilePath);
                onComplete.run();
                // 可以关闭连接，释放资源
                webSocket.close(1000, "");
            }
        }
    }

    @Override
    public void onFailure(WebSocket webSocket, Throwable t, Response response) {
        super.onFailure(webSocket, t, response);
        try {
            if (null != response) {
                int code = response.code();
                System.out.println("onFailure code:" + code);
                System.out.println("onFailure body:" + response.body().string());
                if (101 != code) {
                    System.out.println("connection failed");
                    System.exit(0);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    //返回的json结果拆解
    class JsonParse {
        int code;
        String sid;
        Data data;
    }

    class Data {
        int status;
        String audio;
    }
}
