#!/bin/sh

# 定义项目目录
PROJECT_DIR=/opt/bilibili-comment
APP_DIR=$PROJECT_DIR/ceshi

echo "开始部署 B站监控（无Docker、无虚拟环境版）..."

# --- 1. 环境准备与代码拉取 ---
apk update
apk add --no-cache git python3 py3-pip tzdata bash

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
mkdir -p $PROJECT_DIR $APP_DIR

if [ ! -d "$APP_DIR/.git" ]; then
    git clone https://github.com/351950505/ceshi.git $APP_DIR
else
    cd $APP_DIR
    git pull
    cd -
fi

# --- 2. 安装 Python 依赖 ---
cd $APP_DIR
pip3 install --no-cache-dir --break-system-packages requests pandas pytz

# --- 3. 清空旧日志 ---
true > bili_monitor.log
chmod 777 bili_monitor.log

# ================== 新增测试环节 ==================
echo "--------------------------------------------------"
echo "开始执行连接测试，验证 Cookie 与 WBI 签名..."
TEST_OUTPUT=$(python3 test_wbi.py 2>&1)
TEST_EXIT_CODE=$?

echo "$TEST_OUTPUT"

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo "❌ 测试脚本执行失败（退出码: $TEST_EXIT_CODE）。"
    echo "部署已中止，请检查 Python 环境和 test_wbi.py 脚本。"
    exit 1
fi

# 通过 Python 解析 JSON 返回结果
TEST_RESULT=$(python3 -c "
import sys, json
try:
    # 假设 test_wbi.py 最后一行输出是 JSON
    last_line = \"$TEST_OUTPUT\".strip().split('\n')[-1]
    data = json.loads(last_line)
    if data.get('code') == 0:
        print('success')
    else:
        print(f'api_error:{data.get(\"code\")}')
except Exception as e:
    print('parse_error')
")

case "$TEST_RESULT" in
    success)
        echo "✅ 测试通过！Cookie 和签名验证成功，即将启动主程序。"
        ;;
    api_error:*)
        ERROR_CODE=${TEST_RESULT#api_error:}
        echo "❌ API 测试失败，返回错误码: $ERROR_CODE。"
        echo "请检查 Cookie 是否有效、服务器时间偏差是否已修正。部署已中止。"
        exit 1
        ;;
    *)
        echo "⚠️ 无法解析测试结果，请手动运行 python3 test_wbi.py 检查。部署已中止。"
        exit 1
        ;;
esac
echo "--------------------------------------------------"
# =================================================

# --- 4. 管理进程并完成部署 ---
pkill -f "python3.*main.py" 2>/dev/null
nohup python3 main.py > bili_monitor.log 2>&1 &

# 设置开机自启
cat > /etc/local.d/bili-monitor.start <<EOF
#!/bin/sh
cd $APP_DIR
nohup python3 main.py > bili_monitor.log 2>&1 &
EOF

chmod +x /etc/local.d/bili-monitor.start
rc-update add local default

echo "部署完成！"
