#!/usr/bin/env bash
set -Eeuo pipefail

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SQL

if [[ -n "${REPLICATION_USER:-}" && -n "${REPLICATION_PASSWORD:-}" ]]; then
  psql \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    --set ON_ERROR_STOP=1 \
    --set repl_user="$REPLICATION_USER" \
    --set repl_password="$REPLICATION_PASSWORD" <<'SQL'
SELECT format(
  'CREATE ROLE %I WITH REPLICATION LOGIN PASSWORD %L',
  :'repl_user',
  :'repl_password'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = :'repl_user'
)
\gexec

SELECT format(
  'ALTER ROLE %I WITH REPLICATION LOGIN PASSWORD %L',
  :'repl_user',
  :'repl_password'
)
WHERE EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = :'repl_user'
)
\gexec
SQL
fi

