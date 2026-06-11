#!/usr/bin/env bash
# 演示种子数据生成器（瘦封装，真正逻辑在 seed.py）
# ------------------------------------------------------------------
# 对【已经跑起来的】后端调真实 API，灌演示套题 + 建医生/患者账号。
#
# 为什么走 API 而不是直接 mongoimport：题目存单独的 question collection、
# 靠 ID 引用，字段名/可能的 _class 也跟前端 JSON 不同；走真实创建路径让
# 后端 mapper 自动对齐，手写 BSON 极易因形状不符静默读不出。
#
# 注意（踩过的坑）：POST /api/exams 只建骨架、不落内嵌题目，题目必须逐个
# POST 到 .../question 端点。这套逻辑都在 seed.py 里。
#
# 用法：
#   docker compose up -d            # 先把 mongo + backend 起来
#   ./seed/seed.sh                  # 幂等：账号已存在自动改登录
#   # 之后做成"开机即演示"的交付包见 seed/README.md
# ------------------------------------------------------------------
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v python3 >/dev/null || { echo "❌ 需要 python3"; exit 1; }
exec python3 "$HERE/seed.py" "$@"
