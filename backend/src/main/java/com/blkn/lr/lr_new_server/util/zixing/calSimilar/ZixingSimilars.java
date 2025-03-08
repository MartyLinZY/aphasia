package com.blkn.lr.lr_new_server.util.zixing.calSimilar;


import com.github.houbb.heaven.support.instance.impl.Instances;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 21:42
 */
public final class ZixingSimilars {
    public ZixingSimilars() {
    }
    /**
     * 笔画数
     * @return 实现
     */
    public static ICalSimilar bihuashu() {
        return Instances.singleton(BihuashuSimilar.class);
    }

    /**
     * 部首
     * @return 实现
     */
    public static ICalSimilar bushou() {
        return Instances.singleton(BushouSimilar.class);
    }

    /**
     * 结构
     * @return 实现
     */
    public static ICalSimilar jiegou() {
        return Instances.singleton(JiegouSimilar.class);
    }


    /**
     * 四角
     * @return 实现
     */
    public static ICalSimilar sijiao() {
        return Instances.singleton(SijiaoSimilar.class);
    }
}
