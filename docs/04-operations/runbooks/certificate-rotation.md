# Runbook — Certificate Rotation (mTLS)

Last verified: 2026-08-04 · Owner: platform-eng
Alerts: Netdata warns at 7 days to expiry, critical at 3 days.

## Material inventory

| Item | Path | Lifetime |
|---|---|---|
| Internal CA | `/etc/caddy/tls/ca.crt` | 5 years |
| Server leaf (llm-prod-lt01) | `/etc/caddy/tls/llm-prod-lt01.{crt,key}` | 1 year |
| CRL | `/etc/caddy/tls/ca.crl` | Updated on any client revocation |
| Client certs | Held by consuming teams | 1 year |

Generation procedure (internal CA): `scripts/security/generate-mtls-certs.sh`
and [`../../../deploy/caddy/tls/README.md`](../../../deploy/caddy/tls/README.md).

## Server leaf rotation (zero downtime)

```bash
# 1. Issue new leaf from the internal CA (on the CA host / kiosk)
sudo scripts/security/generate-mtls-certs.sh --leaf llm-prod-lt01

# 2. Stage new material (keep old!)
sudo install -m 0600 llm-prod-lt01.key /etc/caddy/tls/llm-prod-lt01.key.new
sudo install -m 0644 llm-prod-lt01.crt /etc/caddy/tls/llm-prod-lt01.crt.new

# 3. Validate before swap
openssl verify -CAfile /etc/caddy/tls/ca.crt /etc/caddy/tls/llm-prod-lt01.crt.new

# 4. Atomic swap + reload (reload = no dropped connections)
sudo bash -c 'cd /etc/caddy/tls && \
  mv llm-prod-lt01.crt{.new,} && mv llm-prod-lt01.key{.new,}'
sudo systemctl reload caddy

# 5. Verify
curl -sk --cert <test-client.crt> --key <test-client.key> \
  https://10.40.10.21:8443/healthz
```

Rollback: restore previous pair from `/opt/jol/state/tls-backup/`, reload.

## Client cert revocation

1. Revoke at CA: `openssl ca -revoke <cert>` → regenerate CRL.
2. Distribute CRL to `/etc/caddy/tls/ca.crl`, `systemctl reload caddy`.
3. Revoke the client's API key too: `scripts/security/rotate-api-keys.sh
   --revoke <client-id>`.
4. SLA: revocation effective ≤ 4 h from request (access-control-matrix).

## CA expiry (every 5 years — major procedure)

Requires project-level planning: dual-CA trust window (new CA added to
pool 30 days ahead), re-issue all leaf + client certs, then drop old CA.
Never let the CA expire unplanned — it breaks every client at once.
