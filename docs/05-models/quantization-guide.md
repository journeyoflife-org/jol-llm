# Quantization Guide — Q4_K_M vs Q8_0 Decision Matrix

Last verified: 2026-08-04 · Owner: platform-eng

## TL;DR

On llm-prod-lt01 (memory-bandwidth-bound CPU inference), quantization choice
trades **quality** against **speed + RAM**:

- **Q8_0** ≈ lossless vs FP16 for most tasks; ~2× the bytes of Q4_K_M →
  ~2× slower, ~2× the RAM. Use for the *primary* quality-sensitive model
  when it fits.
- **Q4_K_M** is the best speed/RAM compromise among "acceptable quality"
  quants; ~2× faster on this hardware. Use for secondary models, batch
  workloads, and anything ≥ 70B.

## Decision matrix

| Criterion | Q8_0 | Q4_K_M |
|---|---|---|
| Quality vs FP16 | ~99.5% (negligible loss) | ~97–98% (task-dependent; worst on long-chain reasoning & rare-knowledge recall) |
| Bytes/weight | 8.5 bits | 4.8 bits |
| tok/s on 3950X (32B) | ~1.4 | ~2.5 |
| RAM for 32B class | ~36 GiB | ~21 GiB |
| Largest model that fits lt01 (80 GiB budget) | ~70B class (borderline) | ~120B Q4 dense / 235B MoE (reserved) |
| Recommendation | Primary interactive model | Secondary/batch; fallback under capacity pressure |

## Evaluation requirements before adopting a quant

1. **Benchmark**: `scripts/utils/benchmark-model.sh` on staging; append to
   `models/benchmarks/llm-prod-lt01-results.csv`.
2. **Quality gate**: run the internal eval prompt set (vault-managed) and
   compare against the incumbent model; regressions must be reviewed by the
   consuming teams, not assumed acceptable.
3. **Context/KV check**: KV cache is unaffected by weight quant, but verify
   total RAM at target context length (`docs/04-operations/capacity-planning.md`).

## Rules

- Never serve an unapproved quant variant (no ad-hoc `Q5_K_S` etc.);
  registry admission applies to quant changes too.
- MoE models (e.g. Qwen3-235B-A22B): RAM is governed by *total* weights
  for CPU serving; active-parameter speed advantage applies mainly to GPU.
  Treat 235B A22B Q4 as 128 GiB RAM on this platform.

## llama.cpp quant glossary (reference)

| Quant | Bits | Notes |
|---|---|---|
| Q2_K | 2–3 | Not permitted — quality loss unacceptable |
| Q4_K_M | ~4.8 | Standard compromise |
| Q5_K_M | ~5.7 | Rarely worth the middle ground |
| Q8_0 | 8.5 | Near-lossless |
| FP16 | 16 | Never on CPU host |
