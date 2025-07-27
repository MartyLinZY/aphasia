import requests
import json

import settings

# 文本对话大模型
def text_conversation(model="Pro/deepseek-ai/DeepSeek-V3", content="say hello", output_file=settings.LLM_PATH+"output.txt", mode="a"):

    url = "https://api.siliconflow.cn/v1/chat/completions"
    api_key = "sk-akpehvphtuqghygmpjolclwwygbkblxjuopbcyjbroypgsrj"
    headers = {
        "Authorization": "Bearer " + api_key,
        "Content-Type": "application/json"
    }

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": content
            }
        ],
        "max_tokens": 4096,
        "temperature": 0.5
    }

    response = requests.request("POST", url, json=payload, headers=headers)
    answer = json.loads(response.text)['choices'][0]['message']['content']

    with open(output_file, mode, encoding="utf-8") as test:
        test.write(answer + '\n')
    # print(response.text)
    return answer

# 语音转文本大模型
def audio_to_text(model="FunAudioLLM/SenseVoiceSmall", audio_path=settings.LLM_PATH+"audio_test.wav", output_file=settings.LLM_PATH+"output.txt", mode="a"):

    url = "https://api.siliconflow.cn/v1/audio/transcriptions"
    api_key = "sk-akpehvphtuqghygmpjolclwwygbkblxjuopbcyjbroypgsrj"
    boundary = "-----011000010111000001101001"
    headers = {
        "Authorization": "Bearer " + api_key,
        "Content-Type": f"multipart/form-data; boundary={boundary}"
    }

    with open(audio_path, "rb") as audio_file:
        audio_content = audio_file.read()
        payload = (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="model"\r\n\r\n'
            f"{model}\r\n"
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="file"; filename="{audio_path}"\r\n'
            f"Content-Type: audio/wav\r\n\r\n"
        ).encode('utf-8')
        payload += audio_content
        payload += f"\r\n--{boundary}--\r\n".encode('utf-8')

        response = requests.request("POST", url, data=payload, headers=headers)
        answer = json.loads(response.text)['text']

        with open(output_file, mode, encoding="utf-8") as f:
            f.write(answer)
        # print(response.text)
        return answer

if __name__ == "__main__":

    # text_conversation()

    # audio_to_text(mode="w")

    pass
