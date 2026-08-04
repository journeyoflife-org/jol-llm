# GPU Upgrade Roadmap — Polaris → NVIDIA RTX

Last verified: 2026-08-04 · Owner: platform-eng · Status: proposal v2

## Why

The current Polaris GPU is unusable for LLM inference (GCN4, no supported
ROCm stack, unstable Vulkan path for >13B models). CPU inference on the
3950X yields ~1.4 tok/s for Qwen3-32B Q8_0 — functional but constrains
interactive use and rules out parallel slots.

## Target options

| Option | VRAM | Est. perf (Qwen3-32B Q8_0) | Cost | Fit |
|---|---|---|---|---|
| RTX 3090 (used) | 24 GB | Model doesn't fit fully; ~24 GB offload ≈ 4–6 tok/s | low | Stopgap only |
| **RTX 4090** | 24 GB | Same offload ceiling, faster kernels ≈ 6–9 tok/s | medium | **Recommended stopgap** |
| RTX 6000 Ada / 2×3090 NVLink-free MoE-offload | 48 GB | Near-full 32B Q4 on GPU ≈ 20–35 tok/s | high | Phase 2 |

Decision: **Phase 1 = single RTX 4090**, CPU keeps prompt processing
overflow; **Phase 2** revisit when 48 GB+ cards are price-favorable.

## Hardware checklist (Phase 1)

- [ ] PCIe x16 slot 1 free; riser/clearance check (3-slot card)
- [ ] PSU: 750 W sufficient for 3950X (~180 W) + 4090 (450 W peak) with
      headroom — verified against measured wall draw, margin ≥ 20%
- [ ] Case airflow: add front intake; GPU exhaust path clear
- [ ] Remove Polaris card in the same maintenance window (reduces driver
      surface area per hardware doc)

## Software checklist

- [ ] Ubuntu 24.04 + NVIDIA driver ≥ 550 from the **offline driver bundle**
      on the air-gap kiosk (no apt over internet — follow
      [`air-gap-procedure.md`](air-gap-procedure.md) for the .run/.deb)
- [ ] Ollama rebuild/bundle with CUDA support (kiosk-downloaded, SHA256-pinned)
- [ ] Set `OLLAMA_GPU_MEMORY_FRACTION`, verify `ollama ps` shows
      `100% GPU`/partial offload as expected
- [ ] Update `config/ollama/environment`: keep `OLLAMA_NUM_PARALLEL=1`
      initially; re-benchmark before enabling 2 slots
- [ ] Re-run full benchmark suite; update
      `models/benchmarks/llm-prod-lt01-results.csv` and
      `docs/05-models/benchmark-results.md`
- [ ] Update Netdata charts (GPU temp/util alerts replace CPU-temp emphasis)
- [ ] Threat model update: NVIDIA driver/firmware as new supply-chain item
      (add SBOM entry)

## Rollback plan

The CPU path remains fully functional: revert the environment file to
`OLLAMA_NO_CUDA=1` equivalent (`CUDA_VISIBLE_DEVICES=""`), restart Ollama,
service returns to ~1.4 tok/s baseline within 2 minutes. Full procedure in
[`rollback-procedures.md`](rollback-procedures.md) §5.

## Timeline

| Milestone | Target |
|---|---|
| Procurement approved | T0 |
| Kiosk bundle prepared (driver + CUDA Ollama) | T0 + 1 wk |
| Maintenance window & install | T0 + 2 wk |
| 2-week burn-in, benchmarks, go/no-go | T0 + 4 wk |

## Success criteria

- ≥ 5× median tok/s vs CPU baseline on the primary model
- Zero regressions in `tests/integration/` and `tests/security/`
- No new findings against `hardening-checklist.md`
