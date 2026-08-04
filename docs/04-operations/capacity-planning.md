# Capacity Planning

Last verified: 2026-08-04 · Owner: platform-eng

## Current headroom (llm-prod-lt01, Qwen3-32B Q8_0 resident)

| Resource | Used (typical) | Limit | Headroom |
|---|---|---|---|
| RAM | ~42 GiB | 96 GiB | ~54 GiB (page cache + spikes) |
| CPU (inference) | 16C busy only during generation | 32 threads | Idle capacity for prompt bursts |
| NVMe | ~60 GiB (OS+models) | 1 TB | ample |
| Network | ≤ 1 Mb/s API traffic | 1 GbE | ample |

## Throughput model

- Single inference slot; token generation ≈ 1.4 tok/s on Q8_0 32B.
- A median internal request (~300 output tokens) occupies the slot ~4 min.
- **Sustainable capacity ≈ 15 req/hour** at median size; rate limiter set
  below this to protect latency (see `docs/06-api/rate-limiting.md`).
- Load baseline: `tests/load/locustfile.py` run on staging monthly; latest
  results in the load-test report artifact.

## Scaling signals (when to act)

| Signal | Threshold | Action |
|---|---|---|
| Queue depth ≥ 2 sustained 15 min | daily recurrence | Engage consumers on batching; consider 2nd slot only after RAM check |
| p95 latency > 2× baseline | weekly | Benchmark re-run; thermal check; model quantization review (Q4_K_M trade) |
| Consumer demand > 30 req/hour | forecast | Escalate to GPU roadmap / second node |
| Model RAM need > 80 GiB | admission request | Reject on lt01; queue for HW refresh |

## What scaling looks like (decision tree)

1. **Quantize down** (Q8_0 → Q4_K_M): ~2× speed, quality review required
   (`docs/05-models/quantization-guide.md`).
2. **GPU offload** per `docs/02-deployment/gpu-upgrade-roadmap.md`
   (5–8× speed expected with RTX 4090 partial offload).
3. **Second node**: requires new VLAN 40 member + load split at consumers
   (API is stateless); duplicate this repo's deployment.

## Forecast inputs

Consumer onboarding form captures expected req/day and token profile;
platform lead updates this doc quarterly and at every new consumer.
