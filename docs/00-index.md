# jol-llm Documentation Index

Living documentation for the JOL self-hosted LLM platform on
**llm-prod-lt01**. Every document carries a *Last verified* date; anything
older than 90 days must be re-validated before being relied upon in an
incident.

> **Repository split (2026-08-04)** — deployment assets (Ansible, systemd,
> Caddy, host config, monitoring, scripts) moved to
> [journeyoflife-org/jol-infrastructure](https://github.com/journeyoflife-org/jol-infrastructure).
> Paths like `llm/infra/...` or `llm/scripts/...` in these documents are
> relative to that repository.

## 01 — Architecture

| Document | What you get |
|---|---|
| [system-overview](01-architecture/system-overview.md) | Request data flow, component diagram |
| [network-topology](01-architecture/network-topology.md) | VLANs, firewall zones, mTLS paths |
| [hardware-llm-prod-lt01](01-architecture/hardware-llm-prod-lt01.md) | 3950X, 96 GB RAM, Polaris GPU debt |
| [service-dependencies](01-architecture/service-dependencies.md) | Upstream/downstream contracts |

## 02 — Deployment

| Document | What you get |
|---|---|
| [bare-metal-install](02-deployment/bare-metal-install.md) | Step-by-step build of llm-prod-lt01 |
| [air-gap-procedure](02-deployment/air-gap-procedure.md) | Offline model transfer & verification |
| [gpu-upgrade-roadmap](02-deployment/gpu-upgrade-roadmap.md) | Polaris → RTX 3090/4090 |
| [rollback-procedures](02-deployment/rollback-procedures.md) | Per-service rollback |

## 03 — Security & compliance

| Document | What you get |
|---|---|
| [threat-model](03-security/threat-model.md) | STRIDE for the local LLM stack |
| [compliance-mapping](03-security/compliance-mapping.md) | ISO 27001:2022 Annex A ↔ controls |
| [data-retention-policy](03-security/data-retention-policy.md) | GDPR Art 5(1)(e), 0-day prompt retention |
| [access-control-matrix](03-security/access-control-matrix.md) | Users, service accounts, sudoers |
| [hardening-checklist](03-security/hardening-checklist.md) | Pre-go-live audit checklist |

## 04 — Operations

| Document | What you get |
|---|---|
| [runbooks/](04-operations/runbooks/) | Incident response, model swap, log rotation, cert rotation |
| [monitoring-dashboards](04-operations/monitoring-dashboards.md) | Netdata custom charts |
| [capacity-planning](04-operations/capacity-planning.md) | RAM/CPU thresholds, scaling signals |

## 05 — Models

| Document | What you get |
|---|---|
| [model-registry](05-models/model-registry.md) | Canonical approved model list |
| [quantization-guide](05-models/quantization-guide.md) | Q4_K_M vs Q8_0 decision matrix |
| [benchmark-results](05-models/benchmark-results.md) | tok/sec on 3950X per model |
| [license-compliance](05-models/license-compliance.md) | Model license audit |

## 06 — API

| Document | What you get |
|---|---|
| [openapi-spec.yaml](06-api/openapi-spec.yaml) | OpenAPI 3.1 for `/v1/chat/completions` |
| [authentication](06-api/authentication.md) | API key + OAuth2 Proxy patterns |
| [rate-limiting](06-api/rate-limiting.md) | Per-client token bucket strategy |

## Cross-references

- Compliance artifacts (machine-readable): [`security/`](../security/)
- Runbook-adjacent scripts: [`llm/scripts/` in jol-infrastructure](https://github.com/journeyoflife-org/jol-infrastructure/tree/main/llm/scripts)
- Model supply chain data: [`models/`](../models/)
