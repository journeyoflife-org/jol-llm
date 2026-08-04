# Changelog

All notable changes to `jol-llm` are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versioning rules specific to this repository:

- **MAJOR**: breaking changes to the API surface, model registry schema, or
  network/firewall contract.
- **MINOR**: new models, new runbooks, new monitoring, new Ansible capability
  that is backwards compatible.
- **PATCH**: hardening fixes, documentation, manifest corrections, script fixes.

## [1.0.0] - 2026-08-04

### Added
- Initial production baseline for llm-prod-lt01.
- Ollama deployment via hardened systemd unit (`deploy/systemd/ollama.service`),
  CPU inference, single loaded model, 30-minute keep-alive.
- FastAPI auth bridge (`ollama-api-bridge`) with per-client API keys;
  Caddy mTLS termination on 10.40.10.21:8443.
- Model registry with pinned manifests: Qwen3-32B Q8_0 (primary),
  DeepSeek-R1-Distill-Qwen-32B Q4_K_M (secondary),
  Qwen3-235B-A22B Q4_K_M (reserved, pending hardware refresh).
- Ansible site playbook chain: OS hardening → Podman → Ollama → Caddy →
  Netdata → backups.
- OS hardening baseline: UFW default-deny egress, auditd rules for
  /opt/jol/models, sysctl tuning, PAM/fail2ban, AIDE.
- Monitoring: Netdata with custom Ollama exporter (tokens/s, queue depth,
  model residency) and alert thresholds.
- Compliance artifacts: STRIDE analysis, ISO 27001:2022 Annex A mapping,
  GDPR Article 32 checklist, SOC 2 CC mapping, SBOM.
- Operational scripts: pre-flight, bootstrap, model pull with SHA256+GPG
  verification, post-install verification, health check, backups,
  Ollama safe-update, API key rotation, compliance evidence pack.
- Test suites: integration (auth, inference latency, log hygiene),
  load (Locust), security (egress blocking, file permissions).
- Runbooks: incident response, model swap, log rotation, certificate rotation.

### Security
- 0-day prompt retention asserted by automated test
  (`tests/integration/test_compliance_logging.sh`).
- Two-reviewer CODEOWNERS enforcement for `/security`, `/infra`, `/deploy`,
  `/config`.

## [0.9.0] - 2026-07-15

### Added
- Pre-release pilot on staging hardware (llm-stg-01); runbook drafts.

[1.0.0]: https://git.jol.internal/jol/jol-llm/-/compare/v0.9.0...v1.0.0
[0.9.0]: https://git.jol.internal/jol/jol-llm/-/tags/v0.9.0
