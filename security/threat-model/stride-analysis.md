# STRIDE Analysis — jol-llm (detailed)

Companion to `docs/03-security/threat-model.md` (summary table T1–T12).
Method: STRIDE per trust boundary; likelihood/impact per JOL risk matrix
(Low/Medium/High). Review cadence: 12 months or on material change.

## Assets & valuation

- **A1 Prompt/completion content** — may contain internal confidential
  material or personal data. Confidentiality: High.
- **A2 Model weights** — licensed, high replacement cost (re-import labor +
  license audit). Integrity: High.
- **A3 Credentials** — API keys, client certs, CA key. All: High.
- **A4 Audit trail** — basis for accountability (ISO A.8.15). Integrity: High.
- **A5 Availability** — internal tooling tier. Availability: Medium.

## Boundaries and threats (expanded)

### TB1 VLAN perimeter

- **S1 Spoofed client from corp LAN** → mitigated by mTLS cert requirement;
  spoofing requires CA-signed cert (issuance is controlled/visible).
- **E1 Elevation via network services** → UFW input default deny; only
  8443 + SSH(jump host). Attack tree: `attack-trees/lateral-movement.md`.

### TB2 Host boundary

- **T2 Tampering with weights on disk** → AIDE + auditd `-w /opt/jol/models`
  + hash-gated import + nightly `health-check.sh --verify-model`.
- **E2 Privilege escalation from service account** → unit sandbox
  (`NoNewPrivileges`, `ProtectSystem=strict`, empty `CapabilityBoundingSet`);
  service accounts shell-locked.
- **D2 Resource exhaustion** → `MemoryMax=80G`, `TasksMax`, rate limits.

### TB3 TLS termination

- **S3 Rogue client cert** → CA key offline; issuance scripted + audited;
  CRL applied ≤ 4 h.
- **I3 Downgrade/weak cipher** → Caddy modern defaults; internal-only
  surface; periodic `testssl.sh` run on staging (annual).

### TB4 App boundary (bridge → Ollama)

- **I4 Request smuggling on loopback** → single-purpose bridge, strict JSON
  schema, body size cap 1 MiB; Ollama unreachable from network.
- **T6 Content leakage via logs** → no-body logging by construction;
  automated sentinel test; `LimitCORE=0`.

### TB5 Supply chain (kiosk → host)

- **T5a Tampered artifact** → SHA256 from repo (not download page) +
  dual-source cross-reference; target-side re-verification.
- **S5b Compromised publisher key** → accepted residual risk (T3), annual
  review; mitigated by dual-source + manifest PR review.
- **T5c Tampered Ollama binary** → checksum pinned in Ansible vars; assert
  blocks deployment on mismatch; update script enforces same gate.

### TB6 Model runtime (prompt → weights)

- **T4 Prompt injection with tool side-effects** → no external tools
  connected; egress blocked regardless; policy forbids connector approval
  without threat-model update.
- **I6 Model extraction via API** → weights confidentiality rated Low; rate
  limits bound extraction throughput; AUP prohibition.

## Risk acceptance register

| ID | Risk | Decision | Approver | Review due |
|---|---|---|---|---|
| T3 | Compromised upstream publisher key | Accepted (dual-source mitigation) | security + platform-lead | 2027-08 |
| T11 | Loopback cleartext hop | Accepted (kernel-only path) | platform-lead | 2027-08 |
