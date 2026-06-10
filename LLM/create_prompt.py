import settings

# 将对话内容添加进 prompt 模版中，构造出 prompt
# 注：create_prompt_diagnose 随 diagnose1 一并删除；诊断特征 prompt 见 features.py。

def create_prompt_repair(conversation):

    with open(settings.LLM_PATH+"prompt_repair.txt", "r", encoding="utf-8") as f:
        content = f.read().strip() + "\n" + conversation + "\n" + "```"

    with open(settings.LLM_PATH+"prompt_repair_test.txt", "w", encoding="utf-8") as test:
        test.write(content)

    return content
