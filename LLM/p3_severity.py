"""P3 轻量验证：加权严重度分 vs WAB-AQ 金标准的相关性（零成本，从缓存算）。

WAB-AQ 越高=损伤越轻；特征分越高=损伤越重 → 预期【负相关】。
n=11，小样本，只做趋势判断，不是临床标定。
"""
import json
import statistics as st

import numpy as np

from features import FEATURES

# WAB-AQ 金标准（来源：JiangLin/PWA/0aphasia.xlsx 直接匹配 + 0info24-26.xlsx 推断映射）
AQ = {
    # 0aphasia.xlsx，文件名与表格补零差异已对齐（确信）
    "Jinni03a": 54.0,    # Broca
    "LiuNa04a": 74.5, "LiuNa04b": 93.6,   # Anomia（04b 近正常线，基本恢复）
    "LiuNa09": 88.1, "LiuNa10": 87.5, "LiuNa11": 62.7,
    "LiuNa12": 92.9, "LiuNa17": 54.8,     # 17=Wernicke
    # 0info24-26.xlsx，Questa1/2/3a→24/25/26a 推断映射（⚠️不确定）
    "JiangLin24a": 88.0, "JiangLin25a": 87.8, "JiangLin26a": 79.3,
}

cache = json.load(open("features_cache.json", encoding="utf-8"))

# 用全量数据定判别力权重（方案D）
data = [(1 if k.startswith("PWA/") else 0, r["features"])
        for k, r in cache.items() if r.get("features")]
Ps = [d[1] for d in data if d[0] == 1]
Cs = [d[1] for d in data if d[0] == 0]
W = {k: max(0.0, st.mean([d[k] for d in Ps]) - st.mean([d[k] for d in Cs])) for k in FEATURES}

def wscore(feats):
    return sum(W[k] * v for k, v in feats.items())

def spearman(x, y):
    def rank(a):
        order = sorted(range(len(a)), key=lambda i: a[i])
        r = [0] * len(a)
        for pos, i in enumerate(order):
            r[i] = pos
        return r
    return float(np.corrcoef(rank(x), rank(y))[0, 1])

rows = []
for name, aq in AQ.items():
    r = cache.get(f"PWA/{name}.cha")
    if not r or not r.get("features"):
        print(f"  [缺缓存] {name}"); continue
    rows.append((name, aq, wscore(r["features"]), r["lit_count"]))

rows.sort(key=lambda x: x[1])  # 按 AQ 升序（重→轻）
print(f"{'患者':<13}{'WAB-AQ':>8}{'加权分':>9}{'点亮数':>7}")
for name, aq, ws, lit in rows:
    print(f"{name:<13}{aq:>8.1f}{ws:>9.2f}{lit:>7d}")

aqs = [r[1] for r in rows]
wss = [r[2] for r in rows]
lits = [r[3] for r in rows]
print(f"\nn={len(rows)}")
print(f"加权分 vs AQ:  Pearson r={np.corrcoef(wss, aqs)[0,1]:+.3f}  Spearman ρ={spearman(wss, aqs):+.3f}")
print(f"点亮数 vs AQ:  Pearson r={np.corrcoef(lits, aqs)[0,1]:+.3f}  Spearman ρ={spearman(lits, aqs):+.3f}")
print("（预期负相关：AQ越高=越轻=分越低）")