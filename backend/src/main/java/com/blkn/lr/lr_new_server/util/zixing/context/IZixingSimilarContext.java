package com.blkn.lr.lr_new_server.util.zixing.context;


import com.blkn.lr.lr_new_server.util.zixing.Model.IZixingData;
import com.blkn.lr.lr_new_server.util.zixing.calSimilar.ICalSimilar;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 20:56
 */
public interface IZixingSimilarContext {

    /**
     * 第一个汉字
     * @return 汉字
     */
    String charOne();

    /**
     * 第二个汉字
     * @return 汉字
     */
    String charTwo();

    /**
     * 笔画相似度
     * @return 相似度
     */
    ICalSimilar bihuashuSimilar();

    /**
     * 笔画数占比权重
     * @return 权重
     */
    double bihuashuRate();

    /**
     * 汉字结构相似度
     * @return 相似度
     */
    ICalSimilar jiegouSimilar();

    /**
     * 结构占比权重
     * @return 权重
     */
    double jiegouRate();

    /**
     * 汉字部首相似度
     * @return 相似度
     */
    ICalSimilar bushouSimilar();

    /**
     * 部首占比权重
     * @return 权重
     */
    double bushouRate();

    /**
     * 汉字四角编码相似度
     * @return 相似度
     */
    ICalSimilar sijiaoSimilar();

    /**
     * 四角编码占比权重
     * @return 权重
     */
    double sijiaoRate();


    /**
     * 笔画数 数据
     * @return 数据
     */
    IZixingData<Integer> bihuashuData();

    /**
     * 结构 数据
     * @return 数据
     */
    IZixingData<String> jiegouData();

    /**
     * 部首 数据
     * @return 数据
     */
    IZixingData<String> bushouData();

    /**
     * 四角编码 数据
     * @return 数据
     */
    IZixingData<String> sijiaoData();

}
