#!/bin/sh

PROJECT_DIR=/opt/bilibili-comment
APP_DIR=$PROJECT_DIR/ceshi

echo "开始部署 B站监控（无Docker版）..."

apk update
apk add --no-cache git python3 py3-pip tzdata bash

# 设置上海时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

mkdir -p $PROJECT_DIR $APP_DIR

# 拉取/更新代码
if [ ! -d "$APP_DIR/.git" ]; then
    git clone https://github.com/351950505/ceshi.git $APP_DIR
else
    cd $APP_DIR
    git pull
fi

# 安装依赖（只装需要的，尽量省内存）
cd $APP_DIR
pip3 install --no-cache-dir requests pandas pytz

# 创建日志
touch bili_monitor.log
chmod 777 bili_monitor.log

# 停止旧进程（如果有）
pkill -f "python3.*main.py" 2>/dev/null

# 以后台方式启动（使用 nohup + &）
nohup python3 main.py >> bili_monitor.log 2>&1 &

# 或者更稳：加到开机自启（推荐）
cat > /etc/local.d/bili-monitor.start <<EOF
#!/bin/sh
cd $APP_DIR
nohup python3 main.py >> bili_monitor.log 2>&1 &
EOF

chmod +x /etc/local.d/bili-monitor.start
rc-update add local default

echo "部署完成"
echo "日志查看：tail -f $APP_DIR/bili_monitor.log"
echo "手动重启：pkill -f main.py && cd $APP_DIR && nohup python3 main.py >> bili_monitor.log 2>&1 &"
