#!/bin/sh
# 文件名: deploy.sh

PROJECT_DIR=/opt/bilibili-comment
APP_DIR=$PROJECT_DIR/ceshi
SCRIPT_DIR=$PROJECT_DIR/anzhuang

IMAGE_NAME=bili-monitor
CONTAINER_NAME=bili-monitor

echo "========== 1. 更新系统并安装 Docker =========="
apk update
apk add --no-cache git docker bash tzdata openrc

# Alpine 启动 Docker 的特有方式
rc-update add docker default
rc-service docker start || service docker start

echo "========== 2. 准备目录并拉取最新代码 =========="
mkdir -p $PROJECT_DIR
mkdir -p $APP_DIR
mkdir -p $SCRIPT_DIR

# 拉取或更新安装脚本所在仓库(anzhuang)
if [ ! -d "$SCRIPT_DIR/.git" ]; then
    git clone https://github.com/351950505/anzhuang.git $SCRIPT_DIR
else
    cd $SCRIPT_DIR
    git pull
fi

# 拉取或更新项目本体仓库(ceshi)
if [ ! -d "$APP_DIR/.git" ]; then
    git clone https://github.com/351950505/ceshi.git $APP_DIR
else
    cd $APP_DIR
    git pull
fi

echo "========== 3. 配置日志文件 =========="
touch $APP_DIR/bili_monitor.log
chmod 777 $APP_DIR/bili_monitor.log

echo "========== 4. 重新构建并运行 Docker =========="
# 停止旧容器
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# 进入安装目录构建基础镜像
cd $SCRIPT_DIR
docker build -t $IMAGE_NAME .

# 运行容器，将 ceshi 文件夹挂载到容器的 /app 目录
docker run -d \
--name $CONTAINER_NAME \
--restart always \
-v $APP_DIR:/app \
$IMAGE_NAME

echo ""
echo "部署完成！主程序已在 Docker 后台运行。"
echo "日志查看命令："
echo ""
echo "tail -f /opt/bilibili-comment/ceshi/bili_monitor.log"
echo "或者查看 Docker 日志："
echo "docker logs -f $CONTAINER_NAME"
echo ""
