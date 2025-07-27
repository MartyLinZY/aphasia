import argparse
import io
import json
import sys
import settings
from siliconflow import text_conversation
from create_prompt import create_prompt_diagnose
from get_sentences import get_sentences
from perplexity import calculate_perplexity

# 强制标准输出为UTF-8
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# 将对话提供给大模型，得到 “是否患病” “所患类型” “严重程度”。结果会被写入 diagnosis.txt 中
def diagnose1(conversation):

    model = "Pro/deepseek-ai/DeepSeek-V3"

    content = create_prompt_diagnose(conversation)
    diagnosis = text_conversation(model=model, content=content, output_file=settings.LLM_PATH+"diagnosis.txt", mode="w")
    # diagnosis应为一行，三个短语，用空格符分割
    result = diagnosis.strip().replace("{", "").replace("}", "").split()
    if len(result) == 3 and (result[0] == "是" or result[0] == "否"):
        return {"type": result[1], "severity": result[2], "error": "无", "LLManswer": diagnosis}
    else:
        return {"type": "未知", "severity": "未知", "error": f"大模型输出有误", "LLManswer": diagnosis}

# 计算模型对患者的话的困惑度，据此判断患病的严重程度
def diagnose2(conversation):
    sentences = get_sentences(conversation) # 得到患者所说的话
    sen_len = len(sentences)
    loss = 0.
    for sentence in sentences:
        ppl = calculate_perplexity(sentence)
        loss += ppl
        # print("困惑度: " + str(ppl))
    perplexity = loss / sen_len # 患者所有话的平均困惑度
    # print(perplexity)
    return perplexity


if __name__ == "__main__":

    # with open(settings.LLM_PATH+"conversation1.txt", "r", encoding="utf-8") as f:
    #     conversation = f.read().strip()
    # diagnose1(conversation)
    # diagnose2(conversation)

    # 命令行参数解析
    parser = argparse.ArgumentParser(description="利用大模型进行失语症对话诊断")
    parser.add_argument('mode', choices=['diagnose1', 'diagnose2'], help='诊断模式：diagnose1利用大模型诊断患病类型和严重程度，diagnose2计算大模型对患者话的困惑度')
    parser.add_argument('conversation', type=str, help='医患对话内容')
    args = parser.parse_args()
    # conversation = json.loads(args.jsonConversation) # 将JSON字符串转换为Python对象

    try:
        if args.mode == 'diagnose1':
            result = diagnose1(args.conversation)
            output = {'type': result.get('type'), 'severity': result.get('severity'), 'error': result.get('error'), 'LLManswer': result.get('LLManswer')}
            print(json.dumps(output, ensure_ascii=False))  # 标准输出JSON
        elif args.mode == 'diagnose2':
            perplexity = diagnose2(args.conversation)
            output = {'perplexity': perplexity}
            print(json.dumps(output, ensure_ascii=False))  # 标准输出JSON
    except Exception as e:
        # 捕获异常并以JSON格式输出错误
        print(json.dumps({'error': str(e)}, ensure_ascii=False))
        sys.exit(1)
