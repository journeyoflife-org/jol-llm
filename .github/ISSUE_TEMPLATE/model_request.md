---
name: Model request
about: Request a new model or quantization for the registry
labels: ["models", "request"]
---

## Requested model

- Name / upstream repo: <!-- e.g. Qwen/Qwen3-32B -->
- Quantization: <!-- e.g. Q4_K_M, Q8_0 -->
- GGUF size: <!-- GiB -->
- Upstream license: <!-- Apache-2.0 / Qwen License / MIT / other -->

## Business justification

<!-- Which internal use case needs it and why existing models do not cover it.
     Keep it factual; this feeds the model governance review. -->

## Hardware fit (see docs/04-operations/capacity-planning.md)

- RAM required (weights + ~15% KV/context overhead): ___ GiB
- Fits within llm-prod-lt01 96 GB alongside current resident model?
  [ ] yes [ ] no → needs HW refresh (gpu-upgrade-roadmap)
- Expected tok/sec on 3950X (estimate or measured): ___

## Compliance pre-check (requester)

- [ ] License reviewed — commercial/internal use permitted
- [ ] No training-data concerns flagged by security
- [ ] Willing to run benchmark (`scripts/utils/benchmark-model.sh`) on staging

## Approval path

Model admission requires: license audit entry in
`docs/05-models/license-compliance.md`, pinned SHA256 manifest, staging
benchmark, and platform-lead sign-off.
