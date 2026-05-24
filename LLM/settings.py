import os

_BASE = os.path.dirname(os.path.abspath(__file__))

LLM_PATH = os.environ.get("LLM_PATH", _BASE + os.sep)
BERT_PATH = os.environ.get("BERT_PATH", os.path.join(_BASE, "models", "bert-base-chinese"))
