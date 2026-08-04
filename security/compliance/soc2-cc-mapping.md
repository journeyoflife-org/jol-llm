# SOC 2 Common Criteria Mapping

Last verified: 2026-08-04 · Owner: security
Scope note: JOL does not pursue SOC 2 attestation for this internal
platform; this mapping exists to align evidence collection with recognized
criteria and to satisfy internal customers requesting SOC 2-style assurance.

## CC6 — Logical and Physical Access Controls

| Criterion | Implementation | Evidence |
|---|---|---|
| CC6.1 Logical access | mTLS + API keys; access matrix | `docs/03-security/access-control-matrix.md` |
| CC6.2 New user provisioning | Scripted issuance; approval ticket | `rotate-api-keys.sh --new` |
| CC6.3 Access removal | Revocation script; CRL SLA ≤ 4 h | cert-rotation runbook |
| CC6.6 Security measures against threats outside boundaries | Air-gap, egress deny, tested | `test_egress_blocking.sh` |
| CC6.7 Data transmission | TLS only; no content persisted | data-retention-policy |

## CC7 — System Operations

| Criterion | Implementation | Evidence |
|---|---|---|
| CC7.1 Monitoring | Netdata + exporter + alerts | `monitoring/` |
| CC7.2 Vulnerability monitoring | Lynis/debsecan weekly; patch window | compliance-scan workflow |
| CC7.3 Security event evaluation | audit-review.sh weekly | review sheets |
| CC7.4 Incident response | IR policy + runbook | `security/policies/` |

## CC8 — Change Management

| Criterion | Implementation | Evidence |
|---|---|---|
| CC8.1 Authorized changes | PRs, CODEOWNERS 2-eyes, CI gates | `.github/` |
| CC8.1 Testing before implementation | staging verification requirement | CONTRIBUTING.md |
| CC8.1 Rollback | per-service rollback procedures | rollback doc |

## CC9 — Risk Mitigation

| Criterion | Implementation | Evidence |
|---|---|---|
| CC9.1 Risk identification | STRIDE threat model | `security/threat-model/` |
| CC9.2 Vendor risk | model/binary supply-chain gates | air-gap procedure |

## Availability (supplementary)

Single-host reality: no HA claims; RTO < 30 min via rollback; RPO ≈ 24 h
(models/config backed up nightly). Consumers accept via onboarding contract.
