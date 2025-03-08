package com.blkn.lr.lr_new_server.util.zixing.Model;

/**
 * @Author: jinyu
 * @Date: 2022/3/19 21:03
 */

import com.blkn.lr.lr_new_server.util.zixing.constant.ZixingSimilarDataConst;
import com.github.houbb.heaven.util.io.StreamUtil;
import com.github.houbb.heaven.util.lang.StringUtil;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 笔画数数据
 * @author binbin.hou
 * @since 1.0.0
 */
public class BihuashuData implements IZixingData<Integer> {

    private static final Map<String, Integer> MAP;

    static {
        List<String> lines = StreamUtil.readAllLines(ZixingSimilarDataConst.BIAHUASHU);
        MAP = new HashMap<>(lines.size());

        for(String line : lines) {
            String[] strings = line.split(StringUtil.BLANK);
            MAP.put(strings[0], Integer.valueOf(strings[1]));
        }
    }

    @Override
    public Map<String, Integer> dataMap() {
        return MAP;
    }

}

