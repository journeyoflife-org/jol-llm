# Air-Gap Procedure — Offline Model Transfer & Verification

Last verified: 2026-08-04 · Owner: platform-eng · Approver: security

llm-prod-lt01 has **no internet access by design**. Model weights and the
Ollama binary enter through a controlled kiosk workflow. This document is
normative — deviations require security sign-off.

## Roles

| Role | Responsibility |
|---|---|
| Operator | Downloads artifacts on the kiosk machine, verifies signatures, transfers media |
| Security reviewer | Confirms manifest PR, GPG key trust, license audit entry |
| Platform lead | Approves production activation |

## Prerequisites

- **Kiosk machine**: internet-connected, dedicated, hardened, no access to
  internal VLANs, AV/EDR enabled.
- **Transfer media**: encrypted USB (LUKS) used only for this purpose, or
  the NAS staging share (`nas01:/srv/airgap-in`) over the maintenance VLAN.
- **GPG keys**: upstream publisher keys imported on the kiosk **and** pinned
  in this repo (`models/manifests/*.json` → `gpg_fingerprint`).

## Step 1 — Download & verify on the kiosk

```bash
# On the kiosk (internet side)
curl -fLO <url from models/manifests/<model>.json>
sha256sum <artifact>                  # MUST equal manifest "sha256"
gpg --verify <artifact>.sig <artifact>  # if publisher ships signatures
```

Rules:

- If SHA256 mismatches: **stop**, do not transfer, file a security issue.
- The checksum used for verification must come from this repository
  (fetched over the internal git mirror), never from the download page.

## Step 2 — Record provenance

Update the manifest in a PR:

- `sha256` pinned to the verified value (CI rejects the zero placeholder),
- `imported_at`, `imported_by`, `source_url`, `gpg_fingerprint` set.

## Step 3 — Transfer

1. Copy artifact + manifest + signature onto encrypted media.
2. Physically move media to llm-prod-lt01 (or copy via NAS staging share).
3. On the target host:

```bash
sudo scripts/install/03-model-pull.sh --import /mnt/usb/<artifact>
```

The script re-verifies SHA256 **on the target**, places the model under
`/opt/jol/models`, registers it with Ollama via a Modelfile from
`config/ollama/modelfiles/`, and refuses to proceed on any mismatch.

## Step 4 — Post-import validation

```bash
sudo scripts/install/04-post-install-verify.sh --model <name>
sudo scripts/maintenance/health-check.sh --verify-model
```

- [ ] Inference smoke test passes with canned prompt
- [ ] Benchmark appended (`scripts/utils/benchmark-model.sh`)
- [ ] Backup taken (`scripts/maintenance/model-backup.sh`)
- [ ] AIDE baseline updated (audit trail of the new files)

## Rollback

Remove the model (`ollama rm <name>`), delete files, restore AIDE baseline
from the pre-import snapshot. See
[`rollback-procedures.md`](rollback-procedures.md) §4.

## Threat notes

This procedure mitigates STRIDE-T2/T3 (model supply chain) — see
[`../03-security/threat-model.md`](../03-security/threat-model.md). The
dominant residual risk is a malicious upstream artifact that passes GPG
because the publisher key itself was compromised; mitigation: dual-source
checksum cross-reference (publisher page + independent mirror) recorded in
the manifest PR.
