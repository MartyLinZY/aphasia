package com.blkn.lr.lr_new_server.interceptor;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.blkn.lr.lr_new_server.util.TokenUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.io.PrintWriter;

public class TokenInterceptor implements HandlerInterceptor {
	public final static String LOGIN_SYMBOL = "uid";

	// TODO: potential security problem, after login, the user has access to all url
	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
		String token = request.getHeader("Token");

		// Token checking - mobile
        //			HttpSession session = request.getSession();
        //			return session.getAttribute("uid") != null;
        if (token != null) {
			DecodedJWT decodedJWT = TokenUtil.verifyToken(token);
			if (decodedJWT != null) {
				// valid token => add the identity information into the request
				String uid = decodedJWT.getClaim("uid").asString();
				int uType = decodedJWT.getClaim("uType").asInt();
				request.setAttribute("uid", uid);
				request.setAttribute("uType", uType);

				// refresh token and put in header
				response.addHeader("Token", TokenUtil.getToken(uid, uType));
				return true;
			} else {
				// invalid token => return json with state = 0
				response.setCharacterEncoding("UTF-8");
				response.setContentType("application/json;charset=UTF-8");

				try (PrintWriter writer = response.getWriter()) {
					writer.print("{}");
				} catch (IOException e) {
					e.printStackTrace();
				}
				response.setStatus(403);
				return false;
			}
		} else return request.getMethod().equals("OPTIONS");
	}
}
