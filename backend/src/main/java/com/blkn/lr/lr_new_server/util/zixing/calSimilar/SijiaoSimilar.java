package com.blkn.lr.lr_new_server.util.zixing.calSimilar;


import com.blkn.lr.lr_new_server.util.zixing.context.IZixingSimilarContext;

/**
 * 四角编码 相似度
 *
 */
public class SijiaoSimilar implements ICalSimilar {

    @Override
    public double similar(IZixingSimilarContext similarContext) {
        String charOne = similarContext.charOne();
        String charTwo = similarContext.charTwo();

        String codeOne = similarContext.sijiaoData().dataMap().get(charOne);
        String codeTwo = similarContext.sijiaoData().dataMap().get(charTwo);
        if(codeOne != null && codeTwo != null) {
            double score = calcScore(codeOne, codeTwo);

            return score * similarContext.sijiaoRate();
        }
        return 0;
    }

    /**
     * 分数编码
     * @param codeOne 编码1
     * @param codeTwo 编码2
     * @return 结果
     */
    private double calcScore(String codeOne, String codeTwo) {
        if(codeOne.length() == codeTwo.length()) {
            int len = codeOne.length();
            if(len <= 0) {
               return 0;
            }

            int total = 0;
            for(int i = 0; i < len; i++) {
                if(codeOne.charAt(i) == codeTwo.charAt(i)) {
                    total++;
                }
            }

            // 结果正则化
            return (total*1.0) / (len * 1.0);
        }

        return 0;
    }

}
