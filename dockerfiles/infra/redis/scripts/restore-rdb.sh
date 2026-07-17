#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

COMPOSE=${COMPOSE:-docker compose}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose-single-node.yaml}
DATA_VOLUME=${REDIS_DATA_VOLUME:-infra_redis_data}

compose() {
  $COMPOSE -f "$COMPOSE_FILE" "$@"
}

usage() {
  printf 'Usage: %s <backup.rdb> --force\n' "$0" >&2
}

if [ "$#" -ne 2 ] || [ "$2" != "--force" ]; then
  usage
  printf 'Restore overwrites the Redis data volume. Pass --force to confirm.\n' >&2
  exit 2
fi

backup_file=$1
if [ ! -f "$backup_file" ]; then
  printf 'Backup file not found: %s\n' "$backup_file" >&2
  exit 2
fi

backup_dir=$(CDPATH= cd -- "$(dirname -- "$backup_file")" && pwd)
backup_name=$(basename -- "$backup_file")

if [ -f "$backup_file.sha256" ]; then
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$backup_dir" && sha256sum -c "$backup_name.sha256")
  else
    expected=$(awk '{print $1}' "$backup_file.sha256")
    actual=$(shasum -a 256 "$backup_file" | awk '{print $1}')
    if [ "$expected" != "$actual" ]; then
      printf 'Checksum mismatch for %s\n' "$backup_file" >&2
      exit 1
    fi
  fi
fi

compose stop redis-backup redis >/dev/null 2>&1 || true

docker run --rm \
  -v "$DATA_VOLUME":/data \
  -v "$backup_dir":/restore:ro \
  alpine:3.20 \
  sh -eu -c '
    find /data -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp "/restore/$1" /data/dump.rdb
    chown 999:999 /data/dump.rdb
    chmod 600 /data/dump.rdb
  ' sh "$backup_name"

compose up -d

printf 'Redis data volume restored from: %s\n' "$backup_file"

