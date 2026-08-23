#!/usr/bin/env sh
set -eu

ACTION=${1:-logical}
PGHOST=${PGHOST:-postgres}
PGPORT=${PGPORT:-5432}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_LIST_FILE=
TMP_FILE=
TMP_DIR=

cleanup() {
  if [ -n "$DB_LIST_FILE" ]; then
    rm -f "$DB_LIST_FILE"
  fi
  if [ -n "$TMP_FILE" ]; then
    rm -f "$TMP_FILE"
  fi
  if [ -n "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}

trap cleanup EXIT HUP INT TERM

checksum() {
  file=$1
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" > "$file.sha256"
  else
    shasum -a 256 "$file" > "$file.sha256"
  fi
}

verify_checksum() {
  file=$1
  checksum_file="$file.sha256"

  if [ ! -f "$checksum_file" ]; then
    printf '[%s] skipping invalid physical backup without checksum: %s\n' "$(date -Iseconds)" "$file" >&2
    return 1
  fi

  expected_checksum=$(sed -n '1{s/[[:space:]].*$//;p;}' "$checksum_file")
  if command -v sha256sum >/dev/null 2>&1; then
    actual_checksum=$(sha256sum "$file" | awk '{print $1}')
  else
    actual_checksum=$(shasum -a 256 "$file" | awk '{print $1}')
  fi

  if [ -z "$expected_checksum" ] || [ "$actual_checksum" != "$expected_checksum" ]; then
    printf '[%s] skipping physical backup with invalid checksum: %s\n' "$(date -Iseconds)" "$file" >&2
    return 1
  fi
}

base_backup_start_wal() {
  backup_file=$1

  verify_checksum "$backup_file" || return 1
  if ! backup_label=$(tar -xOzf "$backup_file" ./backup_label 2>/dev/null); then
    printf '[%s] skipping physical backup with unreadable backup_label: %s\n' "$(date -Iseconds)" "$backup_file" >&2
    return 1
  fi

  start_wal=$(printf '%s\n' "$backup_label" | awk '
    /^START WAL LOCATION:/ {
      sub(/^.*\(file /, "")
      sub(/\).*$/, "")
      print
      exit
    }
  ')

  case "$start_wal" in
    ''|*[!0-9A-F]*)
      printf '[%s] skipping physical backup with invalid start WAL: %s\n' "$(date -Iseconds)" "$backup_file" >&2
      return 1
      ;;
  esac

  if [ "${#start_wal}" -ne 24 ]; then
    printf '[%s] skipping physical backup with invalid start WAL: %s\n' "$(date -Iseconds)" "$backup_file" >&2
    return 1
  fi

  printf '%s\n' "$start_wal"
}

cleanup_wal_archive() {
  backup_dir=$1
  archive_dir=/var/lib/postgresql/wal_archive

  if [ ! -d "$archive_dir" ] || [ ! -w "$archive_dir" ]; then
    printf '[%s] WAL archive cleanup failed: archive directory is not writable: %s\n' "$(date -Iseconds)" "$archive_dir" >&2
    return 1
  fi

  if ! command -v pg_archivecleanup >/dev/null 2>&1; then
    printf '[%s] WAL archive cleanup failed: pg_archivecleanup is unavailable\n' "$(date -Iseconds)" >&2
    return 1
  fi

  oldest_backup=
  oldest_start_wal=
  for candidate in $(find "$backup_dir" -maxdepth 1 -type f -name 'basebackup_*.tar.gz' | sort); do
    if candidate_start_wal=$(base_backup_start_wal "$candidate"); then
      oldest_backup=$candidate
      oldest_start_wal=$candidate_start_wal
      break
    fi
  done

  if [ -z "$oldest_backup" ]; then
    printf '[%s] WAL archive cleanup failed: no valid retained physical backup found\n' "$(date -Iseconds)" >&2
    return 1
  fi

  backup_marker=$(find "$archive_dir" -maxdepth 1 -type f -name "${oldest_start_wal}.*.backup" | sort | sed -n '1p')
  if [ -z "$backup_marker" ]; then
    printf '[%s] WAL archive cleanup failed: backup history marker not found for %s\n' "$(date -Iseconds)" "$oldest_backup" >&2
    return 1
  fi

  backup_marker_name=${backup_marker##*/}
  printf '[%s] cleaning archived WAL before %s required by oldest valid backup: %s\n' \
    "$(date -Iseconds)" "$oldest_start_wal" "$oldest_backup"
  pg_archivecleanup "$archive_dir" "$backup_marker_name"
  printf '[%s] WAL archive cleanup completed\n' "$(date -Iseconds)"
}

logical_backup() {
  : "${DB_USER:?Set DB_USER}"
  : "${DB_PASSWORD:?Set DB_PASSWORD}"

  backup_dir=/backups/logical
  retention_days=${BACKUP_RETENTION_DAYS:-7}

  mkdir -p "$backup_dir"
  DB_LIST_FILE=$(mktemp /tmp/postgres-databases.XXXXXX)
  PGPASSWORD="$DB_PASSWORD" psql \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$DB_USER" \
    -d postgres \
    -At \
    -v ON_ERROR_STOP=1 \
    -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn ORDER BY datname;" \
    > "$DB_LIST_FILE"

  if [ ! -s "$DB_LIST_FILE" ]; then
    printf '[%s] logical backup failed: no connectable databases found\n' "$(date -Iseconds)" >&2
    return 1
  fi

  failed=0
  while IFS= read -r database_name; do
    if [ -z "$database_name" ]; then
      continue
    fi

    backup_file="$backup_dir/${database_name}_${TIMESTAMP}.dump"
    TMP_FILE="$backup_file.tmp"
    rm -f "$TMP_FILE"

    printf '[%s] backing up database: %s\n' "$(date -Iseconds)" "$database_name"
    if PGPASSWORD="$DB_PASSWORD" pg_dump \
      -h "$PGHOST" \
      -p "$PGPORT" \
      -U "$DB_USER" \
      -d "$database_name" \
      -F c \
      -Z 6 \
      -f "$TMP_FILE"
    then
      mv "$TMP_FILE" "$backup_file"
      TMP_FILE=
      checksum "$backup_file"
      printf '[%s] logical backup written: %s\n' "$(date -Iseconds)" "$backup_file"
    else
      printf '[%s] logical backup failed: %s\n' "$(date -Iseconds)" "$database_name" >&2
      rm -f "$TMP_FILE"
      TMP_FILE=
      failed=$((failed + 1))
    fi
  done < "$DB_LIST_FILE"

  rm -f "$DB_LIST_FILE"
  DB_LIST_FILE=
  find "$backup_dir" -type f \( -name '*.dump' -o -name '*.dump.sha256' \) -mtime +"$retention_days" -delete

  if [ "$failed" -gt 0 ]; then
    printf '[%s] logical backup completed with %s failure(s)\n' "$(date -Iseconds)" "$failed" >&2
    return 1
  fi
}

base_backup() {
  : "${REPLICATION_USER:?Set REPLICATION_USER}"
  : "${REPLICATION_PASSWORD:?Set REPLICATION_PASSWORD}"

  backup_dir=/backups/base
  retention_days=${BASEBACKUP_RETENTION_DAYS:-7}
  backup_file="$backup_dir/basebackup_${TIMESTAMP}.tar.gz"

  mkdir -p "$backup_dir"
  TMP_DIR=$(mktemp -d "$backup_dir/.basebackup_${TIMESTAMP}.XXXXXX")
  TMP_FILE="$backup_file.tmp"
  rm -f "$TMP_FILE"

  PGPASSWORD="$REPLICATION_PASSWORD" pg_basebackup \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$REPLICATION_USER" \
    -D "$TMP_DIR" \
    -F plain \
    -X stream \
    --checkpoint=fast
  pg_verifybackup "$TMP_DIR"
  tar -C "$TMP_DIR" -czf "$TMP_FILE" .
  rm -rf "$TMP_DIR"
  TMP_DIR=

  mv "$TMP_FILE" "$backup_file"
  TMP_FILE=
  checksum "$backup_file"
  find "$backup_dir" -type f \( -name 'basebackup_*.tar.gz' -o -name 'basebackup_*.tar.gz.sha256' \) -mtime +"$retention_days" -delete
  printf '[%s] physical base backup written: %s\n' "$(date -Iseconds)" "$backup_file"
  cleanup_wal_archive "$backup_dir"
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
