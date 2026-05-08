package com.blkn.lr.lr_new_server.interceptor;

import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Intercepter Configure include the black list and white list
 *
 */
@Configuration
public class InterceptorConfigurer implements WebMvcConfigurer {
	@Value("${app.cors.allowed-origins:http://localhost:3000}")
	private String allowedOrigins;

	@Value("${app.cors.allowed-methods:GET,POST,PUT,PATCH,DELETE,OPTIONS}")
	private String allowedMethods;

	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		HandlerInterceptor loginInterceptor = new TokenInterceptor();
		registry.addInterceptor(loginInterceptor)
			.addPathPatterns("/api/**")
			.excludePathPatterns("/api/auth")
			.excludePathPatterns("/api/register")
			.excludePathPatterns("/api/test/**")
		;
	}

	@Override
	public void addCorsMappings(CorsRegistry registry) {
		registry.addMapping("/**")
				.allowedOrigins(splitByComma(allowedOrigins))
				.allowedMethods(splitByComma(allowedMethods))
				.allowedHeaders("*");
	}

	private String[] splitByComma(String value) {
		return value.split("\\s*,\\s*");
	}
}
