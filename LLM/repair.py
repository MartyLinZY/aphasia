import argparse
import io
import json
import sys
from create_prompt import create_prompt_repair
import settings
from siliconflow import text_conversation

# 强制标准输出为UTF-8
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# 将对话提供给大模型，修复患者的话
def repair(conversation):

    model = "Pro/deepseek-ai/DeepSeek-V3"

    content = create_prompt_repair(conversation)
    diagnosis = text_conversation(model=model, content=content, output_file=settings.LLM_PATH+"repair.txt", mode="w")

    result = diagnosis.strip().strip('`').strip()
    return {"repairedConversation": result}
    
if __name__ == "__main__":

    # with open(settings.LLM_PATH+"conversation4.txt", "r", encoding="utf-8") as f:
    #     conversation = f.read().strip()
    # repair(conversation)

    # 命令行参数解析
    parser = argparse.ArgumentParser(description="利用大模型修复失语症患者的话")
    parser.add_argument('conversation', type=str, help='医患对话内容')
    args = parser.parse_args()
    # conversation = json.loads(args.jsonConversation) # 将JSON字符串转换为Python对象

    try:
        result = repair(args.conversation)
        output = {'repairedConversation': result.get('repairedConversation')}
        print(json.dumps(output, ensure_ascii=False))  # 标准输出JSON
    except Exception as e:
        # 捕获异常并以JSON格式输出错误
        print(json.dumps({'error': str(e)}, ensure_ascii=False))
        sys.exit(1)
