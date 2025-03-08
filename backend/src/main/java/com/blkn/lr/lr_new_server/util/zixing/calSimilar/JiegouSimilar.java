package com.blkn.lr.lr_new_server.util.zixing.calSimilar;


import com.blkn.lr.lr_new_server.util.zixing.context.IZixingSimilarContext;

/**
 * 结构相似度
 *
 */
public class JiegouSimilar implements ICalSimilar {

    @Override
    public double similar(IZixingSimilarContext similarContext) {
        String charOne = similarContext.charOne();
        String charTwo = similarContext.charTwo();

        String jiegouOne = similarContext.jiegouData().dataMap().get(charOne);
        String jiegouTwo = similarContext.jiegouData().dataMap().get(charTwo);
        if(jiegouOne != null && jiegouTwo != null) {
            // 结构也可以考虑近似度，不过意义不大
            Integer a = Integer.valueOf(jiegouOne);
            Integer b = Integer.valueOf(jiegouTwo);
            int s=a^b;
            int res=0;
            while(s!=0){
                res+=s&1;
                s>>=1;
            }
            return 1/(Math.pow(Math.E,res)) * similarContext.jiegouRate();

        }
        return 0;
    }

}
