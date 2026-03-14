#!/bin/bash
# -------------------------------
# B站监控 Docker 一键部署脚本
# 完全自动化，服务器无需手动创建文件
# -------------------------------

PROJECT_DIR=/opt/bilibili-comment/anzhuang
CONTAINER_NAME=bili-monitor
IMAGE_NAME=bili-monitor

# 1️⃣ 安装依赖
apk update
apk add --no-cache python3 py3-pip bash git curl docker tzdata

# 启动 Docker 服务
service docker start

# 设置中国时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 2️⃣ 创建目录并设置权限
mkdir -p $PROJECT_DIR
chmod 777 $PROJECT_DIR

# 3️⃣ 停止旧容器
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 4️⃣ 构建 Docker 镜像
docker build -t $IMAGE_NAME $PROJECT_DIR

# 5️⃣ 启动容器
docker run -d \
    --name $CONTAINER_NAME \
    --restart always \
    -v $PROJECT_DIR/bili_monitor.log:/app/bili_monitor.log \
    $IMAGE_NAME

echo "B站监控 Docker 已启动，后台运行中"
echo "日志文件：$PROJECT_DIR/bili_monitor.log"
docker ps | grep $CONTAINER_NAME
