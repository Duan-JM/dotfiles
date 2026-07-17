# PostgreSQL one-click operations

This directory runs a production-oriented single-primary PostgreSQL instance with WAL archiving, streaming-replication readiness, health checks, backup scripts, and safe Docker log rotation.

## Quick start

```sh
cp .env.example .env
vi .env
./deploy.sh start
./deploy.sh status
```

## Operations

```sh
./deploy.sh backup              # compressed pg_dump backup
./deploy.sh basebackup          # physical base backup with WAL stream
./deploy.sh backup-now          # logical backup from the backup sidecar
./deploy.sh basebackup-now      # physical backup from the backup sidecar
./deploy.sh restore <file.dump> # restore a logical backup
./deploy.sh reload              # reload postgresql.conf
./deploy.sh logs                # follow logs
./deploy.sh backup-logs         # follow backup scheduler logs
```

## Automatic backups

Automatic backups are managed by the lightweight `postgres-backup` container, so the same setup works on macOS and Linux without systemd or host cron.

Defaults:

- logical backup: every day at 02:15, written to `./backups/logical`
- physical base backup: every Sunday at 03:15, written to `./backups/base`
- retention: logical backups 14 days, base backups 7 days

Tune these in `.env`:

```sh
LOGICAL_BACKUP_ENABLED=true
LOGICAL_BACKUP_CRON='15 2 * * *'
BASEBACKUP_ENABLED=true
BASEBACKUP_CRON='15 3 * * 0'
BACKUP_RETENTION_DAYS=14
BASEBACKUP_RETENTION_DAYS=7
```

Use `./deploy.sh backup-logs` to inspect scheduled backup runs. The `backups` directory is intentionally ignored by Git.

## Enterprise features enabled

- WAL and PITR foundation: `wal_level=replica`, `archive_mode=on`, WAL compression, WAL retention, replication slots, and WAL sender capacity.
- Replication readiness: set `REPLICATION_USER` and `REPLICATION_PASSWORD` before first initialization to create a replication role.
- Observability: `pg_stat_statements`, slow-query logging, checkpoint/connection/disconnection/lock-wait logs, WAL I/O timing, and query I/O timing.
- Reliability: fsync, full-page writes, synchronous commit, safer checkpoints, health checks, graceful stop window, and Docker log rotation.
- Maintenance: tuned autovacuum defaults and one-command logical and physical backups with checksum files and retention cleanup.

Before exposing PostgreSQL outside a trusted private network, restrict `config/pg_hba.conf` to specific client CIDRs and firewall the published port.

WAL archive files are stored in the `infra_postgres_wal_archive` Docker volume. Copy or sync that volume to durable off-host storage if you need real disaster recovery.
