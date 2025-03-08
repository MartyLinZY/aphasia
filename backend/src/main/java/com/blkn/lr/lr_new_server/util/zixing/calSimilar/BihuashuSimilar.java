package com.blkn.lr.lr_new_server.util.zixing.calSimilar;


import com.blkn.lr.lr_new_server.util.zixing.context.IZixingSimilarContext;

/**
 * 笔画数相似度
 */
public class BihuashuSimilar implements ICalSimilar {

    @Override
    public double similar(IZixingSimilarContext similarContext) {
        String charOne = similarContext.charOne();
        String charTwo = similarContext.charTwo();

        Integer numberOne = similarContext.bihuashuData().dataMap().get(charOne);
        Integer numberTwo = similarContext.bihuashuData().dataMap().get(charTwo);
        if(numberOne != null && numberTwo != null) {
            // 笔画差的越多，则差异越大
            double weight = 1 - Math.abs((numberOne - numberTwo)*1.0 / Math.max(numberOne, numberTwo));

            return weight * similarContext.bihuashuRate();
        }
        return 0;
    }

}
