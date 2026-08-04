# Bare-Metal Install — llm-prod-lt01

Last verified: 2026-08-04 · Owner: platform-eng
Estimated duration: 2.5 h (excluding model import).

> Prerequisite: complete [`hardening-checklist`](../03-security/hardening-checklist.md)
> pre-checks and have the air-gap kiosk media ready.

## 0. Preparation

- [ ] Ubuntu 24.04 LTS Server ISO verified against Canonical's SHA256SUMS
      (on an online machine) and written to install media.
- [ ] BIOS updated, virtualization/AMD-V enabled, secure boot **off**
      (amdgpu + signed-module policy documented separately), boot order
      NVMe-first.
- [ ] Network plan: `10.40.10.21/24`, gw `10.40.10.1`, no external routes.
- [ ] This repository cloned onto the jump host and mirrored to the target
      via git bundle (`git bundle create jol-llm.bundle main`).

## 1. OS installation

1. Minimal server install, LVM optional (we use plain partitions):
   `/` ext4 100 GB, `/opt/jol` ext4 remainder of NVMe, swap **2 GB only**
   (swappiness tuning lives in `config/sysctl/99-llm-performance.conf`).
2. Hostname `llm-prod-lt01`, no cloud-init datasources beyond none/local.
3. Create operator account, lock root SSH, enroll SSH CA per
   [`access-control-matrix`](../03-security/access-control-matrix.md).

## 2. Bootstrap (one command)

```bash
sudo /opt/jol/repos/jol-llm/scripts/install/01-pre-flight.sh   # HW gates
sudo /opt/jol/repos/jol-llm/scripts/install/02-bootstrap.sh     # full stack
```

`02-bootstrap.sh` invokes the Ansible site playbook
(`infra/playbooks/site.yml`) locally and performs, in order:

1. **OS hardening** (`01-os-hardening.yml`): UFW default-deny in/out,
   auditd + `/opt/jol/models` rules, sysctl performance profile, PAM
   limits, fail2ban, AIDE init, unattended security upgrades.
2. **Rootless Podman** (`02-podman-setup.yml`): subuid/subgid, optional
   Quadlet containers (oauth2-proxy, netdata sidecar profiles).
3. **Ollama** (`03-ollama-deploy.yml`): binary install from the kiosk-signed
   bundle, `ollama-svc` system user, hardened unit from
   `deploy/systemd/ollama.service`, environment from
   `config/ollama/environment`.
4. **Reverse proxy** (`04-reverse-proxy.yml`): Caddy + mTLS material from
   the internal CA (see `deploy/caddy/tls/README.md`).
5. **Monitoring** (`05-monitoring.yml`): Netdata + `ollama-metrics.py`
   exporter + alert thresholds.
6. **Backups** (`06-backup-configure.yml`): rsync to HDD, logrotate, cron.

## 3. Model import

Follow [`air-gap-procedure.md`](air-gap-procedure.md). Minimum:
`qwen3-32b-q8_0` (primary).

## 4. Verification

```bash
sudo /opt/jol/repos/jol-llm/scripts/install/04-post-install-verify.sh
```

Pass criteria (script exits non-zero otherwise):

- UFW active, egress test fails-to-connect (expected),
- `ollama --version` matches pinned version in `infra/group_vars/all/vars.yml`,
- `/api/tags` on loopback lists the primary model,
- end-to-end request through `https://10.40.10.21:8443/v1/chat/completions`
  with test mTLS cert + test API key returns 200 in < 60 s,
- audit log contains exactly one metadata-only record for that request,
- `tests/security/test_file_permissions.sh` passes.

## 5. Go-live

- [ ] Run `tests/integration/` + `tests/security/` suites, attach output
      to the go-live ticket.
- [ ] Register host in asset inventory + backup catalog.
- [ ] Announce consumer onboarding window (see
      [`../01-architecture/service-dependencies.md`](../01-architecture/service-dependencies.md)).

## Rollback

Full reinstall is the supported rollback for initial bring-up; per-service
rollbacks for later changes: [`rollback-procedures.md`](rollback-procedures.md).
