# 使用 Python 3.11 Alpine 版本作为基础镜像
FROM python:3.11-alpine

WORKDIR /app

# 安装基础工具和时区
RUN apk add --no-cache bash tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 复制部署脚本目录到容器内
COPY . .

# 安装 Python 依赖
RUN pip install --no-cache-dir requests pandas pytz

# 启动主程序
CMD ["python3", "/app/main.py"]
