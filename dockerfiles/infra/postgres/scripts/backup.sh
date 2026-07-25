#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

COMPOSE=${COMPOSE:-docker compose}

$COMPOSE exec -T postgres-backup /scripts/container-backup.sh logical
