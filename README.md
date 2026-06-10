# 失语症语言康复评估系统

本地开发环境运行指南。三件套结构：

| 目录 | 技术 | 端口 |
|---|---|---|
| `frontend/` | Flutter（Provider 状态管理） | dev server 随机端口 |
| `backend/` | Spring Boot 3.5.14 / Java 17 + MongoDB + Redis | `8080` |
| `LLM/` | Python FastAPI 微服务（诊断 / 修复 / 困惑度） | `8001` |

三件套**跨进程通信**：前端 HTTP 调后端，后端 OkHttp 调 LLM 微服务。开发时同一台机器跑三个独立进程。

---

## 一次性环境准备

### 1. 系统依赖

| 组件 | 推荐版本 | 验证命令 |
|---|---|---|
| JDK | 17 | `java -version` |
| Flutter（含 Dart） | 3.x | `flutter --version` |
| Python | 3.10+ | `python3 --version` |
| MongoDB | 7.0+ | `mongod --version` |
| Redis | 7.2+ | `redis-server --version` |

macOS 一键装：

```bash
brew install openjdk@17 mongodb-community@7.0 redis python@3.12
# Flutter 单独从 https://docs.flutter.dev/get-started/install 装
```

Linux 装 MongoDB 7 / Redis 7 走对应发行版的官方源（参考 mongodb.com / redis.io 文档）。

### 2. 配置 API 凭据

```bash
cp .env.example .env
# 编辑 .env 填入实际值（.env 已 gitignored，密钥不会进 git）
```

`.env.example` 里列了 5 类外部服务密钥，**全部需要自行申请**：

| 变量 | 用途 | 申请地址 |
|---|---|---|
| `LLM_API_KEY` | 阿里 Qwen（翻译、Qwen-Audio 流畅度评分） | <https://dashscope.aliyun.com> |
| `BAIDU_APP_ID/API_KEY/CLIENT_SECRET` | 百度 OCR（手写识别） | <https://ai.baidu.com> |
| `FLYTEK_APP_ID/API_KEY/CLIENT_SECRET` | 讯飞 ASR/TTS（语音识别 / 合成） | <https://www.xfyun.cn> |
| `SILICONFLOW_API_KEY` | SiliconFlow（诊断 / 修复，DeepSeek-V3） | <https://siliconflow.cn> |
| `MONGO_PASSWORD` / `REDIS_PASSWORD` | 本地 Mongo/Redis 凭据 | 自行设置 |
| `JWT_SECRET` | JWT 签名密钥（≥ 32 随机字符） | `openssl rand -hex 32` |

### 3. MongoDB 用户初始化

`application.properties` 默认连 `localhost:27017`，认证用 `${MONGO_USERNAME:zsb}` / `${MONGO_PASSWORD:123456}`。如果本地 Mongo 是空的，先建用户：

```bash
mongosh
use LrNew
db.createUser({ user: "zsb", pwd: "<.env 里 MONGO_PASSWORD 的值>", roles: [{ role: "readWrite", db: "LrNew" }] })
```

或者关掉 Mongo 认证只跑 noauth（不推荐，但能省事）：把 `application.properties` 里 `spring.data.mongodb.username/password` 两行直接注释掉。

> **关于 `/diagnose2`（客观严重度）**：早期用 BERT 困惑度，但经 JiangLin 语料实测，困惑度判失语方向相反（患者重复反而压低困惑度），已废弃。现改为**特征加权分**（`LLM/features.py`，LLM 抽 13 个语言学特征 → 加权严重度分），**无需下载 BERT、无 torch/transformers 依赖**。

### 4. Python 虚拟环境

```bash
cd LLM
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install httpx pytest   # 测试依赖（见 requirements.txt 注释）
```

### 5. Flutter 依赖

```bash
cd frontend
flutter pub get
```

---

## 启动（每次开发要起 5 个东西）

打开 5 个终端按顺序：

### 终端 1：MongoDB

```bash
# macOS
brew services start mongodb-community@7.0
# 或前台跑：mongod --dbpath ~/mongo-data
```

### 终端 2：Redis

```bash
brew services start redis
# 或前台跑：redis-server
```

### 终端 3：LLM 微服务（:8001）

```bash
cd LLM
source .venv/bin/activate
set -a; source ../.env; set +a    # 把 .env 所有变量 export 出去
uvicorn app:app --port 8001
```

### 终端 4：后端（:8080）

```bash
cd backend
set -a; source ../.env; set +a    # Spring Boot 不会自动读 .env，必须先 source
./mvnw spring-boot:run
```

> **非 bash/zsh shell 的 .env 加载方式**
>
> 上面 `set -a; source ../.env; set +a` 只在 bash/zsh 工作（macOS/Linux 默认、Windows WSL/Git Bash 也走 bash 链路）。其他环境：
>
> - **Fish shell**：`for line in (cat ../.env | grep -v '^#' | grep -v '^$'); set -gx (string split -m 1 = $line); end`
> - **Windows PowerShell**：`Get-Content ../.env | ForEach-Object { if ($_ -match '^([^=#]+)=(.*)$') { [Environment]::SetEnvironmentVariable($matches[1], $matches[2]) } }`
> - **IDEA / IntelliJ（跨平台推荐）**：Run Configuration → Environment Variables → 粘贴 `.env` 内容，或勾 "Load environment variables from file" 选 `.env`。这是 Windows 用户最省事的路径，避免 PowerShell 字符串转义坑。

### 终端 5：前端

```bash
cd frontend
flutter run \
  --dart-define=BACKEND_URL=http://localhost:8080 \
  --dart-define=BACKEND_HOST=localhost
```

选目标：Chrome / Edge / 安卓真机 / 安卓模拟器 / Windows 等。iOS/macOS 需要额外配 `audio_record/platform/` 下平台分支，未充分测试。

---

## 跑测试

```bash
# 后端 JUnit（约 330 项）
cd backend && ./mvnw test

# 前端 widget + unit test（约 95 项）
cd frontend && flutter test
flutter analyze   # 静态检查

# LLM pytest（12 项：FastAPI 路由 + siliconflow 客户端）
cd LLM && source .venv/bin/activate && pytest
```

## 端口图

```
27017  MongoDB
 6379  Redis
 8080  Spring Boot 后端
 8001  FastAPI LLM 微服务
随机   Flutter dev server  (CORS 通配 localhost:*)
```

---

## 常见问题

| 症状 | 排查 |
|---|---|
| Spring Boot 启动报 `connection refused 27017` | MongoDB 没起，`brew services start mongodb-community@7.0` |
| Spring Boot 报 `Authentication failed` | `application.properties` 期望 `zsb/123456`（或 .env 里的密码），但本地 Mongo 没建这个用户 → 走第 3 步初始化 |
| 前端按钮点击无响应、控制台 CORS 错误 | `application.properties` 的 `app.cors.allowed-origin-patterns` 默认通配 `localhost:*`；如果 Flutter 跑在别的域名或端口外，加到 `APP_CORS_ALLOWED_ORIGIN_PATTERNS` 环境变量 |
| LLM 调用 500 报 `SILICONFLOW_API_KEY 未配置` | `.env` 里这个 key 没填 / 启动 uvicorn 之前没 `set -a; source ../.env; set +a` |
| `/diagnose2` 报错 / 返回异常 | 现走特征加权分(features.py)，依赖 `SILICONFLOW_API_KEY` + `prompt_features.txt`；不再需要 BERT 模型 |
| 讯飞 ASR 返 401 / 403 | `FLYTEK_*` 三个 key 配错，或讯飞控制台没开 IAT/TTS 接口 |
