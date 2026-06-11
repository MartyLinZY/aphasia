# 失语症语言康复评估系统

本地开发环境运行指南。三件套结构：

| 目录 | 技术 | 端口 |
|---|---|---|
| `frontend/` | Flutter（Provider 状态管理） | dev server 随机端口 |
| `backend/` | Spring Boot 3.5.14 / Java 17 + MongoDB + Redis | `8080` |
| `LLM/` | Python FastAPI 微服务（特征诊断 / 修复） | `8001` |

三件套**跨进程通信**：前端 HTTP 调后端，后端 OkHttp 调 LLM 微服务。

---

## 🐳 Docker 一键启动（推荐）

装好 **Docker + Docker Compose** 后，三条命令把全栈（MongoDB + Redis + 后端 + LLM + 前端）跑起来：

```bash
cp .env.example .env        # 填入 5 类外部 API 密钥（见下方表，全部需自行申请）
docker compose up --build   # 首次构建较久（含 Maven / Flutter Web 构建）
```

- 前端：<http://localhost:8088>　后端：<http://localhost:8080>
- MongoDB 走无认证（mongo 端口不对外暴露，仅 docker 网络内可达），无需手动建用户；生产环境请自行加认证。
- 容器间地址自动注入（`MONGO_HOST=mongo` / `REDIS_HOST=redis` / `LLM_SERVICE_URL=http://llm:8001`），`.env` 里这些不用填。
- **仍需填 5 类外部密钥**（SiliconFlow / 讯飞 / 百度 / Qwen），否则诊断/语音/翻译会报错——这是第三方付费服务，绕不开。

```bash
docker compose down         # 停服务（保留 Mongo 数据卷）
docker compose down -v      # 停 + 清空 Mongo 数据（重置）
```

> 不想用 Docker、要本地起裸进程开发，走下面的「一次性环境准备」。

---

## 🎬 演示流程（换机即演示）

演示数据**已打包**进 `seed/mongodump/`，`docker compose up` 后 mongo 首启动会**自动恢复**（2 账号 + 2 套题），零手动步骤。**无需手动建题。**

### 0. 起栈（数据自动就位）

```bash
cp .env.example .env             # 填好 5 类外部 API key
docker compose up --build        # mongo 首启动自动 mongorestore 演示数据
```

> 想自己重灌/改种子：`docker compose down -v` 清库后 `./seed/seed.sh exam.json && ./seed/seed.sh exam_reliable.json`，再重新导出 dump（见 `seed/README.md` 用法 B）。

**演示账号 + 稳定套题 ID**（dump 里固定，换机不变）：

| 角色 | 登录（手机号/邮箱框填） | 密码 |
|---|---|---|
| 患者 | `13800000001` | `demo1234` |
| 医生 | `13800000002` | `demo1234` |

| 套题 | 搜索用 examId |
|---|---|
| 完整 7 题（全题型） | `6a2abd9795070345cef23e7a` |
| 纯后端可靠 4 题 | `6a2abd9795070345cef23e82` |

> ⚠️ **登录名必须是手机号或邮箱**：前端登录表单有客户端校验（`^1[3-9]\d{9}$` 或邮箱正则），
> `demo_doctor` 这类随意字符串会被前端直接拦下，登不进去（后端其实不挑）。

打开 <http://localhost:8088> 开始。底部 3 个 tab 随角色变：
**搜索/套题管理** · **人工智能服务** · **我的（历史）**。

### 1. 患者答题主线（核心）

