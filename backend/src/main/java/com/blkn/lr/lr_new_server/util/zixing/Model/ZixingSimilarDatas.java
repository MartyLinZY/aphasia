package com.blkn.lr.lr_new_server.util.zixing.Model;


import com.github.houbb.heaven.support.instance.impl.Instances;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 20:56
 */
public  final class ZixingSimilarDatas {
    public ZixingSimilarDatas() {
    }
    /**
     * 笔画数
     * @return 实现
     */
    public static IZixingData<Integer> bihuashu() {
        return Instances.singleton(BihuashuData.class);
    }

    /**
     * 部首
     * @return 实现
     */
    public static IZixingData<String> bushou() {
        return Instances.singleton(BushouData.class);
    }

    /**
     * 结构
     * @return 实现
     */
    public static IZixingData<String> jiegou() {
        return Instances.singleton(JiegouData.class);
    }

    /**
     * 四角
     * @return 实现
     */
    public static IZixingData<String> sijiao() {
        return Instances.singleton(SijiaoData.class);
    }
}
