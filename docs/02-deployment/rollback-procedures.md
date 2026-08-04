# Rollback Procedures

Last verified: 2026-08-04 · Owner: platform-eng

General rules:

- Never roll back two components simultaneously; one change, one rollback.
- Before any risky change: `scripts/maintenance/config-backup.sh`
  (git-commits `/etc` state) + `scripts/maintenance/model-backup.sh`.
- Every rollback ends with: `scripts/install/04-post-install-verify.sh`
  and an entry in the incident/change log.

## 1. Ollama binary rollback

`scripts/maintenance/update-ollama.sh` keeps the previous verified binary at
`/opt/jol/releases/ollama-<oldver>` and records it in
`/opt/jol/state/last-known-good.json`.

```bash
sudo systemctl stop ollama
sudo /opt/jol/releases/ollama-<oldver> --version          # sanity
sudo cp /opt/jol/releases/ollama-<oldver> /usr/local/bin/ollama
sudo systemctl start ollama
sudo scripts/install/04-post-install-verify.sh
```

## 2. Configuration rollback (Ansible-managed files)

All `/etc` files we manage are git-tracked by `config-backup.sh`:

```bash
cd /var/lib/jol/etc-git
git log --oneline -- <file>        # find last good commit
sudo git checkout <sha> -- <file>
sudo systemctl restart <affected-unit>
```

Then align the repo source (`config/`, `deploy/`) in a follow-up PR so the
rollback survives the next Ansible run.

## 3. systemd unit rollback (snapshots)

Units are installed from `deploy/systemd/`. Snapshots live in
`/opt/jol/state/unit-snapshots/` (created by the deploy playbook):

```bash
sudo cp /opt/jol/state/unit-snapshots/ollama.service.prev /etc/systemd/system/ollama.service
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## 4. Model rollback

Models are immutable files; rollback = re-register previous model:

```bash
ollama list                                  # identify previous model still on disk
sudo scripts/maintenance/model-backup.sh --restore <model-name>   # if removed
# swap runbook without downtime: see runbooks/model-swap.md
```

If weights are suspected corrupted: re-import from the HDD backup
(`/mnt/backup/models`) after SHA256 check against `models/manifests/`.

## 5. GPU stack rollback (post-RTX upgrade)

```bash
sudo systemctl stop ollama
sudo sed -i 's/^CUDA_VISIBLE_DEVICES=.*/CUDA_VISIBLE_DEVICES=""/' \
  /opt/jol/repos/jol-llm/config/ollama/environment   # or keep file in git
sudo systemctl start ollama        # falls back to CPU inference
```

Driver removal is out-of-scope for emergency rollback (CPU path ignores the
GPU); schedule driver purge in the next maintenance window.

## 6. Caddy / certificate rollback

```bash
sudo cp /opt/jol/state/unit-snapshots/Caddyfile.prev /etc/caddy/Caddyfile
sudo systemctl reload caddy        # reload, not restart, to avoid downtime
```

Bad certificate push: restore previous cert/key from
`/opt/jol/state/tls-backup/` and `systemctl reload caddy`.

## 7. Full host restore (last resort)

1. Re-run [`bare-metal-install.md`](bare-metal-install.md) on fresh disks.
2. Restore models from HDD backup (SHA256-verified).
3. Restore `/etc` git bundle from `/mnt/backup/config`.
4. Rotate all API keys and client certs (assume compromise if the cause was
   security-related — see `runbooks/incident-response.md`).
