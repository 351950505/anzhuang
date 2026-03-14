#!/bin/bash
# -------------------------------
# B站监控 Docker 一键部署脚本
# 区分项目仓库和脚本仓库
# -------------------------------

# 定义路径
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

# 4️⃣ 创建目录
mkdir -p $PROJECT_DIR $SCRIPT_DIR $APP_DIR
chmod 777 $PROJECT_DIR $APP_DIR $SCRIPT_DIR

# 5️⃣ 停止旧容器
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 6️⃣ 拉取项目文件（ceshi.git）
if [ ! -d "$APP_DIR/.git" ]; then
    git clone https://github.com/351950505/ceshi.git $APP_DIR
else
    cd $APP_DIR
    git pull
fi

# 7️⃣ 构建 Docker 镜像
cd $SCRIPT_DIR
docker build -t $IMAGE_NAME .

# 8️⃣ 启动容器
docker run -d \
    --name $CONTAINER_NAME \
    --restart always \
    -v $APP_DIR/bili_monitor.log:/app/bili_monitor.log \
    -v $APP_DIR/bili_cookie.txt:/app/bili_cookie.txt \
    -v $APP_DIR/webhook_config.txt:/app/webhook_config.txt \
    $IMAGE_NAME

echo "B站监控 Docker 已启动，后台运行中"
echo "日志文件：$APP_DIR/bili_monitor.log"
docker ps | grep $CONTAINER_NAME
