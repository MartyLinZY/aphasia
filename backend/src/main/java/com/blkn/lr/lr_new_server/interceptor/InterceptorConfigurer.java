package com.blkn.lr.lr_new_server.interceptor;

import org.springframework.context.annotation.Configuration;
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

	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		HandlerInterceptor loginInterceptor = new TokenInterceptor();
		registry.addInterceptor(loginInterceptor)
			.addPathPatterns("/api/**")
			.excludePathPatterns("/api/auth")
			.excludePathPatterns("/api/register")
			.excludePathPatterns("/api/test/**")
			.excludePathPatterns("/api/diagnose1")
			.excludePathPatterns("/api/diagnose2")
			.excludePathPatterns("/api/repair")
		;
	}

	@Override
	public void addCorsMappings(CorsRegistry registry) {
		// the CORS setting is only for developing
		// TODO: Comment this in production mode since the frontend will be put together with the backend
		registry.addMapping("/**")
				.allowedOrigins("*") // this only for developing
				.allowedMethods("*");
//				.allowCredentials(true);
//                .exposedHeaders("failType");
	}
}
