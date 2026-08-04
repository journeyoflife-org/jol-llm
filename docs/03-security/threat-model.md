# Threat Model — Local LLM Stack (STRIDE)

Last verified: 2026-08-04 · Owner: security · Approver: platform-lead

Detailed analysis: [`../../security/threat-model/stride-analysis.md`](../../security/threat-model/stride-analysis.md).
Attack trees: [`../../security/threat-model/attack-trees/`](../../security/threat-model/attack-trees/).

## Assets

| ID | Asset | Confidentiality | Integrity | Availability |
|---|---|---|---|---|
| A1 | Prompt/completion content (in memory only) | High | Medium | n/a |
| A2 | Model weights (`/opt/jol/models`) | Low | High | Medium |
| A3 | API keys / client certs | High | High | n/a |
| A4 | Audit log (metadata only) | Medium | High | Medium |
| A5 | Inference availability | n/a | n/a | Medium |

## Trust boundaries

TB1 VLAN perimeter (corp → llm-api), TB2 host boundary, TB3 TLS termination
(Caddy → loopback), TB4 app boundary (bridge → Ollama), TB5 supply chain
(kiosk → host), TB6 model runtime boundary (prompt → weights).

## STRIDE summary

| ID | Threat | Cat. | Asset | Likelihood | Impact | Mitigations | Residual |
|---|---|---|---|---|---|---|---|
| T1 | Lateral movement from corp VLAN to LLM host | Spoofing/Elevation | A1–A5 | Medium | High | UFW input deny-by-default; SSH only from jump host; mTLS; no shared creds | Low |
| T2 | Malicious model weights via supply chain | Tampering | A2 | Low | High | Pinned SHA256 + GPG, air-gap procedure, dual-source checksum, AIDE | Low |
| T3 | Compromised upstream publisher key | Spoofing | A2 | Low | High | Dual-source cross-reference in manifest PR, security review of every manifest change | Medium — accepted, reviewed annually |
| T4 | Prompt injection exfiltrating via future tool integrations | Info disclosure | A1 | Medium | Medium | No egress firewall policy; no tool/function-calling connectors approved; reviewed per integration | Low |
| T5 | API key leakage from a client app | Spoofing | A3 | Medium | Medium | Per-client keys, 90-day rotation script, hashed storage, rate limits, audit by hashed ID | Low |
| T6 | Prompt content leaked through logs/crash dumps | Info disclosure | A1 | Medium | High | No-body logging enforced & CI-tested; Ollama crash dumps disabled; tmpfs not used for prompts (memory-only) | Low |
| T7 | DoS via request floods | DoS | A5 | Medium | Medium | Token-bucket rate limits, single-slot semantics, CPU governor; Locust baseline in `tests/load/` | Low |
| T8 | Denial via model RAM exhaustion | DoS | A5 | Low | Medium | `OLLAMA_MAX_LOADED_MODELS=1`, context cap, admission rule in capacity planning | Low |
| T9 | Audit log tampering to hide abuse | Tampering/Repudiation | A4 | Low | High | auditd append-only config, daily rsync to HDD/WORM, `audit-review.sh` anomaly scan | Low |
| T10 | Repudiation of client actions | Repudiation | A4 | Medium | Medium | Correlation IDs bound to hashed client ID + mTLS cert hash in every record | Low |
| T11 | Cleartext exposure on loopback hop | Info disclosure | A1 | Low | Medium | Accepted: loopback never leaves kernel; host compromise supersedes | Medium — accepted |
| T12 | GPU/driver supply chain (post-RTX upgrade) | Tampering | A2 | Low | Medium | Planned: driver bundles SHA256-pinned via kiosk, SBOM entry | n/a until upgrade |

## Out of scope

Physical theft of the NVMe (mitigated elsewhere by facility controls +
disk crypto-erase policy), electromagnetic side channels, and nation-state
memory-residue forensics.

## Review cadence

Re-review on: any new integration, any manifest schema change, hardware
changes (GPU roadmap), or every 12 months — whichever first.
