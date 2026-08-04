# Data Retention Policy — LLM Platform

Last verified: 2026-08-04 · Owner: security · Legal basis: GDPR Art. 5(1)(e),
Art. 32 · Review: annual

## Scope

Applies to all data processed by the jol-llm platform (llm-prod-lt01 and
staging equivalents).

## Classes of data

| Class | Definition | Retention | Storage |
|---|---|---|---|
| **Prompt/completion content** | Anything in request/response bodies, including streamed tokens | **0 days** — never written to disk, memory-resident only for request lifetime | RAM only |
| **Request metadata** | Timestamp, correlation ID, hashed client ID, model name, token counts, latency, HTTP status | **90 days** | `/var/log/jol-audit/` → HDD archive (WORM) |
| **Model weights** | Licensed third-party artifacts | Until decommission or license revocation | `/opt/jol/models` + encrypted HDD backup |
| **Host telemetry** | Netdata metrics (no content) | 30 days detail, 1 year hourly | Netdata DB |
| **Security audit (OS)** | auditd records of file/auth events | 90 days + archive | auditd → logrotate → HDD |

## GDPR alignment

- **Art. 5(1)(e) storage limitation**: prompt content has a retention period
  of zero; it is processed ephemerally and cannot be retrieved after the
  response completes.
- **Art. 5(1)(f) integrity & confidentiality**: metadata hashes use
  salted SHA-256; the salt lives in the vault and rotates with API keys.
- **Art. 32 security of processing**: encryption in transit (mTLS), strict
  access control, verified by automated tests.
- **Art. 30 records of processing**: this policy + the system-overview data
  flow constitute the processing record for the LLM processor role.
- **Art. 33/34 breach notification**: any suspected exposure of prompt
  content triggers `runbooks/incident-response.md` §4 immediately (72 h
  clock).

## Technical enforcement

1. The API bridge logs **only** the metadata fields above; the code path
   that formats log records never receives body buffers.
2. Ollama runs with no file-backed history; `OLLAMA_NOPRUNE` unset,
   session state in memory only.
3. `tests/integration/test_compliance_logging.sh` greps audit + journal +
   Caddy access logs for the sentinel prompt from a live test request and
   fails CI/run if it appears anywhere on disk.
4. Crash dumps (core files) are disabled for `ollama-svc`
   (`LimitCORE=0`) so in-flight content cannot reach disk via a crash.

## Erasure & decommissioning

- **Metadata purge**: logrotate `maxage 90`; archive copies deleted after
  1 year unless under legal hold.
- **Decommission**: NVMe crypto-erase (LUKS header wipe) + HDD secure-erase;
  certificate of sanitization filed with the asset register.

## Exceptions

Any exception (e.g., forensic preservation) requires written security +
legal approval, a fixed expiry date, and an entry in the exception register
(vault-managed).
