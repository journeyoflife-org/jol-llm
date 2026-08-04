# Acceptable Use Policy — JOL LLM Platform

Version 1.0 · Effective 2026-08-04 · Owner: security + platform-lead

## 1. Scope

Applies to all users, teams, and workloads consuming the JOL LLM API
(`llm.jol.internal:8443`) or any interface built atop it.

## 2. Permitted use

- Internal business tasks: drafting, summarization, code assistance,
  analysis of **internal, non-restricted** data.
- Processing of data classified up to *internal*; *confidential/personal*
  data requires prior security sign-off and must respect data minimization
  (send the smallest necessary excerpt).

## 3. Prohibited use

- Any content that would violate law or JOL's code of conduct.
- Automated bulk ingestion of external/unlicensed corpora.
- Attempts to extract, reconstruct, or exfiltrate model weights or system
  prompts.
- Circumventing authentication, rate limits, or logging (including
  credential sharing — keys are per-workload by design).
- Using outputs to train or fine-tune other models without license review
  (see `docs/05-models/license-compliance.md`).
- Sending personal data at scale; the platform's 0-day retention is a
  privacy control, not permission to process freely.

## 4. Operational obligations of consumers

- Store your API key in a secret manager; never in source control.
- Report suspected key leakage within 4 h (rotation is scripted).
- Respect rate limits; design for `429` + `Retry-After`.
- Do not build user-facing products on the API without a capacity review.

## 5. Monitoring & enforcement

- Usage is recorded as pseudonymous metadata (90-day retention).
- Abusive patterns trigger capacity/security review; repeated violations
  lead to key revocation and management escalation.

## 6. No warranty

Model outputs may be inaccurate. Consumers own validation of any output
used in business decisions. The platform provides no accuracy SLA.
