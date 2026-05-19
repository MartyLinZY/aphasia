import numpy as np
import torch
import torch.nn as nn
from transformers import BertTokenizer, BertForMaskedLM
from transformers import logging as transformers_logging

import settings

transformers_logging.set_verbosity_error()

model_path = settings.BERT_PATH

# 模块级缓存：模型只加载一次，后续调用直接复用
_model = None
_tokenizer = None

def _get_model():
    global _model, _tokenizer
    if _model is None:
        _tokenizer = BertTokenizer.from_pretrained(model_path)
        _model = BertForMaskedLM.from_pretrained(model_path)
        _model.eval()
    return _model, _tokenizer

def calculate_perplexity(sentence):
    model, tokenizer = _get_model()
    with torch.no_grad():
        tokenize_input = tokenizer.tokenize(sentence)
        tensor_input = torch.tensor([tokenizer.convert_tokens_to_ids(tokenize_input)])
        sen_len = len(tokenize_input)
        sentence_loss = 0.

        for i, word in enumerate(tokenize_input):
            tokenize_input[i] = '[MASK]'
            mask_input = torch.tensor([tokenizer.convert_tokens_to_ids(tokenize_input)])
            output = model(mask_input)

            prediction_scores = output[0]
            softmax = nn.Softmax(dim=0)
            ps = softmax(prediction_scores[0, i]).log()
            word_loss = ps[tensor_input[0, i]]
            sentence_loss += word_loss.item()
            tokenize_input[i] = word

        perplexity = np.exp(-sentence_loss / sen_len)
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
