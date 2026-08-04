# API Authentication

Last verified: 2026-08-04 · Owner: platform-eng

## Model: two independent factors

1. **mTLS client certificate** (machine/team identity) — enforced by Caddy;
   connections without a valid, unrevoked cert never reach the application.
2. **Bearer API key** (workload identity) — enforced by the API bridge;
   one key per consuming workload, revocable without touching TLS.

Both must pass. This separation lets us revoke a leaked key in minutes
without a cert ceremony, and revoke a team's cert without re-keying apps.

## API key format & storage

- Format: `jol_<client>_<64 hex>` (256-bit entropy).
- Storage: salted SHA-256 in the bridge key store
  (`/etc/jol/bridge/keys.db`, mode 0600, owner `bridge-svc`). The plaintext
  key exists only at issuance time and in the consumer's secret store.
- Metadata per key: client ID, issued date, expiry (90 days), scope.

## Lifecycle

```bash
sudo scripts/security/rotate-api-keys.sh --new <client-id>     # issue
sudo scripts/security/rotate-api-keys.sh --rotate <client-id>  # dual-key window
sudo scripts/security/rotate-api-keys.sh --revoke <client-id>  # immediate
sudo scripts/security/rotate-api-keys.sh --list                # audit view
```

- **Rotation** uses a 72 h dual-key window: old and new keys both valid so
  consumers can flip without downtime; the script warns at 72/24/4 h before
  expiry.
- Every authN decision is written to the metadata-only audit log (key
  fingerprint, never the key).

## Client usage example

```bash
curl --cert team-x.crt --key team-x.key \
  -H "Authorization: Bearer jol_team-x_…" \
  -H "Content-Type: application/json" \
  https://llm.jol.internal:8443/v1/chat/completions \
  -d '{"model":"qwen3-32b-q8_0","messages":[{"role":"user","content":"..."}]}'
```

## OAuth2 Proxy pattern (optional, browser flows)

For internal web UIs that need delegated user sign-on, deploy
`oauth2-proxy` (Quadlet: `deploy/podman/oauth2-proxy.container`) in front
of Caddy with the internal IdP:

- OIDC code flow against the internal IdP; session cookie scoped to the UI.
- The proxy still forwards a service API key to the bridge — user identity
  is passed as an allow-listed header (`X-Forwarded-User`) for UI-level
  attribution only; the *workload key* remains the authz anchor.
- Never expose the raw API to browsers; the proxy is the only approved
  browser-facing surface.

## Failure semantics

| Condition | HTTP | Note |
|---|---|---|
| No/invalid client cert | TLS alert at Caddy | Connection never reaches bridge |
| Missing Bearer key | 401 | `WWW-Authenticate: Bearer` |
| Invalid/expired key | 401 | Constant-time comparison in bridge |
| Revoked key | 401 + audit flag | Security notified via alert rule |
