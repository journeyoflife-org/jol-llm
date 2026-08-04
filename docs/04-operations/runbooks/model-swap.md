# Runbook — Model Swap (Hot Swap of Quantized Models)

Last verified: 2026-08-04 · Owner: platform-eng
Downtime tolerance: none for API gateway; inference interruption ≤ 3 min
acceptable during resident-model switch.

## Preconditions

- New model imported and verified (`03-model-pull.sh`), visible in
  `ollama list`.
- Announce window in #llm-ops; check Netdata queue depth ≈ 0 before start.
- Backup current state: `scripts/maintenance/config-backup.sh`.

## Procedure

1. **Freeze new traffic** (keep existing requests draining):
   ```bash
   sudo systemctl stop caddy           # or: UFW deny 8443 temporarily
   ```
2. **Wait for drain**: watch `ollama ps` until no running request
   (bridge audit tail shows no in-flight correlation IDs):
   ```bash
   tail -f /var/log/jol-audit/bridge.log   # metadata only — safe
   ```
3. **Swap resident model** — set the default model for the bridge and
   warm the new model:
   ```bash
   sudo -u ollama-svc ollama run <new-model> --keepalive 30m <<< "/bye"
   ```
   Or update the Modelfile default in `config/ollama/modelfiles/` +
   restart bridge if the alias changed.
4. **Verify**:
   ```bash
   sudo scripts/install/04-post-install-verify.sh --model <new-model>
   ```
   Latency budget must pass; check `ollama ps` shows single resident model.
5. **Unfreeze**:
   ```bash
   sudo systemctl start caddy
   ```
6. **Monitor** for 15 min: tok/s floor, error rate, queue depth.

## Rollback

If verify fails or consumers report regressions: repeat steps 1–5 with the
previous model name. The old model stays on disk until decommissioned;
`ollama rm` only after 1 week stable + backup confirmed.

## Notes

- `OLLAMA_MAX_LOADED_MODELS=1` means the swap evicts the previous model;
  first request after swap pays load time (~30–90 s from NVMe).
- Never run two ≥32B models concurrently on lt01 (RAM budget, see hardware
  doc).
