package com.blkn.lr.lr_new_server.util.zixing.Model;

import java.util.Map;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 21:01
 */
public interface IZixingData<T> {
    /**
     * 返回数据信息
     * @return 结果
     */
    Map<String, T> dataMap();
}
