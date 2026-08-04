# Model License Compliance Audit

Last verified: 2026-08-04 · Owner: security · Review: per model admission + annual

License copies: [`../../models/licenses/`](../../models/licenses/).
Canonical source of each model's license: the upstream repository at
download time (recorded in the manifest's `license.source_url`).

## Audit register

| Model | License | SPDX / identifier | Commercial use | Internal use OK | Obligations | Audit date | Auditor |
|---|---|---|---|---|---|---|---|
| Qwen3-32B (+ distills) | Qwen License | Qwen-License | Yes (no MAU threshold concerns at our scale) | Yes | Retain attribution; no use to train competing foundation models; comply with acceptable-use clause | 2026-07-20 | security |
| DeepSeek-R1-Distill-Qwen-32B | MIT | MIT | Yes | Yes | Retain copyright notice (bundled in `models/licenses/`) | 2026-07-20 | security |
| Qwen3-235B-A22B | Qwen License | Qwen-License | Yes | Yes (reserved, not deployed) | Same as Qwen3-32B | 2026-07-20 | security |

## Standing rules

1. **No model is imported before its license row exists here.** The model
   request template enforces this gate.
2. License text is archived at admission time (immutable copy) because
   upstream terms can change; our grant is evaluated at acquisition date.
3. Distilled models inherit obligations from **both** base-model and
   distiller licenses (e.g., DeepSeek-R1-Distill-Qwen carries MIT *and*
   Qwen upstream lineage terms).
4. Output-use restrictions: none of the current models impose output
   ownership restrictions on us; re-check per admission.
5. Annual re-audit verifies no upstream license change materially affects
   our deployment; findings logged below.

## Re-audit log

| Date | Scope | Outcome |
|---|---|---|
| 2026-08-04 | Initial register (v1.0.0) | All compliant |

## Escalation

Any doubt (e.g., upstream license amendment, merger of a licensor) → stop
admission, legal review, platform lead decision, document here.
