# Model Registry — Canonical Approved List

Last verified: 2026-08-04 · Owner: platform-eng · Approver: security

Machine-readable manifests: [`../../models/manifests/`](../../models/manifests/).
A model is **not usable** until it has: manifest with pinned SHA256, license
audit entry, staging benchmark, and platform-lead approval.

## Approved models

| Registry name | Base model | Quant | Size | Min RAM | tok/s (3950X) | Status | License |
|---|---|---|---|---|---|---|---|
| `qwen3-32b-q8_0` | Qwen3-32B | Q8_0 | 34.1 GiB | 48 GB | ~1.4 | **production (primary)** | Qwen License (audited) |
| `deepseek-r1-distill-qwen-32b` | DeepSeek-R1-Distill-Qwen-32B | Q4_K_M | 19.9 GiB | 32 GB | ~2.6 | approved (secondary, reasoning) | MIT (audited) |
| `qwen3-235b-a22b-q4_k_m` | Qwen3-235B-A22B (MoE) | Q4_K_M | 128 GiB | 160 GB | n/a on lt01 | **reserved** — exceeds lt01 RAM; pending HW refresh | Qwen License (audited) |

## Admission process (new model)

1. Open `model_request` issue (business justification + license pre-check).
2. Security: license audit → entry in
   [`license-compliance.md`](license-compliance.md).
3. Operator: kiosk download, SHA256+GPG verify per
   [`../02-deployment/air-gap-procedure.md`](../02-deployment/air-gap-procedure.md).
4. Staging: import, benchmark (`scripts/utils/benchmark-model.sh`), quality
   spot-check against the primary model.
5. Manifest PR (pinned hash + provenance fields); CODEOWNERS review.
6. Platform-lead sign-off → status flips to `approved`.

## Retirement

Status → `deprecated` in manifest, consumers notified 30 days ahead, then
`ollama rm` + file deletion + backup purge per data-retention policy.

## Naming convention

`<family>-<size>[-<variant>]-<quant>` lowercase, e.g. `qwen3-32b-q8_0`.
Registry names are the API `model` parameter values.
