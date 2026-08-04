# Attack tree — model supply chain compromise

Goal: attacker substitutes or modifies model weights served to users.

```mermaid
flowchart TB
  GOAL["Malicious weights in production<br/>(asset A2 integrity)"]
  GOAL --> U["Upstream compromise"]
  GOAL --> K["Kiosk/staging compromise"]
  GOAL --> H["On-host substitution"]

  U --> U1["Malicious artifact with valid hash on download page"]
  U1 --> U1a["Blocked: hash taken from THIS repo,<br/>cross-referenced from second source<br/>in manifest PR (2-eyes)"]

  K --> K1["Tampered artifact on transfer media"]
  K1 --> K1a["Blocked: SHA256 re-verified on target<br/>by 03-model-pull.sh before install"]

  H --> H1["Direct write to /opt/jol/models"]
  H --> H2["Swap of /usr/local/bin/ollama"]
  H1 --> H1a["auditd watch + AIDE diff +<br/>nightly re-hash vs manifest"]
  H2 --> H2a["auditd watch + update script<br/>checksum gate + release archive"]
```

## Cut sets

1. Upstream + both checksum sources compromised simultaneously — residual
   risk T3 (accepted, annual review).
2. Root on host bypassing monitoring — mitigated by immutable audit rules
   (`-e 2`) + off-host archive of audit trail; detection via WORM-archive
   reconciliation.
