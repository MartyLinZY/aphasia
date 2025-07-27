LLM 实现了两个 Python 脚本：
1. diagnose.py 有两个模式，diagnose1 可以根据医患对话判断患病类型与严重程度，diagnose2 可以根据医患对话计算 bert-base-chinese模型对患者话的困惑度。
2. repair.py 可以根据医患对话修复患者的话。

使用前：
将 settings.py 中的 LLM_PATH 设置为 LLM 目录的路径。
将 settings.py 中的 BERT_PATH 设置为 Bert-base-Chinese 的路径。
Bert-base-Chinese 在 https://huggingface.co/google-bert/bert-base-chinese/tree/main 下载。
注：后端 backend 的 APPSetting.java 中 Python 脚本的部分也要进行设置。

前端实现了两个页面，llm_diagnose 和 llm_repair。
这两个页面都是输入对话内容，然后点击按钮申请服务。
对于同一段对话，只可以点击一次按钮，获取到对应的服务后，按钮将变为未响应状态。
当输入框内的对话内容改变时，按钮恢复为可点击状态，针对新的对话内容提供服务。