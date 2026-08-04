# jol-llm — JOL Self-Hosted LLM Platform

> Air-gapped, compliance-grade large language model serving on bare metal.
> ISO 27001:2022-aligned · GDPR Art. 32 · **0-day prompt retention**

![status](https://img.shields.io/badge/status-production-green)
![iso27001](https://img.shields.io/badge/ISO%2027001%3A2022-mapped-blue)
![prompt-retention](https://img.shields.io/badge/prompt%20retention-0%20days-orange)
![egress](https://img.shields.io/badge/egress-blocked-red)

## Executive summary

`jol-llm` is the single source of truth for the JOL on-premises LLM service
running on **llm-prod-lt01** (AMD Ryzen 9 3950X, 96 GB DDR4, Polaris GPU).
It provides:

- **Inference runtime** — Ollama (CPU-first inference, hardened systemd unit)
- **API gateway** — Caddy with mutual TLS + FastAPI auth bridge (API keys)
- **Model governance** — checksummed manifests, license audit, benchmark log
- **Compliance evidence** — STRIDE threat model, ISO 27001 Annex A mapping,
  GDPR Art. 32 checklist, SOC 2 CC mapping
- **Operations** — runbooks, monitoring, backup, rollback, capacity planning
- **Infrastructure as Code** — Ansible playbooks/roles, systemd units, Quadlets

No prompt or completion content is ever written to disk. All telemetry
egress is blocked at the firewall and asserted by automated tests.

## Hardware baseline (llm-prod-lt01)

| Component | Value | Notes |
|---|---|---|
| CPU | AMD Ryzen 9 3950X | 16C/32T, CPU inference primary |
| RAM | 96 GB DDR4-3200 dual-channel | Governs max model size |
| GPU | AMD Polaris (amdgpu) | Technical debt, not used for serving |
| Storage | NVMe (OS+models) + HDD (backups/audit archive) | |
| NIC | 1 GbE, VLAN 40 (llm-api) | No internet egress |

See [`docs/01-architecture/hardware-llm-prod-lt01.md`](docs/01-architecture/hardware-llm-prod-lt01.md)
and the [`docs/02-deployment/gpu-upgrade-roadmap.md`](docs/02-deployment/gpu-upgrade-roadmap.md)
(Polaris → RTX 3090/4090 migration plan).

## Approved model registry

| Model | Quant | Size | Min RAM | Status |
|---|---|---|---|---|
| Qwen3-32B | Q8_0 | ~34 GiB | 48 GB | **Primary, in production** |
| DeepSeek-R1-Distill-Qwen-32B | Q4_K_M | ~20 GiB | 32 GB | Approved, secondary |
| Qwen3-235B-A22B | Q4_K_M | ~128 GiB | 160 GB | Reserved — exceeds lt01 RAM, pending HW refresh |

Canonical metadata (URLs, SHA256, licenses) lives in
[`models/manifests/`](models/manifests/). Benchmark results on the 3950X:
[`models/benchmarks/llm-prod-lt01-results.csv`](models/benchmarks/llm-prod-lt01-results.csv)
and [`docs/05-models/benchmark-results.md`](docs/05-models/benchmark-results.md).

## Quickstart (bare metal, llm-prod-lt01)

```bash
# 1. Pre-flight hardware verification
sudo scripts/install/01-pre-flight.sh

# 2. One-command install (OS hardening, Ollama, Caddy, Netdata, backups)
sudo scripts/install/02-bootstrap.sh

# 3. Air-gapped model import (verifies SHA256 + GPG before install)
sudo scripts/install/03-model-pull.sh qwen3-32b-q8_0

# 4. End-to-end verification (API auth, inference, logging guarantees)
sudo scripts/install/04-post-install-verify.sh
```

Full step-by-step instructions:
[`docs/02-deployment/bare-metal-install.md`](docs/02-deployment/bare-metal-install.md).
Offline model transfer: [`docs/02-deployment/air-gap-procedure.md`](docs/02-deployment/air-gap-procedure.md).

## Repository layout

| Path | Purpose |
|---|---|
| `docs/` | Living documentation (architecture, security, operations, models, API) |
| `infra/` | Ansible IaC (playbooks, roles, inventory, vault) |
| `deploy/` | systemd units, Podman Quadlets, compose, Caddy config |
| `config/` | Service configuration templates (sysctl, auditd, UFW, logrotate) |
| `scripts/` | Idempotent install/maintenance/security/ops scripts |
| `models/` | Model manifests, license copies, benchmark results (no weights) |
| `security/` | Policies, compliance mappings, threat model, SBOM |
| `monitoring/` | Netdata config, custom exporter, dashboards |
| `tests/` | Integration, load, and security verification |

Documentation index: [`docs/00-index.md`](docs/00-index.md).

## Compliance at a glance

- **Prompt data**: never persisted; request/response bodies are stripped
  before any logging path (asserted by `tests/integration/test_compliance_logging.sh`).
- **Retention**: metadata-only audit logs retained 90 days
  ([`config/logrotate/jol-audit`](config/logrotate/jol-audit));
  prompt content retention is **0 days** by design.
- **Evidence pack**: `scripts/maintenance/compliance-report.sh` produces the
  ISO 27001 evidence bundle on demand.
- Mappings: [`security/compliance/iso27001-mapping.csv`](security/compliance/iso27001-mapping.csv),
  [`security/compliance/gdpr-article32-checklist.md`](security/compliance/gdpr-article32-checklist.md),
  [`security/compliance/soc2-cc-mapping.md`](security/compliance/soc2-cc-mapping.md).

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting, the threat model
pointer, and the SBOM. Security-sensitive paths (`/security`, `/infra`,
`/deploy`, `/config`) require two-reviewer approval via
[`.github/CODEOWNERS`](.github/CODEOWNERS).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Conventional Commits are enforced by
a local git hook; ShellCheck-clean shell is enforced in CI.

## License

Proprietary — JOL internal use. See [LICENSE](LICENSE).
Third-party model weights are governed by their own licenses, audited in
[`docs/05-models/license-compliance.md`](docs/05-models/license-compliance.md).
