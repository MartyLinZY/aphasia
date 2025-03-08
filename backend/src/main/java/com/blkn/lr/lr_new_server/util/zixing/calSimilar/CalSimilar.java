package com.blkn.lr.lr_new_server.util.zixing.calSimilar;


import com.blkn.lr.lr_new_server.util.zixing.context.IZixingSimilarContext;

/**
 * 汉字相似度算法核心实现
 * @Author: jinyu
 * @Date: 2022/3/19 21:50
 */
public class CalSimilar implements ICalSimilar {
    @Override
    public double similar(IZixingSimilarContext context) {
        final String charOne = context.charOne();
        final String charTwo = context.charTwo();

        //1. 是否相同
        if(charOne.equals(charTwo)) {
            return 1.0;
        }


        //2. 通过权重计算获取
        //2.1 四角编码
        ICalSimilar sijiaoSimilar = context.sijiaoSimilar();
        double sijiaoScore = sijiaoSimilar.similar(context);

        //2.2 结构
        ICalSimilar jiegouSimilar = context.jiegouSimilar();
        double jiegouScore = jiegouSimilar.similar(context);

        //2.3 部首
        ICalSimilar bushouSimilar = context.bushouSimilar();
        double bushouScore = bushouSimilar.similar(context);

        //2.4 笔画
        ICalSimilar biahuashuSimilar = context.bihuashuSimilar();
        double bihuashuScore = biahuashuSimilar.similar(context);



        //4. 计算总分
        double totalScore = sijiaoScore
                + jiegouScore
                + bushouScore
                + bihuashuScore;

        //4.1 避免浮点数比较问题
        if(totalScore <= 0) {
            return 0;
        }

        //4.2 正则化
        double limitScore = context.sijiaoRate()
                + context.jiegouRate()
                + context.bushouRate()
                + context.bihuashuRate();

        return totalScore / limitScore;
    }
}
