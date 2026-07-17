#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  ALLOW_TARGET_OVERWRITE=yes \
  SOURCE_PGHOST=pg-a SOURCE_PGUSER=postgres SOURCE_PGPASSWORD=secret \
  TARGET_PGHOST=pg-b TARGET_PGUSER=postgres TARGET_PGPASSWORD=secret \
  ./scripts/sync-cluster.sh

Optional variables:
  SOURCE_PGPORT=5432
  TARGET_PGPORT=5432
  SOURCE_MAINTENANCE_DB=postgres
  TARGET_MAINTENANCE_DB=template1
  PG_BIN_DIR=/path/to/version-matched/postgresql/bin

The target databases matching source database names are dropped and recreated.
Roles, role passwords, tablespaces, ownership, and grants are not copied.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "$#" -ne 0 ]]; then
  usage >&2
  exit 2
fi

: "${SOURCE_PGHOST:?Set SOURCE_PGHOST}"
: "${SOURCE_PGUSER:?Set SOURCE_PGUSER}"
: "${SOURCE_PGPASSWORD:?Set SOURCE_PGPASSWORD}"
: "${TARGET_PGHOST:?Set TARGET_PGHOST}"
: "${TARGET_PGUSER:?Set TARGET_PGUSER}"
: "${TARGET_PGPASSWORD:?Set TARGET_PGPASSWORD}"

SOURCE_PGPORT=${SOURCE_PGPORT:-5432}
TARGET_PGPORT=${TARGET_PGPORT:-5432}
SOURCE_MAINTENANCE_DB=${SOURCE_MAINTENANCE_DB:-postgres}
TARGET_MAINTENANCE_DB=${TARGET_MAINTENANCE_DB:-template1}

if [[ "${ALLOW_TARGET_OVERWRITE:-}" != "yes" ]]; then
  printf 'Refusing destructive sync. Set ALLOW_TARGET_OVERWRITE=yes.\n' >&2
  exit 2
fi

if ! command -v psql >/dev/null 2>&1; then
  printf 'Required command not found: psql\n' >&2
  exit 127
fi

source_psql=(
  psql
  --host="$SOURCE_PGHOST"
  --port="$SOURCE_PGPORT"
  --username="$SOURCE_PGUSER"
  --dbname="$SOURCE_MAINTENANCE_DB"
  --no-password
  --set=ON_ERROR_STOP=1
)
target_psql=(
  psql
  --host="$TARGET_PGHOST"
  --port="$TARGET_PGPORT"
  --username="$TARGET_PGUSER"
  --dbname="$TARGET_MAINTENANCE_DB"
  --no-password
  --set=ON_ERROR_STOP=1
)

source_system_id=$(
  PGPASSWORD="$SOURCE_PGPASSWORD" "${source_psql[@]}" --tuples-only --no-align \
    --command='SELECT system_identifier FROM pg_control_system();'
)
target_system_id=$(
  PGPASSWORD="$TARGET_PGPASSWORD" "${target_psql[@]}" --tuples-only --no-align \
    --command='SELECT system_identifier FROM pg_control_system();'
)
source_major=$(
  PGPASSWORD="$SOURCE_PGPASSWORD" "${source_psql[@]}" --tuples-only --no-align \
    --command="SELECT current_setting('server_version_num')::integer / 10000;"
)
target_major=$(
  PGPASSWORD="$TARGET_PGPASSWORD" "${target_psql[@]}" --tuples-only --no-align \
    --command="SELECT current_setting('server_version_num')::integer / 10000;"
)

if [[ "$source_system_id" == "$target_system_id" ]]; then
  printf 'Source and target are the same PostgreSQL cluster; refusing to continue.\n' >&2
  exit 2
fi

if (( source_major > target_major )); then
  printf 'Unsupported downgrade: source PostgreSQL %s, target PostgreSQL %s.\n' \
    "$source_major" "$target_major" >&2
  exit 2
fi

