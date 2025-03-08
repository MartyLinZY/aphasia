package com.blkn.lr.lr_new_server.util.zixing.Model;

import com.blkn.lr.lr_new_server.util.zixing.constant.ZixingSimilarDataConst;
import com.github.houbb.heaven.util.io.StreamUtil;
import com.github.houbb.heaven.util.lang.StringUtil;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 21:17
 */
public class JiegouData implements IZixingData<String> {

    private static final Map<String, String> MAP;

    static {
        List<String> lines = StreamUtil.readAllLines(ZixingSimilarDataConst.JIEGOU);
        MAP = new HashMap<>(lines.size());

        for(String line : lines) {
            String[] strings = line.split(StringUtil.BLANK);
            MAP.put(strings[0], strings[1]);
        }
    }

    @Override
    public Map<String, String> dataMap() {
        return MAP;
    }

}
