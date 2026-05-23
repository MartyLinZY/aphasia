#!/usr/bin/env bash
# 本地开发一键启动：Python LLM 服务 + Spring 后端
# 用法：./start-dev.sh
#
# 前置条件：
#   1. MongoDB / Redis 已本地运行（brew services start mongodb-community redis）
#   2. .env 已配置（SILICONFLOW_API_KEY 至少必填）
#   3. LLM/.venv 已装依赖（参考 LLM/requirements.txt）
#   4. LLM/models/bert-base-chinese/ 已下载（首次约 400MB）

set -e
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "❌ 缺少 .env 文件，请参考 .env.example 创建"
  exit 1
fi

source .env

# === Python LLM 服务 ===
echo "▶ 启动 Python LLM 服务 (port 8001)..."
cd LLM
.venv/bin/uvicorn app:app --host 0.0.0.0 --port 8001 > /tmp/aphasia-llm.log 2>&1 &
LLM_PID=$!
cd ..

# 等待 LLM 服务就绪
for i in {1..10}; do
  sleep 1
  if curl -fs http://localhost:8001/health > /dev/null 2>&1; then
    echo "  ✅ LLM 服务已就绪 (PID $LLM_PID)"
    break
  fi
done
if ! curl -fs http://localhost:8001/health > /dev/null 2>&1; then
  echo "  ❌ LLM 服务启动失败，日志见 /tmp/aphasia-llm.log"
  kill $LLM_PID 2>/dev/null
  exit 1
fi

# === Spring 后端 ===
echo "▶ 启动 Spring 后端 (port 8080)..."
cd backend
trap "echo '\n⏹ 收到退出信号，关闭服务...'; kill $LLM_PID 2>/dev/null; pkill -f spring-boot:run 2>/dev/null; exit 0" INT TERM

./mvnw spring-boot:run
