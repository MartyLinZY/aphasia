import re

import settings

# 提取出患者所说的话，并写入 sentences.txt 中
def get_sentences(conversation):

    # 获取全部对话内容
    conversation_split = conversation.split('\n')

    # 提取出以 "PAR: " 开头的句子，并去除非汉字字符
    pattern = re.compile(r'[^一-龥]') # 正则表达式匹配非汉字的字符
    sentences = []
    for sentence in conversation_split:
        if sentence.startswith("PAR"):
            # 去掉非汉字部分
            cleaned_sentence = re.sub(pattern, '', sentence)
            if cleaned_sentence:
                sentences.append(cleaned_sentence)

    with open(settings.LLM_PATH+"sentences.txt", "w", encoding="utf_8") as test:
        for sentence in sentences:
            test.write(sentence + '\n')
    # print("患者所说有效句子的个数: " + str(len(sentences)))

    return sentences
