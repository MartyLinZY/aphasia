"""
失语症 LLM 微服务 — FastAPI
启动：uvicorn app:app --host 0.0.0.0 --port 8001
"""
import logging

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from diagnose import diagnose1, diagnose2
from repair import repair

logger = logging.getLogger(__name__)

app = FastAPI(title="Aphasia LLM Service")


class ConversationRequest(BaseModel):
    conversation: str


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/diagnose1")
def api_diagnose1(req: ConversationRequest):
    if not req.conversation.strip():
        raise HTTPException(status_code=400, detail="conversation 不能为空")
    try:
        return diagnose1(req.conversation)
    except Exception:
        logger.exception("diagnose1 处理失败")
        raise HTTPException(status_code=500, detail="LLM 服务内部错误")


@app.post("/diagnose2")
def api_diagnose2(req: ConversationRequest):
    if not req.conversation.strip():
        raise HTTPException(status_code=400, detail="conversation 不能为空")
    try:
        perplexity = diagnose2(req.conversation)
        return {"perplexity": perplexity}
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
