package com.blkn.lr.lr_new_server.util.zixing.context;


import com.blkn.lr.lr_new_server.util.zixing.Model.IZixingData;
import com.blkn.lr.lr_new_server.util.zixing.calSimilar.ICalSimilar;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 22:00
 */
public  class ZixingSimilarContext implements  IZixingSimilarContext {
    /**
     * 字符 1
     */
    private String charOne;

    /**
     * 字符 2
     */
    private String charTwo;


    /**
     * 笔画数占比
     */
    private double bihuashuRate;

    /**
     * 笔画数数据
     */
    private IZixingData<Integer> bihuashuData;

    /**
     * 笔画数相似度实现
     */
    private ICalSimilar bihuashuSimilar;

    /**
     * 结构占比
     */
    private double jiegouRate;

    /**
     * 结构数据
     */
    private IZixingData<String> jiegouData;

    /**
     * 结构相似度实现
     */
    private ICalSimilar jiegouSimilar;

    /**
     * 部首占比
     */
    private double bushouRate;

    /**
     * 部首数据
     */
    private IZixingData<String> bushouData;

    /**
     * 部首相似度实现
     */
    private ICalSimilar bushouSimilar;

    /**
     * 四角编码占比
     */
    private double sijiaoRate;

    /**
     * 四角编码数据
     */
    private IZixingData<String> sijiaoData;

    /**
     * 四角编码相似度实现
     */
    private ICalSimilar sijiaoSimilar;

    @Override
    public String charOne() {
        return charOne;
    }

    public ZixingSimilarContext charOne(String charOne) {
        this.charOne = charOne;
        return this;
    }

    @Override
    public String charTwo() {
        return charTwo;
    }

    public ZixingSimilarContext charTwo(String charTwo) {
        this.charTwo = charTwo;
        return this;
    }


    @Override
    public double bihuashuRate() {
        return bihuashuRate;
    }

    public ZixingSimilarContext bihuashuRate(double bihuashuRate) {
        this.bihuashuRate = bihuashuRate;
        return this;
    }

    @Override
    public IZixingData<Integer> bihuashuData() {
        return bihuashuData;
    }

    public ZixingSimilarContext bihuashuData(IZixingData<Integer> bihuashuData) {
        this.bihuashuData = bihuashuData;
        return this;
    }

    @Override
    public ICalSimilar bihuashuSimilar() {
        return bihuashuSimilar;
    }

    public ZixingSimilarContext bihuashuSimilar(ICalSimilar bihuashuSimilar) {
        this.bihuashuSimilar = bihuashuSimilar;
        return this;
    }

    @Override
    public double jiegouRate() {
        return jiegouRate;
    }

    public ZixingSimilarContext jiegouRate(double jiegouRate) {
        this.jiegouRate = jiegouRate;
        return this;
    }

    @Override
    public IZixingData<String> jiegouData() {
        return jiegouData;
    }

    public ZixingSimilarContext jiegouData(IZixingData<String> jiegouData) {
        this.jiegouData = jiegouData;
        return this;
    }

    @Override
    public ICalSimilar jiegouSimilar() {
        return jiegouSimilar;
    }

    public ZixingSimilarContext jiegouSimilar(ICalSimilar jiegouSimilar) {
        this.jiegouSimilar = jiegouSimilar;
        return this;
    }

    @Override
    public double bushouRate() {
        return bushouRate;
    }

    public ZixingSimilarContext bushouRate(double bushouRate) {
        this.bushouRate = bushouRate;
        return this;
    }

    @Override
    public IZixingData<String> bushouData() {
        return bushouData;
    }

    public ZixingSimilarContext bushouData(IZixingData<String> bushouData) {
        this.bushouData = bushouData;
        return this;
    }

    @Override
    public ICalSimilar bushouSimilar() {
        return bushouSimilar;
    }

    public ZixingSimilarContext bushouSimilar(ICalSimilar bushouSimilar) {
        this.bushouSimilar = bushouSimilar;
        return this;
    }

    @Override
    public double sijiaoRate() {
        return sijiaoRate;
    }

    public ZixingSimilarContext sijiaoRate(double sijiaoRate) {
        this.sijiaoRate = sijiaoRate;
        return this;
    }

    @Override
    public IZixingData<String> sijiaoData() {
        return sijiaoData;
    }

    public ZixingSimilarContext sijiaoData(IZixingData<String> sijiaoData) {
        this.sijiaoData = sijiaoData;
        return this;
    }

    @Override
    public ICalSimilar sijiaoSimilar() {
        return sijiaoSimilar;
    }

    public ZixingSimilarContext sijiaoSimilar(ICalSimilar sijiaoSimilar) {
        this.sijiaoSimilar = sijiaoSimilar;
        return this;
    }








}
