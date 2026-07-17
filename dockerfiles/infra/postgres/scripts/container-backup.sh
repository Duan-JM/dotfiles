#!/usr/bin/env sh
set -eu

ACTION=${1:-logical}
PGHOST=${PGHOST:-postgres}
PGPORT=${PGPORT:-5432}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

checksum() {
  file=$1
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" > "$file.sha256"
  else
    shasum -a 256 "$file" > "$file.sha256"
  fi
}

logical_backup() {
  : "${DB_NAME:?Set DB_NAME}"
  : "${DB_USER:?Set DB_USER}"
  : "${DB_PASSWORD:?Set DB_PASSWORD}"

  backup_dir=/backups/logical
  retention_days=${BACKUP_RETENTION_DAYS:-14}
  backup_file="$backup_dir/${DB_NAME}_${TIMESTAMP}.dump"
  tmp_file="$backup_file.tmp"

  mkdir -p "$backup_dir"
  PGPASSWORD="$DB_PASSWORD" pg_dump \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -F c \
    -Z 6 \
    -f "$tmp_file"
  mv "$tmp_file" "$backup_file"
  checksum "$backup_file"
  find "$backup_dir" -type f \( -name '*.dump' -o -name '*.dump.sha256' \) -mtime +"$retention_days" -delete
  printf '[%s] logical backup written: %s\n' "$(date -Iseconds)" "$backup_file"
}

base_backup() {
  if [ -z "${REPLICATION_USER:-}" ] || [ -z "${REPLICATION_PASSWORD:-}" ]; then
    printf '[%s] base backup skipped: REPLICATION_USER or REPLICATION_PASSWORD is empty\n' "$(date -Iseconds)"
    return 0
  fi

  backup_dir=/backups/base
  retention_days=${BASEBACKUP_RETENTION_DAYS:-7}
  backup_file="$backup_dir/basebackup_${TIMESTAMP}.tar.gz"
  tmp_file="$backup_file.tmp"

  mkdir -p "$backup_dir"
  PGPASSWORD="$REPLICATION_PASSWORD" pg_basebackup \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$REPLICATION_USER" \
    -D - \
    -F t \
    -z \
    -X stream > "$tmp_file"
  mv "$tmp_file" "$backup_file"
  checksum "$backup_file"
  find "$backup_dir" -type f \( -name 'basebackup_*.tar.gz' -o -name 'basebackup_*.tar.gz.sha256' \) -mtime +"$retention_days" -delete
  printf '[%s] physical base backup written: %s\n' "$(date -Iseconds)" "$backup_file"
}

case "$ACTION" in
  logical)
    logical_backup
    ;;
  base|basebackup)
    base_backup
    ;;
  *)
    printf 'Usage: %s {logical|base}\n' "$0" >&2
    exit 2
    ;;
esac

