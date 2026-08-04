# Security Policy — jol-llm

## Supported versions

| Version | Supported |
|---|---|
| 1.x     | Yes — production (llm-prod-lt01) |
| < 1.0   | No — pre-release history purged |

## Reporting a vulnerability

**Do not open a public issue.** Use one of:

1. GitHub → *Security advisories* → **Report a vulnerability** (uses
   [`.github/ISSUE_TEMPLATE/security_advisory.md`](.github/ISSUE_TEMPLATE/security_advisory.md)).
2. Email `security@jol.internal` (PGP key published on the internal key
   server, fingerprint pinned in `docs/03-security/access-control-matrix.md`).

You will receive an acknowledgement within **1 business day** and a status
update at least every **5 business days**. Target remediation SLAs:

| Severity | Initial triage | Fix or mitigation |
|---|---|---|
| Critical | 24 h | 72 h |
| High     | 3 days | 14 days |
| Medium   | 1 week | next maintenance window |
| Low      | best effort | next maintenance window |

## Scope

In scope: everything in this repository as deployed on `llm-prod-lt01`
(Ollama runtime, API bridge, Caddy mTLS layer, OS hardening, model supply
chain). Out of scope: social engineering, physical intrusion, denial of
service via prompt floods exceeding documented capacity
(`docs/04-operations/capacity-planning.md`).

## Threat model (summary)

Full STRIDE analysis: [`security/threat-model/stride-analysis.md`](security/threat-model/stride-analysis.md).
Attack trees: [`security/threat-model/attack-trees/`](security/threat-model/attack-trees/).

Key design assumptions:

- The host has **no internet egress**; the dominant threat is lateral
  movement from the corporate VLAN and supply-chain compromise of models.
- Prompt and completion content is **never persisted** (GDPR Art. 5(1)(e),
  0-day retention). See [`security/policies/data-retention-policy.md`](security/policies/data-retention-policy.md).
- All API access requires mTLS **and** an API key (defense in depth).
- Models are installed only after SHA256 + GPG verification against pinned
  manifests in `models/manifests/`.

## Software Bill of Materials

CycloneDX SBOM for the Ollama runtime and platform components:
[`security/sbom/ollama-sbom.json`](security/sbom/ollama-sbom.json).
Regenerate during Ollama upgrades via
`scripts/maintenance/update-ollama.sh` (the SBOM refresh step is mandatory
and the update aborts without it).

## Hardening evidence

- Pre-go-live audit: [`docs/03-security/hardening-checklist.md`](docs/03-security/hardening-checklist.md)
- Continuous scanning: Lynis + debsecan in CI (`/.github/workflows/compliance-scan.yml`)
  and weekly via cron on the host.
- Automated assertions: `tests/security/` (egress blocking, file permissions).

## Disclosure policy

Coordinated disclosure only. JOL will not pursue legal action against
researchers who act in good faith within this policy's scope.
