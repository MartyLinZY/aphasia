package com.blkn.lr.lr_new_server.interceptor;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.blkn.lr.lr_new_server.util.TokenUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.method.HandlerMethod;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;

@Slf4j
public class TokenInterceptor implements HandlerInterceptor {
	public final static String LOGIN_SYMBOL = "uid";

	// TODO: potential security problem, after login, the user has access to all url
	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
		if (request.getMethod().equals("OPTIONS")) {
			return true;
		}

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

				if (!hasRequiredRole(handler, uType)) {
					writeJsonError(response, 403, "权限不足");
					return false;
				}

				// refresh token and put in header
				response.addHeader("Token", TokenUtil.getToken(uid, uType));
				return true;
			} else {
				// invalid token => return json with state = 0
				writeJsonError(response, 403, "无效Token");
				return false;
			}
		} else {
			writeJsonError(response, 401, "缺少Token");
			return false;
		}
	}

	private boolean hasRequiredRole(Object handler, int uType) {
		if (!(handler instanceof HandlerMethod handlerMethod)) {
			return true;
		}

		RequireRole requireRole = handlerMethod.getMethodAnnotation(RequireRole.class);
		if (requireRole == null) {
			requireRole = handlerMethod.getBeanType().getAnnotation(RequireRole.class);
		}

		if (requireRole == null) {
			return true;
		}

		return Arrays.stream(requireRole.value()).anyMatch(role -> role == uType);
	}

	private void writeJsonError(HttpServletResponse response, int status, String message) {
		response.setCharacterEncoding("UTF-8");
		response.setContentType("application/json;charset=UTF-8");
		response.setStatus(status);
		String body = "{\"code\":" + status + ",\"message\":\"" + message + "\",\"data\":null}";
		try (PrintWriter writer = response.getWriter()) {
			writer.print(body);
		} catch (IOException e) {
			log.error("写入错误响应失败", e);
		}
	}
}
