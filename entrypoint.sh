#!/usr/bin/env bash
set -euo pipefail
cd /app

# 1) Подхватываем .env если он присутствует
if [ -f ".env" ]; then
  export $(grep -v '^\s*#' .env | grep -E '^[A-Za-z_][A-Za-z0-9_]*=' | xargs -d '\n')
fi

# 2) Если Timeweb передаёт PORT — используем его
if [ -n "${PORT:-}" ]; then
  export SERVICE_PORT="$PORT"
fi

# 3) Распаковываем client.pem из base64
if [ -n "${CLIENT_PEM_B64:-}" ]; then
  echo "[entrypoint] Creating client.pem from base64..."
  echo "$CLIENT_PEM_B64" | base64 -d > "${SSL_CLIENT_CERT_FILE}"
  chmod 600 "${SSL_CLIENT_CERT_FILE}"
fi

# 4) Проверяем наличие client.pem
if [ ! -s "${SSL_CLIENT_CERT_FILE}" ]; then
  echo "[entrypoint] ERROR: client.pem отсутствует — задай CLIENT_PEM_B64"
  exit 1
fi

# 5) Запуск MarzNode
echo "[entrypoint] Starting MarzNode..."
exec python3 /app/marznode.py
