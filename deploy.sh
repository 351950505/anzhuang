#!/bin/sh

PROJECT_DIR=/opt/bilibili-comment
APP_DIR=$PROJECT_DIR/ceshi

echo "=========================================="
echo "开始部署 B站监控系统（Alpine Linux 无容器版）"
echo "=========================================="

# 1. 环境准备
apk update
apk add --no-cache git python3 py3-pip tzdata bash

# 设置时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 创建目录
mkdir -p $PROJECT_DIR $APP_DIR

# 2. 拉取/更新代码
if [ ! -d "$APP_DIR/.git" ]; then
    echo "首次部署，克隆仓库..."
    git clone https://github.com/351950505/ceshi.git $APP_DIR
else
    echo "更新代码..."
    cd $APP_DIR
    git pull
    cd - > /dev/null
fi

# 3. 安装 Python 依赖
cd $APP_DIR
echo "安装 Python 依赖..."
pip3 install --no-cache-dir --break-system-packages requests pandas pytz

# 4. 清空旧日志
true > bili_monitor.log
chmod 777 bili_monitor.log

# ========== 5. 关键测试环节 ==========
echo "----------------------------------------"
echo "运行 test_wbi.py 验证 Cookie 和 WBI 签名..."

# 执行测试脚本并捕获输出
TEST_OUTPUT=$(python3 test_wbi.py 2>&1)
TEST_EXIT=$?

if [ $TEST_EXIT -ne 0 ]; then
    echo "❌ test_wbi.py 执行失败（退出码 $TEST_EXIT）"
    echo "输出：$TEST_OUTPUT"
    echo "部署中止，请检查 test_wbi.py 是否存在以及 Python 环境。"
    exit 1
fi

# 提取最后一行（假设是 JSON）
LAST_LINE=$(echo "$TEST_OUTPUT" | tail -n1)

# 使用 Python 解析 JSON 中的 code 字段
CODE=$(python3 -c "
import sys, json
try:
    data = json.loads('$LAST_LINE')
    print(data.get('code', -1))
except:
    print(-1)
")

if [ "$CODE" = "0" ]; then
    echo "✅ 测试通过！Cookie 和签名验证成功，将启动监控程序。"
else
    echo "❌ API 测试失败，返回 code=$CODE"
    echo "完整输出：$TEST_OUTPUT"
    echo "请检查 Cookie 是否有效、服务器时间补偿是否正确（当前设置 TIME_OFFSET=-120）。"
    echo "部署已中止。"
    exit 1
fi
echo "----------------------------------------"
# ==========================================

# 6. 停止旧的监控进程
pkill -f "python3.*main.py" 2>/dev/null
echo "已停止旧进程（如有）。"

# 7. 后台启动新监控
nohup python3 main.py > bili_monitor.log 2>&1 &
echo "监控程序已启动，PID=$!"

# 8. 设置开机自启
cat > /etc/local.d/bili-monitor.start <<EOF
#!/bin/sh
cd $APP_DIR
nohup python3 main.py > bili_monitor.log 2>&1 &
EOF

chmod +x /etc/local.d/bili-monitor.start
rc-update add local default

echo "=========================================="
echo "部署完成！监控程序正在后台运行。"
echo "查看实时日志：tail -f $APP_DIR/bili_monitor.log"
echo "=========================================="
