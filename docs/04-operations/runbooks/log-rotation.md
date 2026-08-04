# Runbook — Log Rotation & Audit Archival

Last verified: 2026-08-04 · Owner: platform-eng

## What rotates where

| Log | Policy source | Cadence | Retention |
|---|---|---|---|
| `/var/log/jol-audit/bridge.log` | `config/logrotate/jol-audit` | daily | 90 days on NVMe, then HDD archive |
| auditd logs | `/etc/logrotate.d/audit` (distro) | weekly | 90 days + archive |
| Caddy access log | systemd journal + file | daily | 30 days |
| journald | `SystemMaxUse=1G` | auto | size-capped |

## Scheduled behavior

`deploy/systemd/logrotate-ollama.timer` runs daily at 03:10:

1. Rotates audit logs (`rotate-logs.sh` wraps logrotate with integrity
   checks).
2. `model-backup.sh`-style rsync moves `*.gz` older than 7 days to
   `/mnt/backup/audit/<yyyy>/<mm>/` on the HDD.
3. Archived files get `chattr +a` (append-only dir semantics where the
   filesystem supports it; WORM target where available).

## Manual rotation

```bash
sudo scripts/maintenance/rotate-logs.sh            # rotate + verify now
sudo scripts/maintenance/rotate-logs.sh --dry-run  # show what would happen
```

Integrity checks performed:

- pre/post `sha256sum` manifest written next to archives,
- archive count vs logrotate state file,
- **content guard**: the live log is scanned for sentinel absence
  (no prompt content) before rotation seals it.

## Restore / e-discovery

```bash
ls /mnt/backup/audit/2026/08/
zcat /mnt/backup/audit/2026/08/bridge.log-20260801.gz | grep <correlation-id>
```

Metadata only — individual prompt content is unrecoverable by design.

## Failure modes

- Timer failed → Netdata alert `log_rotation_failed`; run manually, then
  check disk space (`df -h /var/log`).
- HDD full → alert; purge per retention policy, never extend retention
  ad hoc (data-retention-policy).
