"""P1/P2 验证：特征抽取在真实语料上区分患者 vs 健康的能力。

- 逐文件结果缓存到 features_cache.json（增量保存，中断可续跑、重跑不重复花钱）。
- 输出：点亮数分布、AUC、阈值扫描下的查准/查全/特异度、异常文件、每特征点亮率。

跑法（需 .env 的 SILICONFLOW_API_KEY）：
  set -a; source ../.env; set +a
  .venv/bin/python validate_features.py all      # 全量 26 PWA + 96 Control
  .venv/bin/python validate_features.py 12       # 每组前 12 个
  .venv/bin/python validate_features.py report   # 只读缓存出报告，不调 API
"""
import json
import os
import statistics as st
import sys
from itertools import product

from chat_corpus import list_corpus, extract_dialogue
from features import extract_features, FEATURES

CACHE = "features_cache.json"


def load_cache():
    if os.path.exists(CACHE):
        with open(CACHE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_cache(c):
    with open(CACHE, "w", encoding="utf-8") as f:
        json.dump(c, f, ensure_ascii=False, indent=1)


def run_group(group, n, cache, report_only):
    rows = []
    for f in list_corpus(group, limit_files=n):
        key = f"{group}/{f.name}"
        if key in cache:
            rows.append((f.name, cache[key]))
            continue
        if report_only:
            continue
        conv = extract_dialogue(f)
        if len(conv) < 200:
            continue
        try:
            r = extract_features(conv)
        except Exception as e:
            # 单文件失败（多为 API 超时）不中断全局，跳过、下次续跑重试
            print(f"  FAIL {key}: {e}", flush=True)
            continue
        cache[key] = r
        save_cache(cache)  # 增量：每跑完一个就落盘
        rows.append((f.name, r))
        print(f"  done {key}: 点亮={r['lit_count']}", flush=True)
    return rows


def auc(pos, neg):
    if not pos or not neg:
        return float("nan")
    w = sum((p > n) + 0.5 * (p == n) for p, n in product(pos, neg))
    return w / (len(pos) * len(neg))


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "6"
    report_only = arg == "report"
    n = None if arg in ("all", "report") else int(arg)

    cache = load_cache()
    res = {g: run_group(g, n, cache, report_only) for g in ["PWA", "Control"]}

    pwa = [(nm, r["lit_count"]) for nm, r in res["PWA"] if r["lit_count"] is not None]
    ctrl = [(nm, r["lit_count"]) for nm, r in res["Control"] if r["lit_count"] is not None]
    P = [c for _, c in pwa]
    C = [c for _, c in ctrl]

    print("\n================= 点亮数分布 =================")
    print(f"PWA     中位={st.median(P):.1f} 均值={st.mean(P):.1f} (n={len(P)})")
    print(f"Control 中位={st.median(C):.1f} 均值={st.mean(C):.1f} (n={len(C)})")
    print(f"\nAUC（点亮数区分 PWA/Control）= {auc(P, C):.3f}")

    print("\n================= 阈值扫描 =================")
    print(f"{'阈值≥':>5}{'查全(sens)':>12}{'特异(spec)':>12}{'查准(prec)':>12}{'准确':>8}")
    best = None
    for t in range(0, 14):
        tp = sum(x >= t for x in P); fn = len(P) - tp
        fp = sum(x >= t for x in C); tn = len(C) - fp
        sens = tp / len(P); spec = tn / len(C)
        prec = tp / (tp + fp) if (tp + fp) else 0
        acc = (tp + tn) / (len(P) + len(C))
        j = sens + spec - 1  # Youden's J
        if best is None or j > best[1]:
            best = (t, j)
        print(f"{t:>5}{sens:>12.2f}{spec:>12.2f}{prec:>12.2f}{acc:>8.2f}")
    print(f"\n最佳阈值(Youden J): 点亮≥{best[0]}")

    th = best[0]
    print(f"\n================= 异常文件（按阈值≥{th}）=================")
    print("漏诊(患者点亮低):", [f"{nm}({c})" for nm, c in sorted(pwa, key=lambda x: x[1]) if c < th] or "无")
    print("误诊(健康点亮高):", [f"{nm}({c})" for nm, c in sorted(ctrl, key=lambda x: -x[1]) if c >= th] or "无")

    print("\n================= 每特征点亮率 =================")
    print(f"{'特征':<14}{'PWA':>8}{'Control':>10}{'差':>8}")
    for k in FEATURES:
        pr = st.mean([r["features"][k] for _, r in res["PWA"] if r["features"]])
        cr = st.mean([r["features"][k] for _, r in res["Control"] if r["features"]])
        print(f"{k:<14}{pr:>8.2f}{cr:>10.2f}{pr - cr:>8.2f}")


if __name__ == "__main__":
    main()
