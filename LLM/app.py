"""
失语症 LLM 微服务 — FastAPI
启动：uvicorn app:app --host 0.0.0.0 --port 8001
"""
import logging

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from features import diagnose as diagnose_features
from repair import repair

logger = logging.getLogger(__name__)

app = FastAPI(title="Aphasia LLM Service")


class ConversationRequest(BaseModel):
    conversation: str


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/diagnose2")
def api_diagnose2(req: ConversationRequest):
    # 客观特征诊断（特征向量→加权严重度分）。注：旧 /diagnose1（LLM 一锤子判类型）已删除——
    # 实测类型恒输出"Broca"(1/8)、严重度恒"中度"、且误诊一半健康人；患病/严重度由本路提供。
    # 原困惑度实现也已废弃（JiangLin 语料实测方向相反）。端点名暂留 diagnose2 以兼容后端调用。
    if not req.conversation.strip():
        raise HTTPException(status_code=400, detail="conversation 不能为空")
    try:
        return diagnose_features(req.conversation)
    except Exception:
        logger.exception("diagnose2 处理失败")
        raise HTTPException(status_code=500, detail="LLM 服务内部错误")


@app.post("/repair")
def api_repair(req: ConversationRequest):
    if not req.conversation.strip():
        raise HTTPException(status_code=400, detail="conversation 不能为空")
    try:
        return repair(req.conversation)
    except Exception:
        logger.exception("repair 处理失败")
        raise HTTPException(status_code=500, detail="LLM 服务内部错误")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8001, reload=False)
