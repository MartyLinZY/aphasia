package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dto.apiproxy.PinyinMatchResult;
import net.sourceforge.pinyin4j.PinyinHelper;
import net.sourceforge.pinyin4j.format.HanyuPinyinCaseType;
import net.sourceforge.pinyin4j.format.HanyuPinyinOutputFormat;
import net.sourceforge.pinyin4j.format.HanyuPinyinToneType;
import net.sourceforge.pinyin4j.format.HanyuPinyinVCharType;
import net.sourceforge.pinyin4j.format.exception.BadHanyuPinyinOutputFormatCombination;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;

/**
 * 失语症录音题"拼音模糊判分"：把关键词与患者语音文本各自转拼音（带声调数字），
 * 在患者拼音串上滑窗算 Levenshtein 归一化相似度，最高分 ≥ 阈值即视为命中。
 *
 * <p>多音字策略：
 * <ul>
 *   <li><b>keyword 侧</b>取所有读音的笛卡尔积——医生设"行"时可能意为 xing2 或 hang2，
 *       不能让 pinyin4j 默认首读音判错。关键词通常 1-3 字，组合数可控。</li>
 *   <li><b>spoken 侧</b>仍取首读音——讯飞 ASR 输出整句长文本，多音字组合会指数爆炸，
 *       且 ASR 已基于上下文挑读音，多音字误判概率低。</li>
 * </ul>
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
            sb.append(charPinyins(c)[0]);
        }
        return sb.toString();
    }

    /**
     * 把汉字串转所有可能拼音串（多音字笛卡尔积；非汉字原样保留）。
     * 如 "行人" → ["xing2ren2", "hang2ren2"]；纯单音字或空串返回 size=1。
     */
    public List<String> toAllPinyin(String text) {
        if (text == null || text.isEmpty()) return Collections.singletonList("");
        List<String> results = new ArrayList<>();
        results.add("");
        for (char c : text.toCharArray()) {
            String[] pys = charPinyins(c);
            List<String> next = new ArrayList<>(results.size() * pys.length);
            for (String prev : results) {
                for (String py : pys) {
                    next.add(prev + py);
                }
            }
            results = next;
        }
        return results;
    }

    /** 单字所有去重读音，至少返回长度 1（非汉字时返回字符本身）。 */
    private String[] charPinyins(char c) {
        try {
            String[] arr = PinyinHelper.toHanyuPinyinStringArray(c, FORMAT);
            if (arr == null || arr.length == 0) {
                return new String[]{String.valueOf(c)};
            }
            return new LinkedHashSet<>(java.util.Arrays.asList(arr)).toArray(new String[0]);
        } catch (BadHanyuPinyinOutputFormatCombination e) {
            return new String[]{String.valueOf(c)};
        }
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
     * 在 spoken 拼音串上滑窗找与 keyword 任一读音组合的最高相似度。
     * keyword 用 toAllPinyin 覆盖多音字；spoken 取首读音。expectedPinyin 返回命中
     * 最高相似度的那个 keyword 读音组合，便于前端 extraResults 排查误判。
     */
    public PinyinMatchResult match(String keyword, String spoken, double threshold) {
        List<String> keywordPys = toAllPinyin(keyword);
        String spokenPy = toPinyin(spoken);
        if (keywordPys.get(0).isEmpty() || spokenPy.isEmpty()) {
            return new PinyinMatchResult(false, 0d, keywordPys.get(0), spokenPy);
        }

        int sLen = spokenPy.length();
        double maxSim = 0.0;
        String bestKeywordPy = keywordPys.get(0);
        for (String kPy : keywordPys) {
            int kLen = kPy.length();
            double sim;
            if (sLen <= kLen + 2) {
                sim = similarity(kPy, spokenPy);
            } else {
                sim = 0.0;
                int minWin = Math.max(1, kLen - 2);
                int maxWin = kLen + 2;
                for (int winSize = minWin; winSize <= maxWin; winSize++) {
                    for (int i = 0; i + winSize <= sLen; i++) {
                        double s = similarity(kPy, spokenPy.substring(i, i + winSize));
                        if (s > sim) sim = s;
                    }
                }
            }
            if (sim > maxSim) {
                maxSim = sim;
                bestKeywordPy = kPy;
            }
        }
        return new PinyinMatchResult(maxSim >= threshold, maxSim, bestKeywordPy, spokenPy);
    }
}
