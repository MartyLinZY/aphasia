"""3 类(Broca/Anomic/Wernicke)分型：朴素贝叶斯。

- 从英文特征(type_features_en.json)学 P(特征|类型)。
- 英文内部留一交叉验证(LOO) → 混淆矩阵（天花板：特征到底能不能分这 3 类）。
- 迁移到中文验证集(type_val_zh.json + features_cache.json) → 预测 vs 真值。
零 API，纯本地计算。
"""
import json
import math
from collections import Counter, defaultdict

from features import FEATURES

TYPES = ["Broca", "Anomic", "Wernicke"]
ALPHA = 1.0  # 拉普拉斯平滑


def train(samples):
    """samples: list[(type, feature_dict)] → (prior, P(f=1|type))。"""
    by_type = defaultdict(list)
    for t, f in samples:
        by_type[t].append(f)
    prior, p1 = {}, {}
    total = len(samples)
    for t in TYPES:
        n = len(by_type[t])
        prior[t] = n / total if total else 0
        p1[t] = {k: (sum(f[k] for f in by_type[t]) + ALPHA) / (n + 2 * ALPHA) for k in FEATURES}
    return prior, p1


def predict(feat, prior, p1):
    """返回 (预测类型, {类型: 概率})。"""
    logp = {}
    for t in TYPES:
        if prior[t] == 0:
            logp[t] = -1e9; continue
        s = math.log(prior[t])
        for k in FEATURES:
            p = p1[t][k]
            s += math.log(p) if feat[k] else math.log(1 - p)
        logp[t] = s
    m = max(logp.values())
    exp = {t: math.exp(logp[t] - m) for t in TYPES}
    z = sum(exp.values())
    probs = {t: exp[t] / z for t in TYPES}
    return max(probs, key=probs.get), probs


def confusion(pairs):
    """pairs: list[(true, pred)] → 打印混淆矩阵 + 准确率。"""
    cm = defaultdict(Counter)
    for tr, pr in pairs:
        cm[tr][pr] += 1
    print(f"{'真\\预':>10}" + "".join(f"{t:>10}" for t in TYPES) + f"{'准确':>8}")
    correct = 0
    for tr in TYPES:
        row = cm[tr]
        n = sum(row.values())
        acc = row[tr] / n if n else 0
        correct += row[tr]
        print(f"{tr:>10}" + "".join(f"{row[t]:>10}" for t in TYPES) + f"{acc:>8.0%}")
    print(f"总体准确率: {correct}/{len(pairs)} = {correct/len(pairs):.0%}")


def main():
    eng = json.load(open("type_features_en.json", encoding="utf-8"))
    samples = [(v["type"], v["features"]) for v in eng.values()]
    print(f"英文样本: {dict(Counter(t for t, _ in samples))}\n")

    # 1. 英文内部 LOO
    print("===== 英文内部 留一交叉验证(天花板) =====")
    loo = []
    items = list(eng.values())
    for i, v in enumerate(items):
        train_set = [(u["type"], u["features"]) for j, u in enumerate(items) if j != i]
        prior, p1 = train(train_set)
        pred, _ = predict(v["features"], prior, p1)
        loo.append((v["type"], pred))
    confusion(loo)

    # 2. 全英文训练 → 类型 signature(各特征点亮率)
    prior, p1 = train(samples)
    print("\n===== 各类型特征 signature (P(特征=1|类型), 仅列差异大的) =====")
    print(f"{'特征':<14}" + "".join(f"{t:>10}" for t in TYPES))
    for k in FEATURES:
        vals = [p1[t][k] for t in TYPES]
        if max(vals) - min(vals) >= 0.25:  # 只列有判别力的
            print(f"{k:<14}" + "".join(f"{p1[t][k]:>10.2f}" for t in TYPES))

    # 3. 迁移到中文
    print("\n===== 迁移：中文验证集 =====")
    zh_cache = json.load(open("features_cache.json", encoding="utf-8"))
    zh_val = json.load(open("type_val_zh.json", encoding="utf-8"))
    pairs = []
    details = []
    for name, truth in zh_val.items():
        feat = zh_cache[f"PWA/{name}.cha"]["features"]
        pred, probs = predict(feat, prior, p1)
        pairs.append((truth, pred))
        details.append((truth, name, pred, probs))
    # 先打非 Anomic 的逐个(样本少，看清楚)，Anomic 汇总
    for truth in ["Broca", "Wernicke"]:
        for tr, name, pred, probs in details:
            if tr == truth:
                ps = " ".join(f"{t}={probs[t]:.0%}" for t in TYPES)
                print(f"  [{truth}] {name:14s} → 预测 {pred:9s} ({ps})")
    anomic = [(tr, pr) for tr, _, pr, _ in details if tr == "Anomic"]
    acc_a = sum(pr == "Anomic" for _, pr in anomic) / len(anomic)
    print(f"  [Anomic] 21 个 → 预测对 {sum(pr=='Anomic' for _,pr in anomic)}/{len(anomic)} = {acc_a:.0%}")
    print()
    confusion(pairs)


if __name__ == "__main__":
    main()
