#!/bin/sh

PROJECT_DIR=/opt/bilibili-comment
APP_DIR=$PROJECT_DIR/ceshi
SCRIPT_DIR=$PROJECT_DIR/anzhuang

IMAGE_NAME=bili-monitor
CONTAINER_NAME=bili-monitor

echo "开始部署 B站监控..."

apk update
apk add --no-cache git docker bash tzdata

service docker start

mkdir -p $PROJECT_DIR
mkdir -p $APP_DIR

# 拉取项目
if [ ! -d "$APP_DIR/.git" ]; then
    git clone https://github.com/351950505/ceshi.git $APP_DIR
else
    cd $APP_DIR
    git pull
fi

# 创建日志文件
touch $APP_DIR/bili_monitor.log
chmod 777 $APP_DIR/bili_monitor.log

# 停止旧容器
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# 构建镜像
cd $SCRIPT_DIR
docker build -t $IMAGE_NAME .

# 运行容器
docker run -d \
--name $CONTAINER_NAME \
--restart always \
-v $APP_DIR:/app \
$IMAGE_NAME

echo ""
echo "部署完成"
echo "日志查看命令："
echo ""
echo "tail -f /opt/bilibili-comment/ceshi/bili_monitor.log"
echo ""
