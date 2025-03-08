package com.blkn.lr.lr_new_server.util.zixing;


import com.blkn.lr.lr_new_server.util.zixing.Model.IZixingData;
import com.blkn.lr.lr_new_server.util.zixing.Model.ZixingSimilarDatas;
import com.blkn.lr.lr_new_server.util.zixing.calSimilar.CalSimilar;
import com.blkn.lr.lr_new_server.util.zixing.calSimilar.ICalSimilar;
import com.blkn.lr.lr_new_server.util.zixing.calSimilar.ZixingSimilars;
import com.blkn.lr.lr_new_server.util.zixing.constant.ZixingSimilarRateConst;
import com.blkn.lr.lr_new_server.util.zixing.context.IZixingSimilarContext;
import com.blkn.lr.lr_new_server.util.zixing.context.ZixingSimilarContext;
import com.github.houbb.heaven.support.instance.impl.Instances;


/**
 * @Author: jinyu
 * @Date: 2022/3/19 20:39
 */
public final class ZixingSimilar {
    public ZixingSimilar() {
    }
    public static ZixingSimilar newInstance() {
        return new ZixingSimilar();
    }
    /**
     * 笔画数占比
     */
    private double bihuashuRate = ZixingSimilarRateConst.BIAHUASHU;

    /**
     * 笔画数数据
     */
    private IZixingData<Integer> bihuashuData = ZixingSimilarDatas.bihuashu();

    /**
     * 笔画数相似度实现
     */
    private ICalSimilar bihuashuSimilar = ZixingSimilars.bihuashu();
    /**
     * 结构占比
     */
    private double jiegouRate = ZixingSimilarRateConst.JIEGOU;

    /**
     * 结构数据
     */
    private IZixingData<String> jiegouData = ZixingSimilarDatas.jiegou();

    /**
     * 结构相似度实现
     */
    private ICalSimilar jiegouSimilar = ZixingSimilars.jiegou();

    /**
     * 部首占比
     */
    private double bushouRate = ZixingSimilarRateConst.BUSHOU;

    /**
     * 部首数据
     */
    private IZixingData<String> bushouData = ZixingSimilarDatas.bushou();

    /**
     * 部首相似度实现
     */
    private ICalSimilar bushouSimilar = ZixingSimilars.bushou();
    /**
     * 四角编码占比
     */
    private double sijiaoRate = ZixingSimilarRateConst.SIJIAO;

    /**
     * 四角编码数据
     */
    private IZixingData<String> sijiaoData = ZixingSimilarDatas.sijiao();

    /**
     * 四角编码相似度实现
     */
    private ICalSimilar sijiaoSimilar = ZixingSimilars.sijiao();

    /**
     * 核心实现
     * @since 1.1.0
     */
    private ICalSimilar zixingSimilar = Instances.singleton(CalSimilar.class);



    /**
     * 相似度
     * @param one 第一个
     * @param two 第二个
     * @return 结果
     */
    public double similar(char one, char two) {
        IZixingSimilarContext context = buildContext(one, two);
        return zixingSimilar.similar(context);
    }

    private IZixingSimilarContext buildContext(char one, char two) {
        ZixingSimilarContext context = new ZixingSimilarContext();
        context.charOne(one+"")
                .charTwo(two+"")
                .bihuashuData(bihuashuData)
                .bihuashuSimilar(bihuashuSimilar)
                .bihuashuRate(bihuashuRate)
                .jiegouData(jiegouData)
                .jiegouRate(jiegouRate)
                .jiegouSimilar(jiegouSimilar)
                .bushouData(bushouData)
                .bushouSimilar(bushouSimilar)
                .bushouRate(bushouRate)
                .sijiaoData(sijiaoData)
                .sijiaoRate(sijiaoRate)
                .sijiaoSimilar(sijiaoSimilar);


        return context;
    }
}
