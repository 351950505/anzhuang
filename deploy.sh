#!/bin/bash
# -------------------------------
# B站监控 Docker 一键部署脚本
# 区分项目仓库（ceshi.git）和脚本仓库（anzhuang.git）
# 完全自动化
# -------------------------------

PROJECT_DIR=/opt/bilibili-comment
SCRIPT_DIR=$PROJECT_DIR/anzhuang
APP_DIR=$PROJECT_DIR/ceshi
CONTAINER_NAME=bili-monitor
IMAGE_NAME=bili-monitor

# 1️⃣ 安装依赖
apk update
apk add --no-cache python3 py3-pip bash git curl docker tzdata unzip

# 2️⃣ 启动 Docker 服务
service docker start

# 3️⃣ 设置中国时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 4️⃣ 创建目录并设置权限
mkdir -p $SCRIPT_DIR $APP_DIR
chmod 777 $PROJECT_DIR $SCRIPT_DIR $APP_DIR

# 5️⃣ 停止旧容器
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 6
