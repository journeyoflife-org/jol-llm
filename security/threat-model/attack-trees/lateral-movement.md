# Attack tree — lateral movement to the LLM host

Goal: attacker on corp VLAN obtains prompt data or model control.

```mermaid
flowchart TB
  GOAL["Obtain prompt data / model control<br/>(assets A1, A2, A3)"]
  GOAL --> A["Reach host network services"]
  GOAL --> B["Compromise an authorized path"]

  A --> A1["Connect to 8443/tcp"]
  A --> A2["Connect to 22/tcp"]
  A --> A3["Scan for other listeners"]

  A1 --> A1a["Present valid mTLS cert<br/>[requires CA compromise or<br/>stolen client key — detected via CRL+audit]"]
  A1 --> A1b["TLS failure — blocked<br/>(require_and_verify)"]

  A2 --> A2a["Blocked: SSH allowed only<br/>from 10.90.0.0/24 (UFW)"]

  A3 --> A3a["Blocked: no other listeners<br/>(loopback-only services)"]

  B --> B1["Stolen operator SSH cert"]
  B --> B2["Stolen API key"]
  B --> B3["Insider with access"]

  B1 --> B1a["MFA at jump host; short-lived certs;<br/>recertification quarterly"]
  B2 --> B2a["90-day rotation; hashed store;<br/>usage anomalies in audit-review"]
  B3 --> B3a["2-eyes for security paths;<br/>sudo logging; audit trail"]
```

## Cut sets (minimal successful paths)

1. **CA key compromise + forged client cert** — mitigated: CA key offline,
   0400, access logged; detection: unexpected issuance events.
2. **Leaked API key + valid client cert** — mitigated: rotation cadence,
   revocation ≤ minutes; detection: hashed-ID usage review.
3. **Insider with sudo** — mitigated: command logging, 2-eyes change
   control; accepted residual risk recorded in STRIDE register.

## Metrics

- Time-to-detect target for any cut-set activation: ≤ 24 h (weekly audit
  review + Netdata anomalies).
- Time-to-contain: key/cert revocation ≤ 4 h (SLA).
