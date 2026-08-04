# Hardening Checklist — Pre-Go-Live Audit

Last verified: 2026-08-04 · Owner: security
Must be fully checked (or formally accepted) before any production go-live
or major change. Mirror: weekly Lynis/debsecan cron.

## 1. Network

- [ ] UFW enabled; INPUT default deny; OUTPUT default deny
- [ ] Allowed inbound: 22/tcp (jump host only), 8443/tcp (corp subnets)
- [ ] Allowed outbound: loopback, established/related, DNS + NTP internal only
- [ ] `tests/security/test_egress_blocking.sh` passes
- [ ] `scripts/utils/network-isolation-test.sh` passes
- [ ] No IPv6 routes unless explicitly hardened (IPv6 disabled or firewalled)

## 2. Identity & access

- [ ] SSH: password auth off, root login off, SSH CA configured
- [ ] sudoers matches `access-control-matrix.md` exactly
- [ ] Service accounts shell-locked (`nologin`), no sudo
- [ ] fail2ban active for SSH with 30-min bans
- [ ] Quarterly access recertification ticket open and current

## 3. Services & sandboxing

- [ ] `ollama.service` hardened flags present (`NoNewPrivileges`,
      `ProtectSystem=strict`, `RestrictAddressFamilies`, `LimitCORE=0`)
- [ ] Ollama listens on loopback only (`ss -tlnp` check)
- [ ] Bridge listens on loopback only; key store mode 0600
- [ ] Caddy: mTLS `require_and_verify`, HSTS header, no admin API exposure
- [ ] Unneeded packages purged (no compiler toolchain on prod unless approved)

## 4. Data protection

- [ ] `/opt/jol/models` owned `ollama-svc:ollama-svc`, mode 0750
- [ ] Audit log dir owned `bridge-svc`, mode 0700
- [ ] Log hygiene test passes (no prompt content anywhere)
- [ ] Core dumps disabled for service accounts
- [ ] Backups encrypted at rest on HDD; restore tested this quarter

## 5. Integrity & monitoring

- [ ] AIDE initialized; baseline committed; daily diff cron in place
- [ ] auditd rules from `config/auditd/ollama.rules` loaded (`auditctl -l`)
- [ ] Netdata alerts configured (temp, tok/s floor, queue depth)
- [ ] Health check cron: `health-check.sh` every 5 min via systemd timer
- [ ] Weekly Lynis + debsecan reports archived (90-day retention)

## 6. Supply chain

- [ ] Ollama binary SHA256 matches pinned value in `infra/group_vars/all/vars.yml`
- [ ] All installed models match `models/manifests/*.json` hashes
- [ ] SBOM current (`security/sbom/ollama-sbom.json`)
- [ ] Caddy/Netdata packages from Ubuntu repos only, unattended-upgrades
      limited to security pocket

## 7. Operational readiness

- [ ] Runbooks walked through on staging within the last 30 days
- [ ] Rollback drills performed (Ollama binary + config)
- [ ] Incident response tabletop exercised within 6 months
- [ ] CHANGELOG + docs "Last verified" dates current

## Acceptance

| Item | Name | Role | Date | Signature (ticket) |
|---|---|---|---|---|
| Checklist owner | | security | | |
| Platform approval | | platform-lead | | |
