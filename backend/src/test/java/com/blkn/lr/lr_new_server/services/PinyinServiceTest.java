package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dto.apiproxy.PinyinMatchResult;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * PinyinService 单元测试。
 *
 * <p>覆盖矩阵：
 * <ul>
 *   <li>toPinyin：常见词、空串、纯英文、混合、多音字（取第一读音）</li>
 *   <li>similarity：相等、空、Levenshtein 边界</li>
 *   <li>match：失语症典型替换（声母混淆、声调错乱）、阈值边界、滑窗</li>
 * </ul>
 */
class PinyinServiceTest {

    private final PinyinService svc = new PinyinService();

    // ============================================================
    // toPinyin
    // ============================================================

    @Test
    void toPinyinShouldConvertCommonHanzi() {
        assertEquals("ni3hao3", svc.toPinyin("你好"));
        assertEquals("yi1sheng1", svc.toPinyin("医生"));
    }

    @Test
    void toPinyinShouldReturnEmptyForNullOrEmpty() {
        assertEquals("", svc.toPinyin(""));
        assertEquals("", svc.toPinyin(null));
    }

    @Test
    void toPinyinShouldKeepNonHanziAsIs() {
        assertEquals("abc 123", svc.toPinyin("abc 123"));
    }

    @Test
    void toPinyinShouldMixHanziAndAscii() {
        // 数字/空格原样保留，汉字转拼音
        assertEquals("ni3 1 hao3", svc.toPinyin("你 1 好"));
    }

    // ============================================================
    // similarity
    // ============================================================

    @Test
    void similarityShouldReturnOneForIdenticalStrings() {
        assertEquals(1.0, svc.similarity("yi1sheng1", "yi1sheng1"));
    }

    @Test
    void similarityShouldReturnOneForBothEmpty() {
        assertEquals(1.0, svc.similarity("", ""));
    }

    @Test
    void similarityShouldReturnZeroForCompletelyDifferent() {
        // 等长完全不同 → 距离=长度 → 相似度=0
        assertEquals(0.0, svc.similarity("abc", "xyz"));
    }

    @Test
    void similarityShouldHandleSingleEditDistance() {
        // "yi1" vs "yi2" → 1 edit / 3 chars → 0.667
        double sim = svc.similarity("yi1", "yi2");
        assertTrue(sim > 0.66 && sim < 0.68, "actual=" + sim);
    }

    // ============================================================
    // match —— 失语症典型场景
    // ============================================================

    @Test
    void matchShouldHitExactPinyin() {
        PinyinMatchResult r = svc.match("医生", "医生", 0.7);
        assertTrue(r.isMatched());
        assertEquals(1.0, r.getSimilarity());
        assertEquals("yi1sheng1", r.getExpectedPinyin());
    }

    @Test
    void matchShouldHitTonalVariation() {
        // 声调错（yi1 vs yi3）但声母韵母对 —— 失语症常见
        PinyinMatchResult r = svc.match("医生", "以省", 0.7);
        // yi1sheng1 vs yi3sheng3 → 2 edits / 9 chars ≈ 0.78
        assertTrue(r.isMatched(), "similarity=" + r.getSimilarity());
    }

    @Test
    void matchShouldRejectUnrelatedWords() {
        PinyinMatchResult r = svc.match("医生", "苹果", 0.7);
        assertFalse(r.isMatched());
    }

    @Test
    void matchShouldFindKeywordInLongerSpoken() {
        // 滑窗：关键词"医生"出现在长句子里应当命中
        PinyinMatchResult r = svc.match("医生", "我想要找医生看病", 0.7);
        assertTrue(r.isMatched(), "similarity=" + r.getSimilarity());
    }

    @Test
    void matchShouldReturnFalseWhenEitherSideBlank() {
        assertFalse(svc.match("", "yi sheng", 0.7).isMatched());
        assertFalse(svc.match("医生", "", 0.7).isMatched());
    }

    @Test
    void matchShouldHonorCustomThreshold() {
        // 比对一对相差较大的，0.9 阈值不过、0.3 阈值过
        PinyinMatchResult strict = svc.match("医生", "牙生", 0.9);
        PinyinMatchResult loose = svc.match("医生", "牙生", 0.3);
        assertFalse(strict.isMatched());
        assertTrue(loose.isMatched());
    }
}
