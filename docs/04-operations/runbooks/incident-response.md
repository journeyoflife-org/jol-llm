# Runbook — Incident Response

Last verified: 2026-08-04 · Owner: security + platform-eng
Drill log: vault `IR-DRILLS`. Severity ladder: SEV1 outage / SEV2 degraded /
SEV3 security-suspect.

## 1. API outage (no 200s)

1. **Detect/confirm**: `scripts/maintenance/health-check.sh` (exit code),
   Netdata dashboard, consumer reports.
2. **Triage ladder** (stop at first failure found):
   ```bash
   systemctl status caddy ollama-api-bridge ollama
   curl -sk https://10.40.10.21:8443/healthz          # Caddy layer
   curl -s  http://127.0.0.1:8901/healthz             # bridge
   curl -s  http://127.0.0.1:11434/api/tags           # Ollama
   ```
3. **Common fixes**:
   - Ollama inactive → check `journalctl -u ollama -n 100` (OOM? model
     load error?). OOM: free RAM, restart; recurring OOM → check for rogue
     second loaded model.
   - Bridge 5xx → key store mounted? restart unit.
   - Caddy cert errors → cert rotation runbook.
4. **Escalate**: if not resolved in 30 min → platform lead; page per
   on-call schedule. Communicate on #llm-ops channel.
5. **Post-incident**: timeline in ticket within 48 h; update this runbook
   if any step was wrong.

## 2. Performance degradation

1. Check Netdata: tok/s floor alert, queue depth, CPU temp/frequency.
2. Thermal throttling? `sensors`, clean dust / check fans (HW doc).
3. Queue depth > 2 sustained → consumers exceeding rate budget; verify
   rate-limit config; contact offending client (hashed ID in audit).
4. Model unexpectedly swapped? `ollama list` vs registry; restore via
   `runbooks/model-swap.md`.

## 3. Model corruption suspected

1. `scripts/maintenance/health-check.sh --verify-model` (SHA256 vs manifest).
2. If mismatch: **stop service**, mark SEV3 (integrity incident):
   ```bash
   sudo systemctl stop ollama-api-bridge   # stop traffic first
   sudo aureport -f -i --start today       # who touched /opt/jol/models?
   ```
3. Restore from HDD backup or re-run air-gap import.
4. Security review before re-enabling traffic; AIDE diff attached to ticket.

## 4. Suspected breach / prompt-data exposure (GDPR clock)

1. **Contain**: isolate host from VLAN 40 at the switch (keep power for
   forensics), or at minimum stop bridge + Caddy.
2. **Preserve**: snapshot `/var/log/jol-audit/`, auditd logs, journald to
   the forensic HDD before any restart.
3. **Assess**: was prompt content persisted? By design it cannot be —
   verify with `grep -r` for reported sentinel content; any hit = confirmed
   personal-data incident → GDPR Art. 33 assessment starts (72 h).
4. **Notify**: security lead + DPO immediately; follow
   `security/policies/incident-response-policy.md`.
5. **Recover**: rebuild per rollback §7, rotate all keys/certs.

## 5. Communication templates

- Internal: "LLM API SEV{n}: {symptom}. ETA {x}. Next update {time}."
- Never disclose client names or content in status messages.
