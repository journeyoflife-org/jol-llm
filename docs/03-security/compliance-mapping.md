# ISO 27001:2022 Annex A — Control Mapping

Last verified: 2026-08-04 · Owner: security

Machine-readable evidence index:
[`../../security/compliance/iso27001-mapping.csv`](../../security/compliance/iso27001-mapping.csv).

| Control | Title | Implementation in jol-llm | Evidence |
|---|---|---|---|
| A.5.1 | Policies for information security | `security/policies/` (retention, AUP, IR) | Policy files, review dates |
| A.5.15 | Access control | mTLS + API keys, access-control-matrix | `docs/03-security/access-control-matrix.md`, `scripts/security/rotate-api-keys.sh` |
| A.5.17 | Authentication information | Hashed key store, 90-day rotation, vault for secrets | `rotate-api-keys.sh`, `infra/group_vars/all/vault.yml` |
| A.5.19 | Information security in supplier relationships | Model/binary supply chain verification | `docs/02-deployment/air-gap-procedure.md` |
| A.5.23 | Information security for use of cloud services | n/a — fully on-premises | Statement of applicability note |
| A.5.24–5.28 | Incident management | IR policy + runbook + drill log | `runbooks/incident-response.md`, `security/policies/incident-response-policy.md` |
| A.5.33 | Protection of records | 90-day metadata audit, WORM archive hint | `config/logrotate/jol-audit`, `rotate-logs.sh` |
| A.5.34 | Privacy / GDPR | 0-day prompt retention | `security/policies/data-retention-policy.md`, CI log-hygiene test |
| A.7.13 | Equipment maintenance | SMART monitoring, pre-flight checks | `scripts/install/01-pre-flight.sh` |
| A.8.2 | Privileged access rights | sudoers matrix, no shared root SSH | `access-control-matrix.md` |
| A.8.5 | Secure authentication | SSH CA + certs, fail2ban | `01-os-hardening.yml` |
| A.8.7 | Protection against malware | Minimal install, no external repos on host | Hardening checklist |
| A.8.8 | Management of technical vulnerabilities | Weekly Lynis + debsecan, patching window | `.github/workflows/compliance-scan.yml`, cron evidence |
| A.8.9 | Configuration management | Ansible IaC, unit snapshots, /etc git | `infra/`, `config-backup.sh` |
| A.8.15 | Logging | Metadata-only audit, tamper resistance | `config/auditd/ollama.rules`, T9 mitigations |
| A.8.16 | Monitoring activities | Netdata + alert thresholds | `monitoring/` |
| A.8.22 | Segregation of networks | VLAN 40 isolation, egress deny | `network-topology.md`, `test_egress_blocking.sh` |
| A.8.25 | Secure development life cycle | CI gates, conventional commits, reviews | `CONTRIBUTING.md`, `.github/workflows/` |
| A.8.28 | Secure coding | ShellCheck-enforced, no secrets in CI | `lint-scripts.yml` |

Gap register: see the `notes` column of the CSV for accepted deviations
(currently: A.5.23 n/a; A.8.7 residual — no AV agent on host, compensated by
air-gap + minimal install).
