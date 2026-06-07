package com.blkn.lr.lr_new_server.util;

import com.auth0.jwt.interfaces.DecodedJWT;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * TokenUtil 单元测试。
 *
 * <p>验证 JWT 自洽（签发的 token 自己能验回来）+ 异常路径返回 null（而非抛）—— 这是
 * 拦截器层依赖的契约：verifyToken 永不抛、不合法 token 一律 null，由上层决定 401。
 */
class TokenUtilTest {

    private final TokenUtil tokenUtil = TokenUtil.forSecret("unit-test-secret");

    @Test
    void getTokenShouldIncludeUidAndUTypeClaims() {
        String token = tokenUtil.getToken("user-123", 2);
        assertNotNull(token);

        DecodedJWT decoded = tokenUtil.verifyToken(token);
        assertNotNull(decoded);
        assertEquals("user-123", decoded.getClaim("uid").asString());
        assertEquals(2, decoded.getClaim("uType").asInt());
        assertEquals("aphasia", decoded.getIssuer());
    }

    @Test
    void verifyTokenShouldReturnNullForGarbageString() {
        // 不是合法 JWT 三段式 —— 走 JWTVerificationException 分支
        assertNull(tokenUtil.verifyToken("not.a.valid.jwt"));
    }

    @Test
    void verifyTokenShouldReturnNullForEmptyString() {
        assertNull(tokenUtil.verifyToken(""));
    }

    @Test
    void verifyTokenShouldReturnNullForNull() {
        // null 触发 catch-all（NPE 不是 JWTVerificationException）
        assertNull(tokenUtil.verifyToken(null));
    }

    @Test
    void verifyTokenShouldRejectTokenSignedByDifferentSecret() {
        // 另一个实例签的 token 用本实例不能验通过
        TokenUtil another = TokenUtil.forSecret("different-secret");
        String foreignToken = another.getToken("user-x", 1);

        assertNull(tokenUtil.verifyToken(foreignToken));
    }
}
