FROM python:3.12-slim
WORKDIR /app

# 先装依赖（requirements 变了才重装）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 拷服务代码（.dockerignore 已排除 .venv / 缓存 / 数据产物）
COPY . .

EXPOSE 8001
# 0.0.0.0 才能从容器外/其它容器访问；端口与 app.py 默认一致
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8001"]
