# GDPR Article 32 Checklist — Security of Processing

Last verified: 2026-08-04 · Owner: security

Platform: jol-llm (llm-prod-lt01) · Role: processor of prompts submitted by
internal controllers (JOL business units).

## (a) Pseudonymisation and encryption of personal data

- [x] Transport: mTLS 1.2+ enforced (Caddy `require_and_verify`).
- [x] At rest: no personal data persisted (0-day prompt retention);
      metadata pseudonymised via salted SHA-256 client hashes.
- [x] Backups: encrypted (LUKS/restic password in vault).
- [x] Keys/certs: 0600/0640 modes, asserted by
      `tests/security/test_file_permissions.sh`.

## (b) Confidentiality, integrity, availability, resilience

- [x] Confidentiality: loopback-only runtime, VLAN isolation, egress deny.
- [x] Integrity: SHA256-pinned models + binary; AIDE baseline; auditd.
- [x] Availability: hardened units with auto-restart; rollback procedures;
      RTO target < 30 min (single-host reality documented).
- [x] Resilience: rate limiting; RAM/CPU governance; capacity plan.

## (c) Ability to restore availability and access promptly

- [x] Rollback runbooks verified on staging (date in doc header).
- [x] Model restore from HDD backup tested quarterly.
- [x] Full-rebuild procedure documented (bare-metal-install + backups).

## (d) Process for regularly testing, assessing, evaluating effectiveness

- [x] Automated: CI suites (integration/security) + weekly Lynis/debsecan.
- [x] Quarterly: access recertification, restore drill.
- [x] Semi-annual: IR tabletop exercise.
- [x] Annual: threat model + license + policy review.

## Supporting DPIA conclusions

- Necessity/proportionality: internal productivity tool; minimal data
  (prompt text only, no account graph, no tracking).
- Risks to data subjects mitigated by: no persistence, no external flow,
  access control, and AUP restricting personal-data use.
- Residual risk accepted by DPO on 2026-07-28 (ticket ref in vault).
