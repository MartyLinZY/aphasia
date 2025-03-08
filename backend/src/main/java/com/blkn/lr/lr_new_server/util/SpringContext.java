package com.blkn.lr.lr_new_server.util;

import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.context.annotation.Configuration;

//Solve the problem that the direct new object Spring will not be injected
@Configuration
public class SpringContext implements ApplicationContextAware{
	protected static ApplicationContext context;
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        context = applicationContext;
    }
    public static ApplicationContext getContext() {
        return context;
    }
}
