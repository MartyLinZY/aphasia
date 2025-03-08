package com.blkn.lr.lr_new_server.util.zixing.calSimilar;


import com.blkn.lr.lr_new_server.util.zixing.context.IZixingSimilarContext;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 21:28
 */
public interface ICalSimilar {
    /**
     * 相似度
     * @param similarContext 上下文
     * @return 结果
     * @since 1.0.0
     */
    double similar(final IZixingSimilarContext similarContext);
}
