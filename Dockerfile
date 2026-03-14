# 使用精简版 Python 镜像
FROM python:3.11-alpine

# 安装必要的编译依赖 (防止安装部分 Python 库时报错)
RUN apk add --no-cache tzdata build-base jpeg-dev zlib-dev git bash

# 设置中国时区
ENV TZ=Asia/Shanghai

# 保证 Python 日志能实时输出，不被缓存
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 每次容器启动时，自动安装挂载进来的 requirements.txt，然后运行 main.py
CMD pip install --no-cache-dir -r requirements.txt && python main.py > bili_monitor.log 2>&1
