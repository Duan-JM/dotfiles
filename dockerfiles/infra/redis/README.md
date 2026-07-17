# Redis single-node operations

This directory runs a production-oriented single-node Redis instance with password authentication, AOF/RDB persistence, health checks, Docker log rotation, and container-managed automatic backups.

## Quick start

```sh
cp .env.example .env
vi .env
./deploy.sh start
./deploy.sh status
```

## Operations

```sh
./deploy.sh backup-now   # create an RDB backup immediately
./deploy.sh restore ./backups/rdb/redis_20260717_023000.rdb --force
./deploy.sh backup-logs  # follow backup scheduler logs
./deploy.sh cli          # open redis-cli
./deploy.sh logs         # follow Redis logs
```

Restore stops Redis and the backup sidecar, clears the `infra_redis_data` volume, copies the selected RDB file to `/data/dump.rdb`, then starts Redis again. Because AOF is enabled, the restore script clears old AOF files too; otherwise Redis would prefer the old AOF over the restored RDB.

## Automatic backups

The lightweight `redis-backup` container runs `redis-cli --rdb` on a cron schedule, so it works on macOS and Linux without systemd or host cron.

Defaults:

- RDB backup: every day at 02:30, written to `./backups/rdb`
- retention: 14 days

Tune these in `.env`:

```sh
REDIS_BACKUP_ENABLED=true
REDIS_BACKUP_CRON='30 2 * * *'
REDIS_BACKUP_RETENTION_DAYS=14
```

The `backups` directory is intentionally ignored by Git. Copy or sync it to durable off-host storage if you need disaster recovery.

## Notes

- `FLUSHALL`, `FLUSHDB`, and `CONFIG` are disabled by default to reduce accidental destructive operations.
- The service binds to `127.0.0.1` by default. Change `REDIS_HOST` only when the network is trusted and firewalled.
- Set `maxmemory` and `maxmemory-policy` in `redis.conf` after sizing the host and choosing cache-vs-database semantics.