client_dirs=()
if [[ -n "${PG_BIN_DIR:-}" ]]; then
  client_dirs+=("$PG_BIN_DIR")
fi
if command -v pg_dump >/dev/null 2>&1; then
  client_dirs+=("$(dirname "$(command -v pg_dump)")")
fi
client_dirs+=(
  "/opt/homebrew/opt/postgresql@${target_major}/bin"
  "/usr/local/opt/postgresql@${target_major}/bin"
  "/usr/lib/postgresql/${target_major}/bin"
)

client_bin=
for candidate in "${client_dirs[@]}"; do
  if [[ -x "$candidate/pg_dump" ]] &&
     [[ -x "$candidate/pg_restore" ]] &&
     [[ -x "$candidate/dropdb" ]]; then
    candidate_major=$(
      "$candidate/pg_dump" --version |
        sed -E 's/.* ([0-9]+)(\..*)?$/\1/'
    )
    if [[ "$candidate_major" == "$target_major" ]]; then
      client_bin=$candidate
      break
    fi
  fi
done

if [[ -z "$client_bin" ]]; then
  printf 'PostgreSQL %s client tools are required for target PostgreSQL %s.\n' \
    "$target_major" "$target_major" >&2
  printf 'Install them with: brew install postgresql@%s\n' "$target_major" >&2
  printf 'Or set PG_BIN_DIR to the matching PostgreSQL bin directory.\n' >&2
  exit 127
fi

PG_DUMP="$client_bin/pg_dump"
PG_RESTORE="$client_bin/pg_restore"
DROPDB="$client_bin/dropdb"

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/pg-cluster-sync.XXXXXX")
cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

databases=()
while IFS= read -r -d '' database; do
  databases+=("$database")
done < <(
  PGPASSWORD="$SOURCE_PGPASSWORD" "${source_psql[@]}" \
    --tuples-only --no-align --record-separator-zero \
    --command="SELECT datname
               FROM pg_database
               WHERE datallowconn
                 AND NOT datistemplate
               ORDER BY datname;"
)

if [[ "${#databases[@]}" -eq 0 ]]; then
  printf 'No connectable non-template databases found on the source.\n' >&2
  exit 1
fi

printf 'Exporting %d database(s) from %s:%s...\n' \
  "${#databases[@]}" "$SOURCE_PGHOST" "$SOURCE_PGPORT"

for index in "${!databases[@]}"; do
  database=${databases[$index]}
  printf '  dump %q\n' "$database"
  PGPASSWORD="$SOURCE_PGPASSWORD" "$PG_DUMP" \
    --host="$SOURCE_PGHOST" \
    --port="$SOURCE_PGPORT" \
    --username="$SOURCE_PGUSER" \
    --dbname="$database" \
    --no-password \
    --format=custom \
    --create \
    --file="$work_dir/database-$index.dump"
done

printf 'Replacing matching databases on %s:%s...\n' \
  "$TARGET_PGHOST" "$TARGET_PGPORT"

for index in "${!databases[@]}"; do
  database=${databases[$index]}
  printf '  restore %q\n' "$database"

  PGPASSWORD="$TARGET_PGPASSWORD" "$DROPDB" \
    --host="$TARGET_PGHOST" \
    --port="$TARGET_PGPORT" \
    --username="$TARGET_PGUSER" \
    --maintenance-db="$TARGET_MAINTENANCE_DB" \
    --no-password \
    --if-exists \
    --force \
    "$database"

  PGPASSWORD="$TARGET_PGPASSWORD" "$PG_RESTORE" \
    --host="$TARGET_PGHOST" \
    --port="$TARGET_PGPORT" \
    --username="$TARGET_PGUSER" \
    --dbname="$TARGET_MAINTENANCE_DB" \
    --no-password \
    --exit-on-error \
    --create \
    --no-owner \
    --no-privileges \
    "$work_dir/database-$index.dump"
done

printf 'Sync completed: %d database(s) copied.\n' "${#databases[@]}"
