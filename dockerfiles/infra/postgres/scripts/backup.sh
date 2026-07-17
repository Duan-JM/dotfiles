#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

: "${DB_NAME:?Set DB_NAME in .env}"
: "${DB_USER:?Set DB_USER in .env}"
: "${DB_PASSWORD:?Set DB_PASSWORD in .env}"

COMPOSE=${COMPOSE:-docker compose}
SERVICE=${POSTGRES_SERVICE:-postgres}
BACKUP_DIR=${BACKUP_DIR:-"$ROOT_DIR/backups/logical"}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-14}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"

mkdir -p "$BACKUP_DIR"

$COMPOSE exec -T -e PGPASSWORD="$DB_PASSWORD" "$SERVICE" \
  pg_dump -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -F c -Z 6 > "$BACKUP_FILE"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
else
  shasum -a 256 "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
fi

find "$BACKUP_DIR" -type f \( -name '*.dump' -o -name '*.dump.sha256' \) -mtime +"$RETENTION_DAYS" -delete

printf 'Logical backup written: %s\n' "$BACKUP_FILE"

