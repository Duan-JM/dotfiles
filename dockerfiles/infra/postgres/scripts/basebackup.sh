#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

: "${REPLICATION_USER:?Set REPLICATION_USER in .env}"
: "${REPLICATION_PASSWORD:?Set REPLICATION_PASSWORD in .env}"

COMPOSE=${COMPOSE:-docker compose}
SERVICE=${POSTGRES_SERVICE:-postgres}
BACKUP_DIR=${BASEBACKUP_DIR:-"$ROOT_DIR/backups/base"}
RETENTION_DAYS=${BASEBACKUP_RETENTION_DAYS:-7}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/basebackup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

$COMPOSE exec -T -e PGPASSWORD="$REPLICATION_PASSWORD" "$SERVICE" \
  pg_basebackup -h 127.0.0.1 -U "$REPLICATION_USER" -D - -F t -z -X stream > "$BACKUP_FILE"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
else
  shasum -a 256 "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
fi

find "$BACKUP_DIR" -type f \( -name 'basebackup_*.tar.gz' -o -name 'basebackup_*.tar.gz.sha256' \) -mtime +"$RETENTION_DAYS" -delete

printf 'Physical base backup written: %s\n' "$BACKUP_FILE"

