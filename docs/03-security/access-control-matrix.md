# Access Control Matrix

Last verified: 2026-08-04 · Owner: security · Review: quarterly

## Human accounts

| Account | Scope | Auth | Sudo | Notes |
|---|---|---|---|---|
| jol-admin | Platform lead | SSH CA cert (`platform-lead` principal) | `ALL` (logged) | Sole owner of vault passphrase rotation |
| jol-ops | Platform engineer | SSH CA cert (`platform-eng`) | `/usr/bin/systemctl * ollama* caddy* netdata*`, `/opt/jol/repos/jol-llm/scripts/**` (allowlist) | Day-2 operations |
| jol-sec | Security reviewer | SSH CA cert (`security`) | read-only: `/usr/bin/journalctl`, `/usr/bin/aureport`, `/opt/jol/repos/jol-llm/scripts/security/**` | Audit review |
| root | Emergency only | Locked for SSH; console/IPMI only | — | Break-glass, usage = incident |

Rules: no shared accounts; SSH password auth disabled; MFA enforced at the
SSH CA/jump-host layer; access recertified quarterly (ticket template
`ACCESS-RECERT`).

## Service accounts

| Account | Owns | May NOT |
|---|---|---|
| `ollama-svc` | `/opt/jol/models` (rw), Ollama runtime, loopback :11434 | Write outside models dir; shell login (`/usr/sbin/nologin`); network egress |
| `bridge-svc` | Key store `/etc/jol/bridge/keys.db` (0600), audit log dir | Modify models; execute setuid binaries |
| `caddy` | TLS material `/etc/caddy/tls/*`, access log | — |
| `netdata` | Metrics collection | Inference APIs (no auth credentials held) |

Enforcement: unit-level sandboxing (see `deploy/systemd/ollama.service`),
`tests/security/test_file_permissions.sh` asserts ownership/modes.

## API access (workloads)

- One API key per consuming workload; keys are `jol_<client>_` prefixed,
  256-bit random, stored **salted-hashed** in the bridge key store.
- mTLS client certificates per team; CN bound to team identity; revocation
  via CRL within 4 h of request.
- Key/cert lifecycle: issue → 90-day rotation (`rotate-api-keys.sh`) →
  revoke. See [`../06-api/authentication.md`](../06-api/authentication.md).

## sudoers excerpt (managed by Ansible)

```sudoers
# /etc/sudoers.d/jol-llm  (installed by 01-os-hardening.yml)
Cmnd_Alias JOL_OPS = /usr/bin/systemctl restart ollama*, /usr/bin/systemctl reload caddy
Cmnd_Alias JOL_SEC = /opt/jol/repos/jol-llm/scripts/security/*, /usr/bin/aureport
%platform-eng ALL=(root) NOPASSWD: JOL_OPS
%security     ALL=(root) NOPASSWD: JOL_SEC
```

## Pinned trust anchors

| Item | Location | Rotation |
|---|---|---|
| SSH CA public key | `/etc/ssh/ca.pub` + this matrix | Annual |
| Internal TLS CA | `/etc/caddy/tls/ca.crt` | 5-year CA, yearly leaf certs |
| Security contact PGP | Keyserver + printed fingerprint here: `AB12 CD34 ...` (update at rotation) | Annual |
| Ansible vault | `infra/group_vars/all/vault.yml` | Passphrase rotated on personnel change |

## Change log

| Date | Change | Approver |
|---|---|---|
| 2026-08-04 | Initial production matrix | security |
