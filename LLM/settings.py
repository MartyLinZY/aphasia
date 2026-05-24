import os

_BASE = os.path.dirname(os.path.abspath(__file__))

LLM_PATH = os.environ.get("LLM_PATH", _BASE + os.sep)
# 下游用 `settings.LLM_PATH + "xxx.txt"` 直接拼接，必须以分隔符结尾，
# 否则用户传 `LLM_PATH=/path/to/LLM` 时会拼出 `/path/to/LLMxxx.txt`。
if not LLM_PATH.endswith(os.sep):
    LLM_PATH += os.sep
BERT_PATH = os.environ.get("BERT_PATH", os.path.join(_BASE, "models", "bert-base-chinese"))
