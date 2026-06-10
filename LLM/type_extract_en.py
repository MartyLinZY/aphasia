"""对英文采样(type_sample_en.json)跑 13 特征抽取，缓存到 type_features_en.json。

用英文版 prompt(prompt_features_en.txt)，但输出仍是 13 个中文特征键，
这样英文特征向量和中文缓存(features_cache.json)直接可比。
增量落盘、单文件失败跳过，中断可续。需 .env 的 SILICONFLOW_API_KEY。
"""
import json
import os

import features  # 复用 _parse_json / FEATURES / _TRUE / MODEL
from chat_corpus import extract_dialogue_en
from siliconflow import text_conversation

SAMPLE = "type_sample_en.json"
CACHE = "type_features_en.json"

with open("prompt_features_en.txt", encoding="utf-8") as f:
    PROMPT_HEAD = f.read().strip()


def extract_en(conversation):
    raw = text_conversation(model=features.MODEL,
                            content=PROMPT_HEAD + "\n" + conversation + "\n```",
                            temperature=0)
    obj = features._parse_json(raw)  # 抛异常则上层跳过
    return {k: (1 if str(obj.get(k, 0)).strip() in features._TRUE else 0) for k in features.FEATURES}


def main():
    sample = json.load(open(SAMPLE))
    cache = json.load(open(CACHE)) if os.path.exists(CACHE) else {}
    for typ, files in sample.items():
        for fp in files:
            if fp in cache:
                continue
            conv = extract_dialogue_en(fp)
            if len(conv) < 200:
                continue
            try:
                feats = extract_en(conv)
            except Exception as e:
                print(f"  FAIL {os.path.basename(fp)}: {e}", flush=True)
                continue
            cache[fp] = {"type": typ, "features": feats, "lit": sum(feats.values())}
            json.dump(cache, open(CACHE, "w"), ensure_ascii=False)
            print(f"  done [{typ}] {os.path.basename(fp)}: 点亮={cache[fp]['lit']}", flush=True)
    print(f"\n完成，缓存 {len(cache)} 个")


if __name__ == "__main__":
    main()
