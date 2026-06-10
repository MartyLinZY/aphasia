"""
AphasiaBank CHAT(.cha)语料解析 —— 把 JiangLin Corpus 的转写转成系统认的输入。

为什么需要它：
- .cha 里患者行是 `*PAR:\t你 [/] 你好 . 2869_4410`，带星号、CLAN 标注(`[/]`)、时间戳。
- 这里做桥接：抽 *PAR / *INV 行 → 剥非汉字或剥标注 → 得到干净的患者语句 / 医患对话。
- extract_dialogue 供特征诊断(features.diagnose)用；extract_par_sentences 供语料分析用。

数据集不进 git（临床数据，受 AphasiaBank 协议约束），路径用环境变量 CORPUS_PATH 覆盖，
默认指向仓库同级的 JiangLin/ 目录。
"""
import os
import re
from pathlib import Path

_DEFAULT_CORPUS = Path(__file__).resolve().parents[2] / "JiangLin"
CORPUS_PATH = Path(os.environ.get("CORPUS_PATH", _DEFAULT_CORPUS))

_NON_HAN = re.compile(r"[^一-龥]")


def extract_par_sentences(cha_path, min_len=2, max_len=40):
    """从单个 .cha 抽取患者(*PAR)语句，剥成纯汉字，按长度过滤。"""
    sentences = []
    with open(cha_path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("*PAR:"):
                cleaned = _NON_HAN.sub("", line)
                if min_len <= len(cleaned) <= max_len:
                    sentences.append(cleaned)
    return sentences


_BULLET = re.compile("\x15[^\x15]*\x15")          # CHAT 用 \x15…\x15 包住时间戳
_TIMESTAMP = re.compile(r"\s*\d+_\d+\s*$")
_CLAN_BRACKET = re.compile(r"\[[^\]]*\]")        # [/] [//] [: xxx] 等 CLAN 码
_CLAN_AMP = re.compile(r"&[=~]?\S+")             # &=nodding 手势 / &-uh 填充
_CLAN_MISC = re.compile(r"[<>+]+|\(\.*\)|xxx")   # <> 重叠、+... 中断、(.)停顿、xxx 听不清


def extract_dialogue(cha_path):
    """把 .cha 转成 prompt 认的 INV/PAR 对话文本（去 %mor/%gra 标注、时间戳、CLAN 码）。

    特征诊断(features.diagnose)把整段对话发给 LLM，prompt 里说明 INV=医生 PAR=患者，
    所以这里只保留对话行、清掉转写标注噪声，尽量贴近真实医患转写。
    """
    lines = []
    with open(cha_path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("*INV:") or line.startswith("*PAR:"):
                speaker = line[1:4]
                text = line[5:]
                text = _BULLET.sub("", text)
                text = _TIMESTAMP.sub("", text)
                text = _CLAN_BRACKET.sub("", text)
                text = _CLAN_AMP.sub("", text)
                text = _CLAN_MISC.sub("", text)
                text = re.sub(r"\s+", "", text).strip()  # 中文去 token 间空格
                if text:
                    lines.append(f"{speaker}: {text}")
    return "\n".join(lines)


def list_corpus(group, limit_files=None):
    """列出某组(PWA/Control)的 .cha 文件路径。语料缺失时返回空列表。"""
    group_dir = CORPUS_PATH / group
    if not group_dir.is_dir():
        return []
    files = sorted(group_dir.glob("*.cha"))  # 含 Jinni/LiuNa（带 WAB-AQ 标签的患者）
    return files[:limit_files] if limit_files else files


def corpus_available():
    """语料是否就绪（用于 pytest skip 判断）。"""
    return bool(list_corpus("PWA")) and bool(list_corpus("Control"))
