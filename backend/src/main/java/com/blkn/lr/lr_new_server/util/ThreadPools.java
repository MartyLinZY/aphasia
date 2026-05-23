package com.blkn.lr.lr_new_server.util;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class ThreadPools {
    private static final ThreadFactory FLUENCY_THREAD_FACTORY = new ThreadFactory() {
        private final AtomicInteger counter = new AtomicInteger(1);
        @Override
        public Thread newThread(Runnable r) {
            Thread t = new Thread(r, "fluency-calc-" + counter.getAndIncrement());
            t.setDaemon(false);
            return t;
        }
    };

    public static final ThreadPoolExecutor fluencyCalculator = new ThreadPoolExecutor(
            4, 8,
            60L, TimeUnit.SECONDS,
            new ArrayBlockingQueue<>(100),
            FLUENCY_THREAD_FACTORY,
            new ThreadPoolExecutor.CallerRunsPolicy());
}
