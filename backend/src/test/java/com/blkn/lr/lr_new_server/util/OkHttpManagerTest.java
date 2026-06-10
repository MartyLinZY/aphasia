package com.blkn.lr.lr_new_server.util;

import okhttp3.OkHttpClient;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Constructor;
import java.lang.reflect.Modifier;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * OkHttpManager 单元测试。
 *
 * <p>验证 ① InstanceHolder 懒加载单例（多次 getClient 返同一实例，省连接池）；
 * ② 超时配置正确（避免任何第三方端宕机时请求线程永久阻塞——这是当初引入此类的根因）。
 */
class OkHttpManagerTest {

    @Test
    void getClientShouldReturnSingleton() throws Exception {
        OkHttpClient first = invokePackagePrivateGetClient();
        OkHttpClient second = invokePackagePrivateGetClient();
        assertSame(first, second, "InstanceHolder 应是单例");
    }

    @Test
    void clientShouldHaveTimeoutsToPreventThreadLeak() throws Exception {
        OkHttpClient client = invokePackagePrivateGetClient();
        assertNotNull(client);
        // 全部三类超时都必须非零，否则第三方宕机/抖动时调用线程会永久阻塞
        assertEquals(TimeUnit.SECONDS.toMillis(10), client.connectTimeoutMillis());
        assertEquals(TimeUnit.SECONDS.toMillis(60), client.readTimeoutMillis());
        assertEquals(TimeUnit.SECONDS.toMillis(30), client.writeTimeoutMillis());
    }

    @Test
    void constructorShouldBePrivate() throws Exception {
        // 工具类禁止被实例化 —— 反射打开后能调用，但应是 private 修饰
        Constructor<OkHttpManager> ctor = OkHttpManager.class.getDeclaredConstructor();
        assertTrue(Modifier.isPrivate(ctor.getModifiers()),
                "OkHttpManager 是工具类，构造器必须 private");
        ctor.setAccessible(true);
        assertNotNull(ctor.newInstance());
    }

    private static OkHttpClient invokePackagePrivateGetClient() throws Exception {
        // getClient 是 package-private static —— 用反射跨包调用
        var method = OkHttpManager.class.getDeclaredMethod("getClient");
        method.setAccessible(true);
        return (OkHttpClient) method.invoke(null);
    }
}
