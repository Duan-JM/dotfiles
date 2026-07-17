#!/usr/bin/env sh
set -eu

: "${REDIS_HOST:=redis}"
: "${REDIS_PORT:=6379}"
: "${REDIS_PASSWORD:?Set REDIS_PASSWORD}"

backup_dir=/backups/rdb
retention_days=${REDIS_BACKUP_RETENTION_DAYS:-14}
timestamp=$(date +%Y%m%d_%H%M%S)
backup_file="$backup_dir/redis_${timestamp}.rdb"
tmp_file="$backup_file.tmp"

mkdir -p "$backup_dir"

redis-cli \
  -h "$REDIS_HOST" \
  -p "$REDIS_PORT" \
  -a "$REDIS_PASSWORD" \
  --no-auth-warning \
  --rdb "$tmp_file"

mv "$tmp_file" "$backup_file"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$backup_file" > "$backup_file.sha256"
else
  shasum -a 256 "$backup_file" > "$backup_file.sha256"
fi

find "$backup_dir" -type f \( -name '*.rdb' -o -name '*.rdb.sha256' \) -mtime +"$retention_days" -delete

printf '[%s] Redis RDB backup written: %s\n' "$(date -Iseconds)" "$backup_file"

