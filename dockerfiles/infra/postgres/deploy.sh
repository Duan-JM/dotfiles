#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

COMPOSE=${COMPOSE:-docker compose}
SERVICE=${POSTGRES_SERVICE:-postgres}

usage() {
  cat <<'EOF'
Usage: ./deploy.sh <command>

Commands:
  start             Start PostgreSQL and wait for healthcheck
  stop              Stop PostgreSQL
  restart           Restart PostgreSQL and wait for healthcheck
  status            Show container and database status
  logs              Follow PostgreSQL logs
  backup-logs       Follow backup scheduler logs
  backup            Create a compressed logical backup
  basebackup        Create a physical base backup with WAL stream
  backup-now        Create a logical backup from the backup container
  basebackup-now    Create a physical base backup from the backup container
  restore <file>    Restore a logical backup created by backup
  reload            Reload postgresql.conf without restart when possible
  psql              Open psql in the configured database
EOF
}

require_db_env() {
  : "${DB_NAME:?Set DB_NAME in .env}"
  : "${DB_USER:?Set DB_USER in .env}"
  : "${DB_PASSWORD:?Set DB_PASSWORD in .env}"
}

wait_healthy() {
  cid=$($COMPOSE ps -q "$SERVICE")
  if [ -z "$cid" ]; then
    printf 'Container for service %s was not created.\n' "$SERVICE" >&2
    exit 1
  fi

  i=0
  while [ "$i" -lt 60 ]; do
    status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid")
    if [ "$status" = "healthy" ]; then
      printf 'PostgreSQL is healthy.\n'
      return 0
    fi
    if [ "$status" = "unhealthy" ]; then
      $COMPOSE logs --tail=80 "$SERVICE" >&2
      exit 1
    fi
    i=$((i + 1))
    sleep 2
  done

  $COMPOSE logs --tail=80 "$SERVICE" >&2
  printf 'Timed out waiting for PostgreSQL healthcheck.\n' >&2
  exit 1
}

case "${1:-help}" in
  start)
    require_db_env
    $COMPOSE up -d
    wait_healthy
    ;;
  stop)
    $COMPOSE down
    ;;
  restart)
    require_db_env
    $COMPOSE up -d
    $COMPOSE restart "$SERVICE"
    wait_healthy
    ;;
  status)
    require_db_env
    $COMPOSE ps
    $COMPOSE exec -T -e PGPASSWORD="$DB_PASSWORD" "$SERVICE" psql \
      -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" \
      -c "SELECT version();" \
      -c "SELECT pg_postmaster_start_time() AS started_at, pg_is_in_recovery() AS standby, current_setting('wal_level') AS wal_level, current_setting('archive_mode') AS archive_mode;"
    ;;
  logs)
    $COMPOSE logs -f "$SERVICE"
    ;;
  backup-logs)
    $COMPOSE logs -f postgres-backup
    ;;
  backup)
    ./scripts/backup.sh
    ;;
  basebackup)
    ./scripts/basebackup.sh
    ;;
  backup-now)
    $COMPOSE exec -T postgres-backup /scripts/container-backup.sh logical
    ;;
  basebackup-now)
    $COMPOSE exec -T postgres-backup /scripts/container-backup.sh base
    ;;
  restore)
    shift
    ./scripts/restore-logical.sh "$@"
    ;;
  reload)
    require_db_env
    $COMPOSE exec -T -e PGPASSWORD="$DB_PASSWORD" "$SERVICE" psql \
      -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" \
      -c "SELECT pg_reload_conf();"
    ;;
  psql)
    require_db_env
    $COMPOSE exec -it -e PGPASSWORD="$DB_PASSWORD" "$SERVICE" psql \
      -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
