FROM python:3.11-alpine

WORKDIR /app

RUN apk add --no-cache tzdata bash \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN pip install requests pandas pytz

CMD ["python3", "main.py"]
