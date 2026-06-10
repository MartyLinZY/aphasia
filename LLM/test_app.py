"""
FastAPI 微服务路由测试（app.py）。

为避免依赖外部 SiliconFlow API，在导入 app 之前把 features / repair 模块替换为桩，
只验证 FastAPI 的路由、入参校验与响应透传契约。
当前端点：/health、/diagnose2（特征诊断）、/repair。/diagnose1 已删除。
运行：.venv/bin/pytest test_app.py -v
"""
import sys
import types

from fastapi.testclient import TestClient


def _install_stubs():
    # /diagnose2 走 features.diagnose（特征向量→加权严重度分）
    features_stub = types.ModuleType("features")
    features_stub.diagnose = lambda conversation: {
        "hasAphasia": True, "severity": "中度", "score": 4.5,
        "features": {"短而简化": 1}, "evidence": ["短而简化"], "error": "无", "LLManswer": "{}",
    }
    sys.modules["features"] = features_stub

    repair_stub = types.ModuleType("repair")
    repair_stub.repair = lambda conversation: {"repairedConversation": "我想喝水。"}
    sys.modules["repair"] = repair_stub


_install_stubs()
import app as app_module  # noqa: E402

# app 在 import 时已把桩函数(diagnose_features / repair)绑进自身命名空间，之后不再查 sys.modules。
# 这里还原 sys.modules，避免桩污染其它测试模块
# （features 被 test_features_regression 真实 import，残留桩会丢失 APHASIA_THRESHOLD 等）。
for _m in ("features", "repair"):
    sys.modules.pop(_m, None)

client = TestClient(app_module.app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_diagnose2_success():
    resp = client.post("/diagnose2", json={"conversation": "患者：水...喝"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["hasAphasia"] is True
    assert body["severity"] == "中度"
    assert body["score"] == 4.5


def test_repair_success():
    resp = client.post("/repair", json={"conversation": "我...水..."})
    assert resp.status_code == 200
    assert resp.json() == {"repairedConversation": "我想喝水。"}


def test_empty_conversation_rejected():
    for path in ("/diagnose2", "/repair"):
        resp = client.post(path, json={"conversation": "   "})
        assert resp.status_code == 400, f"{path} 应拒绝空对话"


def test_missing_field_returns_422():
    resp = client.post("/diagnose2", json={})
    assert resp.status_code == 422


def test_internal_error_returns_500(monkeypatch):
    def boom(conversation):
        raise RuntimeError("特征抽取失败")
    # app.py 顶部 `from features import diagnose as diagnose_features`，引用已绑到 app 命名空间，
    # 因此直接 patch app 模块上的名字。
    monkeypatch.setattr(app_module, "diagnose_features", boom)
    resp = client.post("/diagnose2", json={"conversation": "任意"})
    assert resp.status_code == 500
