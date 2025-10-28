FROM python:3.12-alpine

ENV PYTHONUNBUFFERED=1

# ===== 1. Системные пакеты =====
RUN apk add --no-cache bash curl unzip jq git ca-certificates alpine-sdk libffi-dev \
    && update-ca-certificates

WORKDIR /app

# ===== 2. Локальные файлы =====
COPY entrypoint.sh /entrypoint.sh
COPY requirements.txt /app/requirements.txt
RUN chmod +x /entrypoint.sh

# ===== 3. Python зависимости =====
RUN pip install --no-cache-dir -r /app/requirements.txt \
    && apk del alpine-sdk libffi-dev
    
# ===== 3.1. Дополнительные Python зависимости =====
RUN pip install --no-cache-dir google protobuf grpcio grpcio-tools grpclib

# ===== 4. Скачиваем официальный Marznode =====
RUN git clone --depth=1 https://github.com/marzneshin/marznode.git /tmp/marznode \
    && cp -r /tmp/marznode/marznode /app/marznode \
    && cp /tmp/marznode/marznode.py /app/marznode.py \
    && cp /tmp/marznode/xray_config.json /app/xray_config.json || true \
    && rm -rf /tmp/marznode

# ===== 5. Ставим Xray-core версии 25.8.3 =====
ARG XRAY_VERSION=25.8.3
ARG XRAY_ARCH=64
RUN curl -fsSL -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip \
    && unzip -o /tmp/xray.zip -d /app \
    && chmod +x /app/xray \
    && rm /tmp/xray.zip \
    && mkdir -p /app/data \
    && curl -fsSL -o /app/data/geoip.dat   https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat \
    && curl -fsSL -o /app/data/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

# ===== 6. Основные ENV =====
ENV SERVICE_PORT=5566 \
    XRAY_EXECUTABLE_PATH=/app/xray \
    XRAY_ASSETS_PATH=/app/data \
    XRAY_CONFIG_PATH=/app/xray_config.json \
    SSL_CLIENT_CERT_FILE=/app/client.pem \
    SSL_KEY_FILE=/app/server.key \
    SSL_CERT_FILE=/app/server.cert \
    CLIENT_PEM_B64="" \
    SERVER_KEY_B64="" \
    SERVER_CERT_B64=""

EXPOSE 5566
ENTRYPOINT ["/entrypoint.sh"]
