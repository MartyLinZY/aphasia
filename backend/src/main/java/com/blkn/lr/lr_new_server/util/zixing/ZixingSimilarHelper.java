package com.blkn.lr.lr_new_server.util.zixing;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 20:35
 * 字形相似度检测方法类
 */
public final class ZixingSimilarHelper {
    public ZixingSimilarHelper() {
    }
    /**
     * 相似度
     * @param hanziOne 汉字一
     * @param hanziTwo 汉字二
     * @return 结果
     */
    public static double similar(char hanziOne, char hanziTwo) {
        return ZixingSimilar.newInstance().similar(hanziOne, hanziTwo);

    }
}
