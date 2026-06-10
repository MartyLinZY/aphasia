"""特征诊断的离线回归测试：聚合逻辑(纯函数) + 语料缓存上的分类 AUC。

不调 API：diagnose() 用 monkeypatch 桩掉 extract_features；AUC 读 features_cache.json。
锁住 P2/P3 验证过的行为，防止改权重/阈值/prompt 时把判别力改坏。
"""
import json
import os
from itertools import product

import pytest

import features
from features import (APHASIA_THRESHOLD, FEATURE_WEIGHTS, FEATURES, diagnose,
                      severity_score)

CACHE = os.path.join(os.path.dirname(__file__), "features_cache.json")


def _vec(*lit):
    """构造特征向量：传入点亮的特征名，其余为 0。"""
    return {k: (1 if k in lit else 0) for k in FEATURES}


def test_severity_score_is_weighted_sum():
    assert severity_score(_vec("短而简化")) == round(FEATURE_WEIGHTS["短而简化"], 2)
    assert severity_score(_vec()) == 0.0
    full = severity_score({k: 1 for k in FEATURES})
    assert full == round(sum(FEATURE_WEIGHTS.values()), 2)


def test_diagnose_clear_patient(monkeypatch):
    """点亮一堆强特征 → 判患病、严重度高、证据按权重降序。"""
    feats = _vec("找词困难", "短而简化", "中断放弃", "整体沟通障碍", "虚词省略", "句法错乱")
    monkeypatch.setattr(features, "extract_features",
                        lambda c: {"features": feats, "lit_count": 6, "error": "无", "LLManswer": "{}"})
    r = diagnose("任意")
    assert r["hasAphasia"] is True
    assert r["severity"] in ("中度", "重度")
    assert r["score"] >= APHASIA_THRESHOLD
    assert r["evidence"][0] == "短而简化"  # 权重最高(0.801)排第一


def test_diagnose_healthy(monkeypatch):
    """零点亮 → 未患病。"""
    monkeypatch.setattr(features, "extract_features",
                        lambda c: {"features": _vec(), "lit_count": 0, "error": "无", "LLManswer": "{}"})
    r = diagnose("任意")
    assert r["hasAphasia"] is False
    assert r["severity"] == "未患病"
    assert r["score"] == 0.0


def test_diagnose_parse_failure(monkeypatch):
    monkeypatch.setattr(features, "extract_features",
                        lambda c: {"features": None, "lit_count": None, "error": "JSON解析失败", "LLManswer": "乱码"})
    r = diagnose("任意")
    assert r["hasAphasia"] is None
    assert r["severity"] == "未知"
    assert r["error"] == "JSON解析失败"


@pytest.mark.skipif(not os.path.exists(CACHE), reason="features_cache.json 不在（先跑 validate_features.py all）")
def test_corpus_classification_auc():
    """在 122 例语料缓存上，加权分区分 PWA/Control 的 AUC 应 ≥ 0.9（P2 实测 0.955）。"""
    cache = json.load(open(CACHE, encoding="utf-8"))
    pos, neg = [], []
    for key, r in cache.items():
        if not r.get("features"):
            continue
        s = severity_score(r["features"])
        (pos if key.startswith("PWA/") else neg).append(s)
    assert pos and neg
    wins = sum((p > n) + 0.5 * (p == n) for p, n in product(pos, neg))
    auc = wins / (len(pos) * len(neg))
    assert auc >= 0.9, f"加权分 AUC={auc:.3f} 跌破 0.9，判别力被改坏了"
