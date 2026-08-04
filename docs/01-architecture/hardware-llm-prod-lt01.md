# Hardware — llm-prod-lt01

Last verified: 2026-08-04 · Owner: platform-eng

## Bill of materials

| Component | Specification | Role in LLM serving |
|---|---|---|
| CPU | AMD Ryzen 9 3950X, 16 cores / 32 threads, boost 4.7 GHz | **Primary inference engine** (CPU GGML kernels, AVX2) |
| RAM | 96 GB DDR4-3200 (2×48 GB dual-rank, dual-channel, ~47 GB/s theoretical) | Model weights + KV cache; hard cap on model size |
| Motherboard | X570, BIOS 4.x (AGESA current) | NUMA: single node |
| GPU | AMD Radeon Polaris (RX 5xx), amdgpu | **Technical debt** — no viable ROCm/LLM path; physically present, not used |
| NVMe | 1 TB Gen3 (OS + `/opt/jol/models`) | Model load path; SMART monitored |
| HDD | 4 TB (backups + audit archive) | `model-backup.sh`, log archival target |
| NIC | 1 GbE onboard | VLAN 40 access |
| PSU | 750 W 80+ Gold | Headroom for future GPU (see roadmap) |

## RAM budget (worst case)

| Item | GiB |
|---|---|
| OS + services baseline | ~3 |
| Qwen3-32B Q8_0 weights | ~34 |
| KV cache @ 8k context, 1 parallel slot | ~4 |
| Netdata + monitoring | ~1 |
| **Total resident** | **~42** |
| Free headroom (spike/page cache) | ~54 |

Rule: never admit a model whose weights + 15% exceed 80 GiB on this host.
See [`../04-operations/capacity-planning.md`](../04-operations/capacity-planning.md).

## Inference characteristics

- Bottleneck is memory bandwidth, not core count. Dual-channel DDR4-3200
  (~47 GB/s theoretical, ~38 GB/s measured STREAM) yields ~1.3–1.5 tok/s
  prompt-processing-bound for 34 GiB Q8_0 weights.
- `OLLAMA_NUM_PARALLEL=1`: concurrent slots divide bandwidth roughly
  linearly; quality-per-request beats throughput on this box.
- GPU is deliberately idle: Polaris (GCN4) lost upstream ROCm support;
  llama.cpp Vulkan on Polaris is unstable for >13B models. Do not attempt
  to re-enable without a tracked ADR.

## Known debt & mitigations

| Debt | Risk | Mitigation |
|---|---|---|
| Polaris GPU unused | Wasted power draw (~15 W idle), driver surface area | GPU blacklisted from compute paths; removal scheduled with RTX upgrade (`../02-deployment/gpu-upgrade-roadmap.md`) |
| No ECC RAM | Silent corruption of weights in memory | Nightly `health-check.sh --verify-model` re-hashes on-disk weights; ECC platform planned in refresh |
| Single PSU | Availability | On-site spare; swap procedure in ops runbook |
| 1 GbE | Slow model import from NAS | Imports staged over NAS mount in maintenance window only |

## Thermal & power baseline

- `01-pre-flight.sh` records CPU temps, fan curves, and NVMe SMART before
  go-live and after any BIOS change.
- Sustained inference: ~180 W package, all-core 4.0–4.2 GHz, CPU ~78 °C
  (tower cooler, 23 °C ambient). Alert threshold: 88 °C
  (`monitoring/netdata/health.d/ollama.conf`).
