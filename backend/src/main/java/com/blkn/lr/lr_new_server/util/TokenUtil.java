package com.blkn.lr.lr_new_server.util;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Date;

@Slf4j
@Component
public class TokenUtil {
    @Value("${jwt.secret}")
    private String secretValue;

    private static Algorithm algorithm;

    @PostConstruct
    public void init() {
        algorithm = Algorithm.HMAC256(secretValue);
    }

    /**
     *
     * @param uid
     * @return
     */
    public static String getToken(String uid, int uType) {
        Date now = new Date();
        return JWT.create()
                .withIssuer("aphasia")
                .withIssuedAt(now)
                .withExpiresAt(new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000L))
                .withClaim("uid", uid)
                .withClaim("uType", uType)
                // TODO: add a hashed password Claim
                .sign(algorithm);
    }

    /**
     *
     * @param token
     * @return
     */
    public static DecodedJWT verifyToken(String token) {
        try {
            JWTVerifier verifier = JWT.require(algorithm)
                    .withIssuer("aphasia")
                    .build();

            return verifier.verify(token);
        } catch (JWTVerificationException e) {
            log.error("Invalid token received: {}", e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
