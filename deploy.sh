#!/bin/sh

PROJECT_DIR=/opt/bilibili-comment
APP_DIR=$PROJECT_DIR/ceshi

echo "开始部署 B站监控（无Docker、无虚拟环境版）..."

# 更新系统并安装必要包
apk update
apk add --no-cache git python3 py3-pip tzdata bash

# 设置上海时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 创建目录
mkdir -p $PROJECT_DIR $APP_DIR

# 拉取/更新代码
if [ ! -d "$APP_DIR/.git" ]; then
    git clone https://github.com/351950505/ceshi.git $APP_DIR
else
    cd $APP_DIR
    git pull
fi

# 安装依赖（使用 --break-system-packages 绕过 Alpine 限制）
cd $APP_DIR
pip3 install --no-cache-dir --break-system-packages requests pandas pytz

# 创建日志文件
touch bili_monitor.log
chmod 777 bili_monitor.log

# 停止旧进程
pkill -f "python3.*main.py" 2>/dev/null

# 后台启动
nohup python3 main.py >> bili_monitor.log 2>&1 &

# 设置开机自启
cat > /etc/local.d/bili-monitor.start <<EOF
#!/bin/sh
cd $APP_DIR
nohup python3 main.py >> bili_monitor.log 2>&1 &
EOF

chmod +x /etc/local.d/bili-monitor.start
rc-update add local default

echo "部署完成！"
echo "日志查看命令： tail -f $APP_DIR/bili_monitor.log"
echo "手动重启命令： pkill -f main.py && cd $APP_DIR && nohup python3 main.py >> bili_monitor.log 2>&1 &"
