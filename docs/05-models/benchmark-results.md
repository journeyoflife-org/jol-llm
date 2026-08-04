# Benchmark Results — llm-prod-lt01 (AMD 3950X, CPU inference)

Last verified: 2026-08-04 · Method: `scripts/utils/benchmark-model.sh`
(llama-bench-style prompt-processing / generation split, 5 runs, median).

Machine-readable: [`../../models/benchmarks/llm-prod-lt01-results.csv`](../../models/benchmarks/llm-prod-lt01-results.csv)

## Results

| Model | Quant | Threads | Prompt (tok/s) | Generation (tok/s) | Load time (s) | RAM RSS (GiB) |
|---|---|---|---|---|---|---|
| Qwen3-32B | Q8_0 | 32 | ~140 | ~1.4 | ~55 | 36.2 |
| Qwen3-32B | Q4_K_M | 32 | ~250 | ~2.5 | ~35 | 21.8 |
| DeepSeek-R1-Distill-Qwen-32B | Q4_K_M | 32 | ~255 | ~2.6 | ~33 | 21.4 |

## Interpretation

- Generation is memory-bandwidth bound: throughput scales with bytes/weight,
  matching the quantization guide's model (~47 GB/s theoretical bandwidth).
- Prompt processing is compute bound and roughly linear in FLOPs — Q4
  benefits from both fewer bytes and smaller tensors.
- First-token latency for a 512-token prompt ≈ 3.7 s (Q8_0) / 2.1 s (Q4) —
  within the 5 s contract (`docs/01-architecture/service-dependencies.md`).

## Measurement notes

- Governor `performance`, PBO defaults, ambient 23 °C; thermals stable
  (no throttling) during all recorded runs.
- `OLLAMA_NUM_PARALLEL=1`; concurrent generation divides tok/s near-linearly.
- Re-run cadence: after any BIOS/driver/OS kernel change, after GPU
  roadmap changes, and monthly on staging for drift detection.

## Historical

| Date | Change | Effect |
|---|---|---|
| 2026-08-04 | Baseline established (v1.0.0) | — |
