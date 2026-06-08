package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dto.apiproxy.PinyinMatchResult;
import net.sourceforge.pinyin4j.PinyinHelper;
import net.sourceforge.pinyin4j.format.HanyuPinyinCaseType;
import net.sourceforge.pinyin4j.format.HanyuPinyinOutputFormat;
import net.sourceforge.pinyin4j.format.HanyuPinyinToneType;
import net.sourceforge.pinyin4j.format.HanyuPinyinVCharType;
import net.sourceforge.pinyin4j.format.exception.BadHanyuPinyinOutputFormatCombination;
import org.springframework.stereotype.Service;

/**
 * 失语症录音题"拼音模糊判分"：把关键词与患者语音文本各自转拼音（带声调数字），
 * 在患者拼音串上滑窗算 Levenshtein 归一化相似度，最高分 ≥ 阈值即视为命中。
 *
 * <p>多音字策略：取第一个读音（pinyin4j 默认）。这是 v1 折中——医生设关键词时
 * 通常已认定单一读音，讯飞 ASR 输出文本中多音字概率也低。
 */
@Service
public class PinyinService {

    private static final HanyuPinyinOutputFormat FORMAT = new HanyuPinyinOutputFormat();

    static {
        FORMAT.setToneType(HanyuPinyinToneType.WITH_TONE_NUMBER);
        FORMAT.setVCharType(HanyuPinyinVCharType.WITH_V);
        FORMAT.setCaseType(HanyuPinyinCaseType.LOWERCASE);
    }

    /** 把汉字串转拼音串（多音字取第一读音；非汉字原样保留；如 "你好" → "ni3hao3"）。 */
    public String toPinyin(String text) {
        if (text == null || text.isEmpty()) return "";
        StringBuilder sb = new StringBuilder();
        for (char c : text.toCharArray()) {
            try {
                String[] arr = PinyinHelper.toHanyuPinyinStringArray(c, FORMAT);
                if (arr == null || arr.length == 0) {
                    sb.append(c);
                } else {
                    sb.append(arr[0]);
                }
            } catch (BadHanyuPinyinOutputFormatCombination e) {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    /** 归一化 Levenshtein 相似度 ∈ [0, 1]；两串都空算 1。 */
    public double similarity(String a, String b) {
        if (a.isEmpty() && b.isEmpty()) return 1.0;
        int max = Math.max(a.length(), b.length());
        return 1.0 - (double) levenshtein(a, b) / max;
    }

    private int levenshtein(String a, String b) {
        int[][] dp = new int[a.length() + 1][b.length() + 1];
        for (int i = 0; i <= a.length(); i++) dp[i][0] = i;
        for (int j = 0; j <= b.length(); j++) dp[0][j] = j;
        for (int i = 1; i <= a.length(); i++) {
            for (int j = 1; j <= b.length(); j++) {
                int cost = a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1;
                dp[i][j] = Math.min(Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
                        dp[i - 1][j - 1] + cost);
            }
        }
        return dp[a.length()][b.length()];
    }

    /**
     * 在 spoken 拼音串上滑窗找与 keyword 拼音的最高相似度。
     * spoken 较短时整体比较；较长时窗口大小 = keyword 长度 ±2，扫所有位置取 max。
     */
    public PinyinMatchResult match(String keyword, String spoken, double threshold) {
        String keywordPy = toPinyin(keyword);
        String spokenPy = toPinyin(spoken);
        if (keywordPy.isEmpty() || spokenPy.isEmpty()) {
            return new PinyinMatchResult(false, 0d, keywordPy, spokenPy);
        }

        int kLen = keywordPy.length();
        int sLen = spokenPy.length();
        double maxSim;
        if (sLen <= kLen + 2) {
            maxSim = similarity(keywordPy, spokenPy);
        } else {
            maxSim = 0.0;
            int minWin = Math.max(1, kLen - 2);
            int maxWin = kLen + 2;
            for (int winSize = minWin; winSize <= maxWin; winSize++) {
                for (int i = 0; i + winSize <= sLen; i++) {
                    double sim = similarity(keywordPy, spokenPy.substring(i, i + winSize));
                    if (sim > maxSim) maxSim = sim;
                }
            }
        }
        return new PinyinMatchResult(maxSim >= threshold, maxSim, keywordPy, spokenPy);
    }
}
