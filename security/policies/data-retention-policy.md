# Data Retention Policy (normative copy)

Version 1.0 · Effective 2026-08-04 · Owner: security · Review: annual
Canonical documentation copy: `docs/03-security/data-retention-policy.md`
(conflict: this policy document prevails).

## 1. Purpose

Define what the JOL LLM platform may store, for how long, and under which
legal basis, in compliance with GDPR Art. 5(1)(e), Art. 5(1)(f), Art. 32,
and ISO 27001:2022 controls A.5.33/A.5.34.

## 2. Retention schedule

| Data class | Retention | Legal basis | Storage |
|---|---|---|---|
| Prompt/completion content | **0 days** (ephemeral, RAM only) | Legitimate interest limited to transient processing; storage would be disproportionate | None |
| Request metadata (audit) | 90 days + 1-year archive | Legitimate interest (security, capacity accounting) | Audit log → HDD/WORM |
| OS security audit records | 90 days + archive | Legitimate interest / legal obligation | auditd pipeline |
| Model weights | Until decommission | License-bound asset | NVMe + encrypted HDD |
| Host telemetry | 30 days / 1 year aggregate | Legitimate interest | Netdata |

## 3. Prohibitions

- No logging, caching, or sampling of prompt/completion content anywhere in
  the stack (bridge, proxy, runtime, monitoring).
- No debug toggles that persist content may be enabled in production.
- No copies of content in tickets, chat, or documentation (canned test
  strings only).

## 4. Enforcement & verification

- Automated: `tests/integration/test_compliance_logging.sh` (sentinel
  content must not appear in any log) runs in CI and post-deploy.
- Rotations perform a content guard (`scripts/maintenance/rotate-logs.sh`).
- Crash dumps disabled for service accounts (`LimitCORE=0`).

## 5. Erasure

- Automated purge at rotation expiry (logrotate `maxage`).
- On-demand erasure requests: metadata entries are pseudonymous (salted
  hashed client IDs); erasure = salt destruction for the affected client,
  executed within 30 days of a valid request.

## 6. Exceptions

Require written security + legal approval with a fixed expiry; recorded in
the exception register (vault). Forensic holds suspend purge for the scoped
files only.

## 7. Decommissioning

Crypto-erase of LUKS volumes, secure-erase of HDDs, certificate of
sanitization archived. See rollback doc §7.
