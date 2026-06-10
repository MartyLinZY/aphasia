"""零成本再评分：从 features_cache.json 重算不同聚合规则，不调 API。

对比目标：在匹配旧 diagnose1 查全率(~0.85)的阈值上，哪种聚合特异度最高。
加权方案做 LOO 交叉验证，避免"用同一批数据定权重又评估"的过拟合自欺。
"""
import json
import statistics as st
from itertools import product

from features import FEATURES

cache = json.load(open("features_cache.json", encoding="utf-8"))
# (label, feature_dict)  label=1 患者 / 0 健康
data = []
for key, r in cache.items():
    if r.get("features") is None:
        continue
    label = 1 if key.startswith("PWA/") else 0
    data.append((label, r["features"]))

P_idx = [i for i, d in enumerate(data) if d[0] == 1]
C_idx = [i for i, d in enumerate(data) if d[0] == 0]


def auc(pos, neg):
    w = sum((p > n) + 0.5 * (p == n) for p, n in product(pos, neg))
    return w / (len(pos) * len(neg))


def sweep(scores):
    """返回 (auc, 在 sens>=0.85 的最大阈值下的 spec, 该sens, 最佳Youden(t,sens,spec))。"""
    P = [scores[i] for i in P_idx]
    C = [scores[i] for i in C_idx]
    a = auc(P, C)
    ts = sorted(set(scores))
    matched, best = None, None
    for t in ts:
        sens = sum(x >= t for x in P) / len(P)
        spec = sum(x < t for x in C) / len(C)
        j = sens + spec - 1
        if best is None or j > best[3]:
            best = (round(t, 2), sens, spec, j)
        if sens >= 0.85:               # 匹配旧 diagnose1 查全率
            matched = (round(t, 2), sens, spec)
    return a, matched, best


def report(name, scores):
    a, matched, best = sweep(scores)
    mt = f"阈值≥{matched[0]} → 查全{matched[1]:.2f}/特异{matched[2]:.2f}" if matched else "—"
    print(f"{name:<26} AUC={a:.3f} | @查全≥.85: {mt} | 最佳Youden 查全{best[1]:.2f}/特异{best[2]:.2f}")


# A. 等权计数（基线，P2 用的就是这个）
report("A 等权计数(13特征)", [sum(d[1].values()) for d in data])

# B. 去掉噪声特征 重述/自我修正
drop = {"重述/自我修正"}
report("B 去重述", [sum(v for k, v in d[1].items() if k not in drop) for d in data])

# C. 只留强判别特征(P2 差>0.5)
strong = {"找词困难", "持续言语", "短而简化", "虚词省略", "句法错乱", "中断放弃", "整体沟通障碍"}
report("C 仅强特征(7个)", [sum(v for k, v in d[1].items() if k in strong) for d in data])

# D. 判别力加权(in-sample，会偏乐观)
def weights_from(idxs):
    sub = [data[i] for i in idxs]
    Ps = [d for d in sub if d[0] == 1]
    Cs = [d for d in sub if d[0] == 0]
    w = {}
    for k in FEATURES:
        pr = st.mean([d[1][k] for d in Ps]) if Ps else 0
        cr = st.mean([d[1][k] for d in Cs]) if Cs else 0
        w[k] = max(0.0, pr - cr)          # 负判别力的特征权重归零
    return w

w_all = weights_from(range(len(data)))
report("D 判别加权(in-sample)", [sum(w_all[k] * v for k, v in d[1].items()) for d in data])

# D'. 同上但 LOO 交叉验证(诚实估计)
loo_scores = []
for i in range(len(data)):
    w = weights_from([j for j in range(len(data)) if j != i])
    loo_scores.append(sum(w[k] * v for k, v in data[i][1].items()))
report("D' 判别加权(LOO-CV)", loo_scores)

print(f"\n样本: 患者{len(P_idx)} 健康{len(C_idx)}  | 权重(D, 前6):",
      ", ".join(f"{k}={w_all[k]:.2f}" for k in sorted(w_all, key=w_all.get, reverse=True)[:6]))