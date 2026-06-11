#!/bin/bash
# Mongo 首启动自动恢复钩子
# ------------------------------------------------------------------
# mongo 官方镜像约定：/docker-entrypoint-initdb.d/ 里的 *.sh 仅在
# 数据目录为空（即 mongo-data volume 首次创建）时执行一次。
# 把本文件挂到该目录、把 dump 挂到 /seed-dump，换机首启动即自动灌库；
# 之后再 up 已有数据，自动跳过，不会重复恢复。
#
# compose 里挂载示例（mongo 服务）：
#   volumes:
#     - mongo-data:/data/db
#     - ./seed/mongodump:/seed-dump:ro
#     - ./seed/restore.sh:/docker-entrypoint-initdb.d/restore.sh:ro
# ------------------------------------------------------------------
set -e
if [ -d /seed-dump ] && [ -n "$(ls -A /seed-dump 2>/dev/null)" ]; then
  echo "[seed] 检测到 /seed-dump，开始 mongorestore ..."
  mongorestore --quiet /seed-dump
  echo "[seed] 恢复完成"
else
  echo "[seed] 无 /seed-dump 或为空，跳过（先跑 seed/seed.sh + mongodump 生成）"
fi
