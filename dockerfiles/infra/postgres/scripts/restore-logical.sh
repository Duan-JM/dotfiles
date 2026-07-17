#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <backup.dump>\n' "$0" >&2
  exit 2
fi

BACKUP_FILE=$1
if [ ! -f "$BACKUP_FILE" ]; then
  printf 'Backup file not found: %s\n' "$BACKUP_FILE" >&2
  exit 2
fi

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

cat "$BACKUP_FILE" | $COMPOSE exec -T -e PGPASSWORD="$DB_PASSWORD" "$SERVICE" \
  pg_restore -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" --clean --if-exists --no-owner --verbose

