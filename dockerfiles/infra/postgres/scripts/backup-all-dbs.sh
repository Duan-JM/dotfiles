#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

: "${DB_USER:?Set DB_USER in .env}"
: "${DB_PASSWORD:?Set DB_PASSWORD in .env}"

COMPOSE=${COMPOSE:-docker compose}
SERVICE=${POSTGRES_SERVICE:-postgres}
BACKUP_DIR=${BACKUP_DIR:-"$ROOT_DIR/backups/logical"}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-14}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Get list of all user databases (exclude system databases)
DATABASES=$($COMPOSE exec -T -e PGPASSWORD="$DB_PASSWORD" "$SERVICE" \
  psql -h 127.0.0.1 -U "$DB_USER" -d postgres -t -c \
  "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres') ORDER BY datname;")

if [ -z "$DATABASES" ]; then
  printf 'No user databases found to backup.\n'
  exit 0
fi

FAILED=0
BACKED_UP=0

for DB_NAME in $DATABASES; do
  BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"
  
  printf 'Backing up database: %s\n' "$DB_NAME"
  
  if $COMPOSE exec -T -e PGPASSWORD="$DB_PASSWORD" "$SERVICE" \
    pg_dump -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -F c -Z 6 > "$BACKUP_FILE" 2>/dev/null; then
    
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
    else
      shasum -a 256 "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
    fi
    
    printf '  ✓ Backup written: %s\n' "$BACKUP_FILE"
    BACKED_UP=$((BACKED_UP + 1))
  else
    printf '  ✗ Failed to backup database: %s\n' "$DB_NAME" >&2
    FAILED=$((FAILED + 1))
  fi
done

# Clean up old backups
find "$BACKUP_DIR" -type f \( -name '*.dump' -o -name '*.dump.sha256' \) -mtime +"$RETENTION_DAYS" -delete

printf '\nBackup summary: %d succeeded, %d failed\n' "$BACKED_UP" "$FAILED"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
