import settings

# 将对话内容添加进 prompt 模版中，构造出 prompt

def create_prompt_diagnose(conversation):

    with open(settings.LLM_PATH+"prompt_diagnose.txt", "r", encoding="utf-8") as f:
        content = f.read().strip() + "\n" + conversation + "\n" + "```"

    with open(settings.LLM_PATH+"prompt_diagnose_test.txt", "w", encoding="utf-8") as test:
        test.write(content)

    return content

def create_prompt_repair(conversation):

    with open(settings.LLM_PATH+"prompt_repair.txt", "r", encoding="utf-8") as f:
        content = f.read().strip() + "\n" + conversation + "\n" + "```"

    with open(settings.LLM_PATH+"prompt_repair_test.txt", "w", encoding="utf-8") as test:
        test.write(content)

    return content

if __name__ == "__main__":
    with open(settings.LLM_PATH+"conversation.txt", "r", encoding="utf-8") as c:
        conversation = c.read().strip()
    create_prompt_diagnose(conversation)
