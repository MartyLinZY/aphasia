package com.blkn.lr.lr_new_server.util;

import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class ThreadPools {
    public static final ThreadPoolExecutor fluencyCalculator = new ThreadPoolExecutor(4, 8, 10, TimeUnit.MINUTES, new LinkedBlockingDeque<>());
}
