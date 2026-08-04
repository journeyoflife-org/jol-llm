# Incident Response Policy — LLM Platform

Version 1.0 · Effective 2026-08-04 · Owner: security
Operational runbook: `docs/04-operations/runbooks/incident-response.md`

## 1. Objectives

Restore service safely, preserve evidence, meet GDPR Art. 33 notification
obligations (72 h), and produce auditable records (ISO 27001 A.5.24–A.5.28).

## 2. Severity definitions

| Sev | Definition | Response time |
|---|---|---|
| SEV1 | API outage for all consumers | 30 min engagement |
| SEV2 | Degradation > 50% of baseline, or single-consumer outage | 2 h |
| SEV3 | Security-suspect: integrity, auth bypass, content exposure | Immediate; security leads |

## 3. Roles

- **Incident commander**: platform lead (or delegate) — owns timeline & comms.
- **Security lead**: owns SEV3, containment decisions, breach assessment.
- **Operator**: executes runbook steps, preserves evidence.
- **DPO**: engaged for any suspected personal-data exposure.

## 4. Process

1. **Detect & declare** — any observer may declare; threshold is low.
2. **Contain** — prefer service-level stops over host power-off; isolate at
   the switch only for confirmed intrusion (preserve RAM evidence).
3. **Preserve** — snapshot audit/auditd/journal to forensic HDD before
   restarts. Chain of custody noted in the ticket.
4. **Eradicate & recover** — rebuild-from-known-good preferred over
   in-place fixes; rotate all credentials on SEV3.
5. **Notify** — if personal data plausibly exposed: DPO within 4 h,
   regulator assessment within 72 h per Art. 33.
6. **Post-incident review** — within 5 business days; timeline, root cause,
   action items; policy/runbook updates merged as PRs.

## 5. Drills

- Tabletop exercise: every 6 months.
- Technical drill (model corruption restore + key revocation): annually.
- Drill records: vault `IR-DRILLS` (evidence for A.5.26).

## 6. Communication

Internal channel only; status templates in the runbook; no client names or
content in status messages; external disclosure only via management + legal.
