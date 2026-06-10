package com.blkn.lr.lr_new_server.util;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Date;

@Slf4j
@Component
public class TokenUtil {
    private final Algorithm algorithm;

    public TokenUtil(@Value("${jwt.secret}") String secretValue) {
        this.algorithm = Algorithm.HMAC256(secretValue);
    }

    /** 仅供单元测试构造一个独立实例，避免 Spring 容器外调用静态方法时拿到 null algorithm。 */
    public static TokenUtil forSecret(String secret) {
        return new TokenUtil(secret);
    }

    public String getToken(String uid, int uType) {
        Date now = new Date();
        return JWT.create()
                .withIssuer("aphasia")
                .withIssuedAt(now)
                .withExpiresAt(new Date(now.getTime() + 7L * 24 * 60 * 60 * 1000L))
                .withClaim("uid", uid)
                .withClaim("uType", uType)
                .sign(algorithm);
    }

    public DecodedJWT verifyToken(String token) {
        try {
            JWTVerifier verifier = JWT.require(algorithm)
                    .withIssuer("aphasia")
                    .build();
            return verifier.verify(token);
        } catch (JWTVerificationException e) {
            log.error("Invalid token received: {}", e.getMessage());
        } catch (Exception e) {
            log.error("Token 校验异常", e);
        }
        return null;
    }
}
