"""SiliconFlow chat completions 客户端。

只暴露 ``text_conversation``——给 ``diagnose.py`` / ``repair.py`` 用。原来还有
``audio_to_text`` 但全工程 0 caller（ASR 走 Java 后端的讯飞 SDK，不走这里），
已删；如未来恢复参考此处加 ``requests.post(..., files=...)``。
"""

import os

import requests

API_URL = "https://api.siliconflow.cn/v1/chat/completions"
DEFAULT_MODEL = "Pro/deepseek-ai/DeepSeek-V3"
REQUEST_TIMEOUT_SECONDS = 30


def text_conversation(model: str = DEFAULT_MODEL, content: str = "say hello",
                      temperature: float = 0.5) -> str:
    """调 SiliconFlow chat completions 返回回答字符串。

    SILICONFLOW_API_KEY 必须在环境变量中。任何 HTTP / 解析失败一律抛
    ``RuntimeError``——上游 diagnose.py / repair.py 的 ``try/except Exception``
    会把它包成 FastAPI 500，让前端拿到清晰错误而不是无限挂起。
    """
    api_key = os.environ.get("SILICONFLOW_API_KEY", "")
    if not api_key:
        raise RuntimeError("SILICONFLOW_API_KEY 未配置，无法调用 siliconflow text_conversation")

    headers = {
        "Authorization": "Bearer " + api_key,
        "Content-Type": "application/json",
    }
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
        "max_tokens": 4096,
        "temperature": temperature,
    }

    try:
        response = requests.post(
            API_URL,
            json=payload,
            headers=headers,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
    except requests.RequestException as e:
        # 含 ConnectionError / Timeout / 等所有 requests 层异常
        raise RuntimeError(f"siliconflow 网络异常: {e}") from e

    if response.status_code != 200:
        raise RuntimeError(
            f"siliconflow HTTP {response.status_code}: {response.text[:500]}"
        )

    try:
        return response.json()["choices"][0]["message"]["content"]
    except (KeyError, IndexError, ValueError) as e:
        raise RuntimeError(
            f"siliconflow 响应结构异常: {response.text[:500]}"
        ) from e
