#!/bin/bash
# -------------------------------
# B站监控 Docker 一键部署（精简版）
# Alpine Linux / Edge 系统适用
# -------------------------------

PROJECT_DIR=/opt/bilibili-comment

# 安装依赖
apk update
apk add --no-cache python3 py3-pip bash git curl docker tzdata

# 启动 Docker 服务
service docker start

# 设置中国时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 创建目录
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 克隆或更新仓库
if [ ! -d "ceshi" ]; then
    git clone https://github.com/351950505/ceshi.git
else
    cd ceshi
    git pull
    cd ..
fi
cd ceshi

# 创建 Dockerfile
cat > Dockerfile <<'EOF'
FROM python:3.11-alpine
WORKDIR /app
RUN apk add --no-cache bash tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY . .
RUN pip install --no-cache-dir requests pandas pytz
CMD ["python3", "main.py"]
EOF

# 构建 Docker 镜像
docker build -t bili-monitor .

# 停止并删除旧容器
if [ "$(docker ps -aq -f name=bili-monitor)" ]; then
    docker stop bili-monitor
    docker rm bili-monitor
fi

# 启动新容器
docker run -d \
    --name bili-monitor \
    --restart always \
    -v $PROJECT_DIR/ceshi/bili_monitor.log:/app/bili_monitor.log \
    bili-monitor

echo "B站监控 Docker 已启动，后台运行中"
echo "日志文件：$PROJECT_DIR/ceshi/bili_monitor.log"
docker ps | grep bili-monitor