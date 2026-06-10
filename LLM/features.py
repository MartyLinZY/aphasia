"""失语症语言学特征抽取 —— TAB / APROCSA 思路的中文实现。

替代旧 diagnose1 的"一锤子判是否患病"：让 LLM 逐条判 13 个有定义、有例子的
二值语言学特征，输出扁平 JSON。好处：健康人多数特征打 0（修过度诊断）、
严重度可由"点亮哪些特征"聚合（可分级、可解释）。

定义/示例在 prompt_features.txt。温度设 0 保证可复现（诊断不能随机）。
"""
import json
import re

import settings
from siliconflow import text_conversation

MODEL = "Pro/deepseek-ai/DeepSeek-V3"

# 13 个中文适配特征（从 TAB 的 19 条本地化：删了中文几乎没有的"词缀省略"、
# 经 ASR 转写丢失的"音位错语 / conduite d'approche"）
FEATURES = [
    "找词困难", "持续言语", "刻板自动语", "短而简化", "虚词省略",
    "语义错语", "新词", "空话", "句法错乱", "重述/自我修正",
    "中断放弃", "跑题", "整体沟通障碍",
]

_TRUE = {"1", "1.0", "true", "True", "是", "yes", "Yes"}


def _build_prompt(conversation):
    with open(settings.LLM_PATH + "prompt_features.txt", encoding="utf-8") as f:
        return f.read().strip() + "\n" + conversation + "\n```"


def _parse_json(raw):
    """从 LLM 回复里抠出 JSON：剥 markdown 代码块、取第一个 {...}。"""
    s = raw.strip()
    s = re.sub(r"^```(?:json)?", "", s).strip()
    s = re.sub(r"```$", "", s).strip()
    m = re.search(r"\{.*\}", s, re.S)
    if m:
        s = m.group(0)
    return json.loads(s)


def extract_features(conversation):
    """返回 {features: {特征:0/1}, lit_count, error, LLManswer}。解析失败时 features=None。"""
    prompt = _build_prompt(conversation)
    raw = text_conversation(model=MODEL, content=prompt, temperature=0)
    try:
        obj = _parse_json(raw)
    except Exception:
        return {"features": None, "lit_count": None, "error": "JSON解析失败", "LLManswer": raw}

    feats = {k: (1 if str(obj.get(k, 0)).strip() in _TRUE else 0) for k in FEATURES}
    return {
        "features": feats,
        "lit_count": sum(feats.values()),
        "error": "无",
        "LLManswer": raw,
    }


# --- 严重度聚合（在 JiangLin 语料 26患者 vs 96对照 上标定，validate_features/rescore/p3_severity）---
# 权重 = 各特征"患者点亮率 − 对照点亮率"（判别力），负判别力归零。
# 加权分 AUC=0.955（等权）/ 0.962（加权 LOO-CV）；与 WAB-AQ 负相关 −0.69~−0.90。
FEATURE_WEIGHTS = {
    "找词困难": 0.724, "持续言语": 0.55, "刻板自动语": 0.284, "短而简化": 0.801,
    "虚词省略": 0.745, "语义错语": 0.143, "新词": 0.451, "空话": 0.133,
    "句法错乱": 0.658, "重述/自我修正": 0.312, "中断放弃": 0.788, "跑题": 0.192,
    "整体沟通障碍": 0.763,
}

# 患病判定阈值：加权分≥此值判为失语（查全88%/特异91%，对照分布90分位≈2.2）。
APHASIA_THRESHOLD = 2.3

# 严重度分档（⚠️ 暂定：仅用≈8个带 WAB-AQ 的患者标定，样本极小，连续 score 比档位可靠，
# 拿到更多 WAB-AQ 后应重标。分类(hasAphasia)经 122 例验证，分档是便利层）。
SEVERITY_BANDS = [(APHASIA_THRESHOLD, "未患病"), (4.0, "轻度"), (5.5, "中度"), (float("inf"), "重度")]


def severity_score(features):
    """13 个二值特征 → 判别力加权连续分（越高=损伤越重）。"""
    return round(sum(FEATURE_WEIGHTS[k] * v for k, v in features.items()), 2)


def _band(score):
    for cutoff, label in SEVERITY_BANDS:
        if score < cutoff:
            return label
    return SEVERITY_BANDS[-1][1]


def diagnose(conversation):
    """客观特征诊断：抽特征 → 加权分 → 患病判定 + 严重度档 + 证据特征。

    替代旧 diagnose2（困惑度，方向已被语料证伪）。返回 dict：
    {hasAphasia, severity, score, features, evidence, error, LLManswer}。
    """
    r = extract_features(conversation)
    if r["features"] is None:
        return {"hasAphasia": None, "severity": "未知", "score": None,
                "features": None, "evidence": [], "error": r["error"], "LLManswer": r["LLManswer"]}

    feats = r["features"]
    score = severity_score(feats)
    has = score >= APHASIA_THRESHOLD
    # 证据：点亮的特征按判别力权重降序，方便前端展示"为什么这么判"
    evidence = sorted((k for k, v in feats.items() if v), key=lambda k: -FEATURE_WEIGHTS[k])
    return {
        "hasAphasia": has,
        "severity": _band(score) if has else "未患病",
        "score": score,
        "features": feats,
        "evidence": evidence,
        "error": "无",
        "LLManswer": r["LLManswer"],
    }
