"""siliconflow.text_conversation 单元测试。

mock requests.post 覆盖：
- 缺 SILICONFLOW_API_KEY → RuntimeError（不发请求）
- happy 200 → 返 message content
- 非 200 → 抛 RuntimeError 含状态码
- requests.RequestException（含 Timeout / ConnectionError）→ 抛 RuntimeError
- 响应 JSON 结构异常 → 抛 RuntimeError

运行：.venv-test/bin/pytest test_siliconflow.py -v
"""
import os
from unittest.mock import MagicMock, patch

import pytest
import requests

import siliconflow


def _mock_response(status_code: int = 200, json_body=None, text: str = ""):
    resp = MagicMock(spec=requests.Response)
    resp.status_code = status_code
    resp.text = text
    if json_body is not None:
        resp.json.return_value = json_body
    return resp


def test_missing_api_key_raises(monkeypatch):
    monkeypatch.delenv("SILICONFLOW_API_KEY", raising=False)
    with pytest.raises(RuntimeError, match="SILICONFLOW_API_KEY 未配置"):
        siliconflow.text_conversation(content="hi")


def test_happy_path_returns_message_content(monkeypatch):
    monkeypatch.setenv("SILICONFLOW_API_KEY", "fake-key")
    fake_resp = _mock_response(
        200,
        json_body={"choices": [{"message": {"content": "你好"}}]},
    )
    with patch.object(siliconflow.requests, "post", return_value=fake_resp) as post:
        result = siliconflow.text_conversation(content="hi")
    assert result == "你好"
    # 关键：发请求时必须带 timeout，否则挂起会拖垮上游链路
    _, kwargs = post.call_args
    assert kwargs["timeout"] == siliconflow.REQUEST_TIMEOUT_SECONDS
    assert kwargs["headers"]["Authorization"] == "Bearer fake-key"


def test_non_200_raises_runtime_error(monkeypatch):
    monkeypatch.setenv("SILICONFLOW_API_KEY", "fake-key")
    fake_resp = _mock_response(429, text='{"error":"rate limit"}')
    with patch.object(siliconflow.requests, "post", return_value=fake_resp):
        with pytest.raises(RuntimeError, match="siliconflow HTTP 429"):
            siliconflow.text_conversation(content="hi")


def test_network_exception_raises_runtime_error(monkeypatch):
    monkeypatch.setenv("SILICONFLOW_API_KEY", "fake-key")
    with patch.object(
        siliconflow.requests,
        "post",
        side_effect=requests.Timeout("read timeout after 30s"),
    ):
        with pytest.raises(RuntimeError, match="siliconflow 网络异常"):
            siliconflow.text_conversation(content="hi")


def test_malformed_json_raises_runtime_error(monkeypatch):
    monkeypatch.setenv("SILICONFLOW_API_KEY", "fake-key")
    # choices 缺失 → KeyError 路径
    fake_resp = _mock_response(200, json_body={"unexpected": "shape"}, text='{"unexpected":"shape"}')
    with patch.object(siliconflow.requests, "post", return_value=fake_resp):
        with pytest.raises(RuntimeError, match="siliconflow 响应结构异常"):
            siliconflow.text_conversation(content="hi")
