# Monitoring Dashboards (Netdata)

Last verified: 2026-08-04 · Owner: platform-eng

## Sources

- **Netdata agent** on llm-prod-lt01 (`19999/tcp`, collector subnet only).
- **Custom exporter**: `monitoring/exporters/ollama-metrics.py` polls
  Ollama `/api/ps`, `/api/tags`, `/api/version` every 10 s and exposes
  Prometheus-format text on `127.0.0.1:9101`; Netdata's prometheus plugin
  ingests it.
- Custom charts: `monitoring/netdata/charts.d/`; alerts:
  `monitoring/netdata/health.d/ollama.conf`.
- Prebuilt overview dashboard export:
  `monitoring/dashboards/llm-prod-lt01-overview.json`.

## Key charts

| Chart | Metric | Normal | Warn |
|---|---|---|---|
| llm.tokens_per_sec | Generation throughput of resident model | ≥ 1.0 tok/s | < 0.7 tok/s 10 min |
| llm.queue_depth | Pending requests at bridge | 0–1 | ≥ 2 sustained 5 min |
| llm.model_resident | 1 if primary model loaded | 1 | 0 for > 2 min |
| llm.request_errors_5xx | Bridge 5xx rate | 0% | > 2% 5 min |
| system.ram | Free GiB | ≥ 45 GiB | < 25 GiB |
| cpu.temperature | 3950X package | ≤ 80 °C | ≥ 88 °C |
| disk.nvme_smart | Reallocated sectors etc. | clean | any growing attribute |

## Alert routing

- Netdata health → local syslog + email alias `llm-alerts@jol.internal`
  (internal SMTP relay; no external services — air-gap).
- SEV mapping in `runbooks/incident-response.md`.

## Dashboard access

- Internal collector renders the overview; direct agent access only from
  the monitoring collector IP (UFW rule).
- Export/import: Netdata UI → dashboards → export JSON → commit to
  `monitoring/dashboards/` on change.
