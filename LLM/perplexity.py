import numpy as np
import torch
import torch.nn as nn
from transformers import BertTokenizer, BertForMaskedLM
from transformers import logging as transformers_logging

import settings

transformers_logging.set_verbosity_error()

model_path = settings.BERT_PATH

# 计算一个句子的困惑度
def calculate_perplexity(sentence):
    with torch.no_grad():
        model = BertForMaskedLM.from_pretrained(model_path)
        model.eval()

        tokenizer = BertTokenizer.from_pretrained(model_path)
        tokenize_input = tokenizer.tokenize(sentence)
        # print(tokenize_input)
        tensor_input = torch.tensor([tokenizer.convert_tokens_to_ids(tokenize_input)])
        # print(tensor_input)
        sen_len = len(tokenize_input)
        sentence_loss = 0.

        for i, word in enumerate(tokenize_input):
            tokenize_input[i] = '[MASK]'
            # print(tokenize_input)
            mask_input = torch.tensor([tokenizer.convert_tokens_to_ids(tokenize_input)])
            output = model(mask_input)
            # print(len(output))

            prediction_scores = output[0]
            # print(prediction_scores.shape)
            softmax = nn.Softmax(dim=0)
            ps = softmax(prediction_scores[0, i]).log()
            # print(ps.shape)
            word_loss = ps[tensor_input[0, i]]
            sentence_loss += word_loss.item()
            tokenize_input[i] = word

        perplexity = np.exp(-sentence_loss/sen_len)
        # print(perplexity)
    return perplexity

if __name__ == "__main__":

    sentences = [
        "我喜欢吃西瓜。",
        "我喜欢吃房子。"
    ]

    print('\n' + '代码输出:')

    for sentence in sentences:
        perplexity = calculate_perplexity(sentence)
        print('\n' + '句子: ' + sentence + '\n' + '困惑度: ' + str(perplexity))

    print('\n')
