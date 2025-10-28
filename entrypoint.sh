#!/usr/bin/env bash
set -euo pipefail
cd /app

# 1) Подхватываем .env если есть
if [ -f ".env" ]; then
  export $(grep -v '^\s*#' .env | grep -E '^[A-Za-z_][A-Za-z0-9_]*=' | xargs -d '\n')
fi

# 2) Timeweb может задать PORT
if [ -n "${PORT:-}" ]; then
  export SERVICE_PORT="$PORT"
fi

# 3) Функция для записи base64 → файл
write_b64() {
  local data="${1:-}"
  local file="${2:-}"
  if [ -n "$data" ]; then
    echo "$data" | base64 -d > "$file"
    chmod 600 "$file"
    echo "[entrypoint] wrote ${file}"
  fi
}

# 4) Создаём все сертификаты из переменных
write_b64 "${CLIENT_PEM_B64:-}"  "${SSL_CLIENT_CERT_FILE}"
write_b64 "${SERVER_KEY_B64:-}"  "${SSL_KEY_FILE}"
write_b64 "${SERVER_CERT_B64:-}" "${SSL_CERT_FILE}"

# 5) Проверяем наличие файлов
for f in "${SSL_CLIENT_CERT_FILE}" "${SSL_KEY_FILE}" "${SSL_CERT_FILE}"; do
  if [ ! -s "$f" ]; then
    echo "[entrypoint] ERROR: missing certificate file $f"
    exit 1
  fi
done

# 6) Запуск MarzNode
echo "[entrypoint] Starting MarzNode..."
exec python3 /app/marznode.py
