package com.blkn.lr.lr_new_server.thirdparty;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import lombok.extern.slf4j.Slf4j;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import org.jetbrains.annotations.NotNull;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.function.Consumer;

@Slf4j
public class FlyTekAudioSynthesiser extends WebSocketListener {
    // 合成文本编码格式
    public static final String TTE = "UTF8"; // 小语种必须使用UNICODE编码作为值
    // 发音人参数。到控制台-我的应用-语音合成-添加试用或购买发音人，添加后即显示该发音人参数值，若试用未添加的发音人会报错11200
    public static final String VCN = "xiaoyan";

    private final Gson gson = new Gson();

    private String appId;

    private String text;

    private final Runnable onComplete;
    private final Consumer<Throwable> onError;

    private OutputStream outputStream;
    private String destFilePath;


    public FlyTekAudioSynthesiser(String appId, String text, String destFilePath,
                                  Runnable onComplete, Consumer<Throwable> onError) throws FileNotFoundException {
        this.appId = appId;
        this.onComplete = onComplete;
        this.onError = onError;
        this.destFilePath = destFilePath;
        this.outputStream = new FileOutputStream(destFilePath);
        this.text = text;
    }

    @Override
    public void onOpen(@NotNull WebSocket webSocket, @NotNull Response response) {
        super.onOpen(webSocket, response);
        log.info("ws 建立连接成功，发送文本...");
        new Thread(() -> {
            JsonObject common = new JsonObject();
            common.addProperty("app_id", appId);

            JsonObject business = new JsonObject();
            business.addProperty("aue", "lame");
            business.addProperty("sfl", 1);
            business.addProperty("tte", TTE);
            business.addProperty("ent", "intp65");
            business.addProperty("vcn", VCN);
            business.addProperty("pitch", 45);
            business.addProperty("speed", 44);

            JsonObject data = new JsonObject();
            data.addProperty("status", 2);
            data.addProperty("text",
                    Base64.getEncoder().encodeToString(text.getBytes(StandardCharsets.UTF_8)));

            JsonObject root = new JsonObject();
            root.add("common", common);
            root.add("business", business);
            root.add("data", data);

            webSocket.send(gson.toJson(root));
        }).start();
    }

    @Override
    public void onMessage(@NotNull WebSocket webSocket, @NotNull String text) {
        super.onMessage(webSocket, text);
        JsonParse myJsonParse = gson.fromJson(text, JsonParse.class);
        if (myJsonParse.code != 0) {
            log.error("讯飞合成错误，code={}, sid={}", myJsonParse.code, myJsonParse.sid);
            closeOutputQuietly();
            onError.accept(new IOException("讯飞合成错误 code=" + myJsonParse.code + " sid=" + myJsonParse.sid));
            webSocket.close(1000, "");
            return;
        }
        if (myJsonParse.data != null) {
            try {
                byte[] textBase64Decode = Base64.getDecoder().decode(myJsonParse.data.audio);
                outputStream.write(textBase64Decode);
                outputStream.flush();
            } catch (Exception e) {
                log.error("写入合成音频数据失败", e);
                closeOutputQuietly();
                onError.accept(e);
                webSocket.close(1000, "");
                return;
            }
            if (myJsonParse.data.status == 2) {
                closeOutputQuietly();
                log.info("合成成功，sid={}, 路径={}", myJsonParse.sid, destFilePath);
                onComplete.run();
                // 可以关闭连接，释放资源
                webSocket.close(1000, "");
            }
        }
    }

    @Override
    public void onFailure(WebSocket webSocket, Throwable t, Response response) {
        super.onFailure(webSocket, t, response);
        int code = -1;
        String body = "";
        if (null != response) {
            code = response.code();
            try {
                body = response.body() != null ? response.body().string() : "";
            } catch (IOException e) {
                log.warn("读取讯飞合成失败响应 body 出错", e);
            }
        }
        log.error("讯飞合成连接失败，code={}, body={}", code, body, t);
        closeOutputQuietly();
        onError.accept(t != null ? t : new IOException("讯飞合成连接失败 code=" + code));
    }

    private void closeOutputQuietly() {
        try {
            if (outputStream != null) {
                outputStream.close();
                outputStream = null;
            }
        } catch (IOException e) {
            log.warn("关闭音频输出流失败", e);
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
