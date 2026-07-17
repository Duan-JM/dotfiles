#!/usr/bin/env sh
set -eu

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

write_env_var() {
  name=$1
  eval "value=\${$name:-}"
  printf '%s=%s\n' "$name" "$(shell_quote "$value")" >> /runtime/env.sh
}

mkdir -p /runtime /backups/logical /backups/base
: > /runtime/env.sh

for name in \
  TZ PGHOST PGPORT DB_NAME DB_USER DB_PASSWORD \
  REPLICATION_USER REPLICATION_PASSWORD \
  BACKUP_RETENTION_DAYS BASEBACKUP_RETENTION_DAYS
do
  write_env_var "$name"
done

{
  printf 'SHELL=/bin/sh\n'
  printf 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n'
  if [ "${LOGICAL_BACKUP_ENABLED:-true}" = "true" ]; then
    printf '%s . /runtime/env.sh; /scripts/container-backup.sh logical >> /proc/1/fd/1 2>> /proc/1/fd/2\n' "${LOGICAL_BACKUP_CRON:-15 2 * * *}"
  fi
  if [ "${BASEBACKUP_ENABLED:-true}" = "true" ]; then
    printf '%s . /runtime/env.sh; /scripts/container-backup.sh base >> /proc/1/fd/1 2>> /proc/1/fd/2\n' "${BASEBACKUP_CRON:-15 3 * * 0}"
  fi
} > /etc/crontabs/root

if [ "${LOGICAL_BACKUP_ON_START:-false}" = "true" ]; then
  . /runtime/env.sh
  /scripts/container-backup.sh logical
fi

printf 'PostgreSQL backup scheduler started. logical=%s base=%s\n' "${LOGICAL_BACKUP_CRON:-disabled}" "${BASEBACKUP_CRON:-disabled}"
exec crond -f -l 8 -c /etc/crontabs
