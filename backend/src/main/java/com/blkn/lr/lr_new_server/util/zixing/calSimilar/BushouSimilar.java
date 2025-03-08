package com.blkn.lr.lr_new_server.util.zixing.calSimilar;


import com.blkn.lr.lr_new_server.util.zixing.context.IZixingSimilarContext;

/**
 * 部首相似度
 *
 */
public class BushouSimilar implements ICalSimilar {

    @Override
    public double similar(IZixingSimilarContext similarContext) {
        String charOne = similarContext.charOne();
        String charTwo = similarContext.charTwo();

        String bushouOne = similarContext.bushouData().dataMap().get(charOne);
        String bushouTwo = similarContext.bushouData().dataMap().get(charTwo);
        if(bushouOne != null && bushouTwo != null) {
            if(bushouOne.equals(bushouTwo)) {
                return 1.0 * similarContext.bushouRate();
            }
        }
        return 0;
    }

}
