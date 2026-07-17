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
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose-single-node.yaml}
SERVICE=${REDIS_SERVICE:-redis}

compose() {
  $COMPOSE -f "$COMPOSE_FILE" "$@"
}

usage() {
  cat <<'EOF'
Usage: ./deploy.sh <command>

Commands:
  start         Start Redis and backup scheduler
  stop          Stop Redis
  restart       Restart Redis and wait for healthcheck
  status        Show container and Redis status
  logs          Follow Redis logs
  backup-logs   Follow backup scheduler logs
  backup-now    Create an RDB backup from the backup container
  restore <file> --force
                Restore an RDB backup into the Redis data volume
  cli           Open redis-cli
EOF
}

require_env() {
  : "${REDIS_PORT:?Set REDIS_PORT in .env}"
  : "${REDIS_PASSWORD:?Set REDIS_PASSWORD in .env}"
}

wait_healthy() {
  cid=$(compose ps -q "$SERVICE")
  if [ -z "$cid" ]; then
    printf 'Container for service %s was not created.\n' "$SERVICE" >&2
    exit 1
  fi

  i=0
  while [ "$i" -lt 60 ]; do
    status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid")
    if [ "$status" = "healthy" ]; then
      printf 'Redis is healthy.\n'
      return 0
    fi
    if [ "$status" = "unhealthy" ]; then
      compose logs --tail=80 "$SERVICE" >&2
      exit 1
    fi
    i=$((i + 1))
    sleep 2
  done

  compose logs --tail=80 "$SERVICE" >&2
  printf 'Timed out waiting for Redis healthcheck.\n' >&2
  exit 1
}

case "${1:-help}" in
  start)
    require_env
    compose up -d
    wait_healthy
    ;;
  stop)
    compose down
    ;;
  restart)
    require_env
    compose up -d
    compose restart "$SERVICE"
    wait_healthy
    ;;
  status)
    require_env
    compose ps
    compose exec -T "$SERVICE" redis-cli -a "$REDIS_PASSWORD" --no-auth-warning INFO server persistence stats replication
    ;;
  logs)
    compose logs -f "$SERVICE"
    ;;
  backup-logs)
    compose logs -f redis-backup
    ;;
  backup-now)
    compose exec -T redis-backup /scripts/container-backup.sh
    ;;
  restore)
    shift
    ./scripts/restore-rdb.sh "$@"
    wait_healthy
    ;;
  cli)
    require_env
    compose exec -it "$SERVICE" redis-cli -a "$REDIS_PASSWORD" --no-auth-warning
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
