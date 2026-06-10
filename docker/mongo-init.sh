#!/bin/bash
# 首次初始化时（mongo 数据卷为空）运行：在 LrNew 库建后端用的读写用户。
# mongo 官方镜像把本脚本放进 /docker-entrypoint-initdb.d 自动执行；
# 此时 root 用户已由 MONGO_INITDB_ROOT_* 创建，用它登录再建 zsb。
set -e

mongosh --host 127.0.0.1 \
  -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin <<EOF
db = db.getSiblingDB('LrNew');
db.createUser({
  user: '${MONGO_USERNAME:-zsb}',
  pwd: '${MONGO_PASSWORD:-123456}',
  roles: [{ role: 'readWrite', db: 'LrNew' }]
});
EOF
