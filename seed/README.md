# 演示种子数据（换机即演示）

这套种子让**整个流程**（医生登录 → 看套题 / 患者登录 → 答题 → 出诊断报告）
在另一台机器上 `docker compose up` 后就能演示，不用现场手搓套题。

## 里面是什么

| 文件 | 作用 |
|---|---|
| `exam.json` | 演示套题「演示用综合失语测评套题」。源头是 commit `7f8a12c` 删除的 `my_app.dart` 内嵌测试套题，经精选编排（曾以 `demo-data/demo_seed.mongo.js` 直插脚本形式存在，2026-06-11 已合并到这里、统一走 API）。**7 题 + 3 大项**覆盖全部 5 种题型（书写 1 / 选择 2 / 指令 1 / 场景寻物 1 / 录音 2），含 2 条按各大项分数段判失语的诊断规则。 |
| `exam_reliable.json` | 纯后端可靠 4 题（选择/指令/场景寻物），全本地判分、离线可演。 |
| `exam_recovery.json` | 康复版（与 exam.json 同题，`recovery:true`）。做完进「康复记录」tab（显示得分，不显诊断）。 |
| `seed.py` | 种子生成器本体（标准库 urllib，无额外依赖）：建账号 → 建套题骨架 → 逐题写入 → 发布。可选 argv[1] 指定套题文件。 |
| `seed.sh` | `seed.py` 的瘦封装（`exec python3 seed.py`），方便 `./seed/seed.sh` 直接跑。 |
| `restore.sh` | Mongo 首启动自动恢复钩子（配合下面的"交付包"步骤）。 |

## 关键点：图片不用 seed 后端

`exam.json` 里题目图片走的是**前端 asset** 路径 `assets/images/for_question_setting/*`，
这些图随 Flutter bundle 走，已确认全部在仓库里、pubspec 也声明了。
所以这套演示题**不需要**给后端挂 `images/` volume —— 那个 volume 是给"医生现场上传题图"用的，演示题用不到。

## 注意：哪些题需要外部 API key 才能完整作答

题目图片随前端走，但**作答判分**对外部服务的依赖分两类：

- **无需任何 key（一定能演）**：选择题、场景寻物题、指令题的作答判分；答完后的**分数段失语分型 + 结果报告**。
- **需对应 key**：书写题作答 → 百度 OCR（`BAIDU_*`）；录音题作答 → 讯飞 ASR（`FLYTEK_*`）或 Qwen 音频（`LLM_API_KEY`）；`/diagnose2` 客观诊断 → `SILICONFLOW_API_KEY`。

本套题含 1 书写 + 2 录音题，若目标机只配了 SiliconFlow，这 3 题会卡在识别步骤；
要演全 5 题型，需 SiliconFlow + 百度 + 讯飞（或 Qwen）都齐。纯演"选择/寻物/指令 + 分型报告"则无需任何外部 key。

## 用法 A：当场灌（最快，适合本机/已联调的机器）

```bash
docker compose up -d            # 至少把 mongo + backend 起来
./seed/seed.sh                  # 幂等：账号已存在会自动改走登录
```

完成后：
- 医生：`13800000002` / `demo1234`
- 患者：`13800000001` / `demo1234`
- 套题「演示用综合失语测评套题」已发布，患者登录即可选做。

> ⚠️ 账号用**手机号**不是随意字符串：前端登录表单（`login.dart:_validateUsername`）
> 校验 identity 必须匹配中国手机号 `^1[3-9]\d{9}$` 或邮箱，`demo_doctor` 这种会被
> 客户端直接拦下（登不进去），后端其实不挑。

> 可用环境变量覆盖：`BACKEND_URL`（默认 `http://localhost:8080`）、
> `DEMO_DOCTOR/DEMO_DOCTOR_PW/DEMO_PATIENT/DEMO_PATIENT_PW`。

## 用法 B：开机即演示（**已就绪**，推荐给纯净演示机）

**dump 已生成、compose 已挂好**——目标机 `docker compose up` 后库里**自动就有**演示数据，零手动步骤。

- `seed/mongodump/LrNew/` 已含 dump（2 账号 + 2 套题 + 题目，干净无测试结果）；
- `docker-compose.yml` 的 `mongo` 已挂载 dump + `restore.sh` 到 `/docker-entrypoint-initdb.d/`；
- 题目提示语音（讯飞 TTS）烤在**后端镜像** `static/prompts/` 里，随镜像走，不依赖 dump。

**换机步骤**：把整个 `aphasia/`（含 `seed/mongodump/`）拷过去 → 填好 `.env` 的 5 类 key → `docker compose up --build`。
`mongo-data` 为空 → 首启动自动 `mongorestore` → 账号/题库/引用全在；之后再 `up` 已有数据，init 钩子自动跳过。

> **稳定的演示套题 ID**（dump 里的 ObjectId 固定，换机恢复后不变）：
> - 测评·完整 7 题 `6a2abd9795070345cef23e7a`
> - 测评·纯后端可靠 4 题 `6a2abd9795070345cef23e82`
> - 康复·综合训练 7 题 `6a2ac4eac40849fdf6803909`（搜索时类型选「康复」）
>
> 演示账号：医生 `13800000002` / 患者 `13800000001`，密码 `demo1234`。

**要更新种子内容时**（改了 exam.json/诊断规则等）：先 `docker compose down -v` 清库 → `up` → 依次 `./seed/seed.sh exam.json`、`./seed/seed.sh exam_reliable.json`、`./seed/seed.sh exam_recovery.json` →（可选）`mongosh LrNew --eval "db.examResult.deleteMany({})"` 清测试结果 → 重新导出覆盖 dump：
```bash
docker compose exec mongo sh -c 'rm -rf /tmp/seed-dump && mongodump --db LrNew --out /tmp/seed-dump --quiet'
rm -rf seed/mongodump && mkdir -p seed/mongodump
docker compose cp mongo:/tmp/seed-dump/LrNew ./seed/mongodump/LrNew
```

## 为什么不是手写 mongoimport JSON

后端存储形状跟前端 JSON 不一样：
- 题目存在**单独的 `question` collection**，套题里只存题目 **ID 引用**（N+1 预取设计），不是内嵌；
- 字段名不同（API 入参 `recovery`/`published` ↔ 存储 `isRecovery`/`isPublished`、多 `isDisabled`、`ownerId`）；
- 多态判别：诊断规则 `DiagnoseByScoreRange` 虽继承 `DiagnosisRule`，但 DTO/model 全用基类、子类是死代码，落库即基类，**实测不需要 `_class`**。

**⚠️ 关键坑（seed.py 已处理）**：`POST /api/exams` **不持久化内嵌题目**——`ExamMapper` 只取每个 `QuestionDto.getId()` 当引用，id 为 null 就读回成占位「原问题已删除」。所以必须**两步**：先 POST 套题骨架（子项 `questions:[]`，分类/诊断规则会落），再每题 `POST /api/exams/{id}/categories/{ci}/subCategories/{si}/question`（后端 `addQuestion` 才真正建题 + 追加 ID）。`seed.py` 就是这么做的；`mongodump` 出来的即**保证正确**的存储形状，无需人肉对齐 BSON。
