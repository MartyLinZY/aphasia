"""
FastAPI 微服务路由测试（app.py）。

为避免依赖 torch/transformers/BERT 模型与外部 SiliconFlow API，
在导入 app 之前把 diagnose / repair 模块替换为桩模块，
从而只验证 FastAPI 的路由、入参校验与响应透传契约。
运行：.venv-test/bin/pytest test_app.py -v
"""
import sys
import types

from fastapi.testclient import TestClient


def _install_stubs():
    diagnose_stub = types.ModuleType("diagnose")
    diagnose_stub.diagnose1 = lambda conversation: {
        "type": "运动性失语", "severity": "中度", "error": "无", "LLManswer": "是 运动性失语 中度",
    }
    diagnose_stub.diagnose2 = lambda conversation: 123.45
    sys.modules["diagnose"] = diagnose_stub

    repair_stub = types.ModuleType("repair")
    repair_stub.repair = lambda conversation: {"repairedConversation": "我想喝水。"}
    sys.modules["repair"] = repair_stub


_install_stubs()
import app as app_module  # noqa: E402

client = TestClient(app_module.app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_diagnose1_success():
    resp = client.post("/diagnose1", json={"conversation": "医生：你好\n患者：水...喝"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["type"] == "运动性失语"
    assert body["severity"] == "中度"


def test_diagnose2_success():
    resp = client.post("/diagnose2", json={"conversation": "患者：水...喝"})
    assert resp.status_code == 200
    assert resp.json() == {"perplexity": 123.45}


def test_repair_success():
    resp = client.post("/repair", json={"conversation": "我...水..."})
    assert resp.status_code == 200
    assert resp.json() == {"repairedConversation": "我想喝水。"}


def test_empty_conversation_rejected():
    for path in ("/diagnose1", "/diagnose2", "/repair"):
        resp = client.post(path, json={"conversation": "   "})
        assert resp.status_code == 400, f"{path} 应拒绝空对话"


def test_missing_field_returns_422():
    resp = client.post("/diagnose1", json={})
    assert resp.status_code == 422


def test_internal_error_returns_500(monkeypatch):
    def boom(conversation):
        raise RuntimeError("模型加载失败")
    # app.py 在模块顶部 `from diagnose import diagnose1`，引用已绑定到 app 命名空间，
    # 因此需直接 patch app 模块上的名字。
    monkeypatch.setattr(app_module, "diagnose1", boom)
    resp = client.post("/diagnose1", json={"conversation": "任意"})
    assert resp.status_code == 500