1. 用 `13800000001 / demo1234` 登录。
2. tab **「搜索」** → 填上面的 examId（如 `6a2abd9795070345cef23e82`）→ 类型选 **「测评」**（**别选康复**）→ **「开始训练」**。
3. 按顺序答 **7 题**，覆盖全部 5 种题型：

   | # | 题型 | 作答方式 | 判分依赖 |
   |---|---|---|---|
   | 1 | 书写·叉子 | 手写"叉子" | 百度 OCR ⚠️ |
   | 2 | 选择·梳子 | 点梳子图 | 纯后端 ✅ |
   | 3 | 选择·球 | 点球图 | 纯后端 ✅ |
   | 4 | 指令·梳子书本 | 先点梳子→放到书本 | 纯后端 ✅ |
   | 5 | 场景寻物·风筝 | 图上点风筝（右上） | 纯后端 ✅ |
   | 6 | 录音·照相机 | 录音说"照相机" | 讯飞/Qwen ⚠️ |
   | 7 | 录音·图片描述 | 录音描述野餐图 | 讯飞/Qwen ⚠️ |

4. 答完最后一题 → 自动跳 **结果页**：各题分、各大项分 + 按诊断规则给出的失语判定。
5. tab **「我的」** → 看到这次历史记录，可回看。

### 2. 医生端套题管理

1. 用 `13800000002 / demo1234` 登录。
2. tab0 = **「套题管理」** → 列表里有「演示用综合失语测评套题」。
3. 点进去演示：三层结构（大项→子项→题目）、7 题编排、评分规则、**诊断规则**、发布开关。
   也可现场新建一套 → 加题 → 发布，演示"医生造题"全过程。

### 3. AI 对话诊断（`/diagnose2`）

> 后端是医生权限（role 2），用 **医生账号** 演。

1. tab **「人工智能服务」** → **「对话诊断」**。
2. 粘贴一段医患对话样本提交 → 返回 是否失语 / 严重度 / 加权分 / 13 个语言学特征 / 证据特征。
   样本（有找词困难、短句、停顿）：
   ```
   医生：请描述一下这张图片。患者：这个…这个…就是…那个人在…在弄那个…我说不上来…就是放那个…天上飞的…线…对，放那个东西。还有那个…小孩…在那边…玩。
   ```
   同页还有 **「语句修复」**（`/repair`）可顺带演示。

### 外部服务依赖与网络

题目**图片随前端走、不依赖网络**，部分**作答判分要连第三方**（key 配齐即可，2026-06-11 已逐个实测全部连通）：

| 环节 | 依赖 | 实测 |
|---|---|---|
| 选择(2/3)/场景寻物(5)/指令(4)、分型报告、结果保存 | 纯后端，无外部依赖 | ✅ |
| `/diagnose2`、`/repair` | SiliconFlow | ✅ ~2–5s |
| 书写题(1)→手写识别 | 百度 OCR | ✅ ~0.1s |
| 录音题(6)→关键词识别 | 讯飞 ASR | ✅ ~1.4s |
| 录音题(7)→流畅度 | Qwen-Audio | ✅ ~1.4s |

> **关于偶发的「评分中，请稍候」卡住**：上述外部调用本身都通。但后端对**百度的两个端点**
> （`handwrite_recognize`、`text_similarity`）**没设超时**（讯飞有 60s、Qwen 快速返回）。
> 所以**只有当代理节点临时失效 / 百度暂时不可达时**，书写题可能卡在"评分中"转圈；
> 网络恢复后重答即可。若要彻底消除这个偶发，给百度调用补 `setConnectTimeout/ReadTimeout`
> 并重建后端镜像（健壮性收尾项，非必需）。
>
> 若演示机用 **Clash/Surge 等 TUN/fake-ip 代理**：容器里这些域名会解析成 `198.18.x.x`，
> 但只要代理节点正常，流量会被正确转发出去（实测百度/讯飞/Qwen 均通）。万一某项不通，
> 可把 `*.baidubce.com`、`*.xfyun.cn`、`dashscope.aliyuncs.com` 在代理里设直连，或换可用节点。

### 重置 / 重复演示

```bash
docker compose down             # 停服务，数据留在 mongo-data 卷（重启不丢，可反复演）
docker compose down -v          # 连数据一起清空，下次要重新 ./seed/seed.sh
```

> 注意：`seed.sh` 每跑一次会**新建**一套套题（不会去重），重复跑会留多套。要干净状态就先 `down -v`。

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
