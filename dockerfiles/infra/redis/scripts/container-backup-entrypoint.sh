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

mkdir -p /runtime /backups/rdb
: > /runtime/env.sh

for name in TZ REDIS_HOST REDIS_PORT REDIS_PASSWORD REDIS_BACKUP_RETENTION_DAYS
do
  write_env_var "$name"
done

{
  printf 'SHELL=/bin/sh\n'
  printf 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n'
  if [ "${REDIS_BACKUP_ENABLED:-true}" = "true" ]; then
    printf '%s . /runtime/env.sh; /scripts/container-backup.sh >> /proc/1/fd/1 2>> /proc/1/fd/2\n' "${REDIS_BACKUP_CRON:-30 2 * * *}"
  fi
} > /etc/crontabs/root

if [ "${REDIS_BACKUP_ON_START:-false}" = "true" ]; then
  . /runtime/env.sh
  /scripts/container-backup.sh
fi

printf 'Redis backup scheduler started. rdb=%s\n' "${REDIS_BACKUP_CRON:-disabled}"
exec crond -f -l 8 -c /etc/crontabs

