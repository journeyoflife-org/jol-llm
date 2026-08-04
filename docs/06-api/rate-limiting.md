# Rate Limiting — Per-Client Token Bucket

Last verified: 2026-08-04 · Owner: platform-eng

## Why

Single inference slot + ~1.4 tok/s means the platform is a scarce resource.
Rate limiting protects latency for everyone and provides a fairness record
for capacity planning.

## Model

Per-client **token bucket** at the API bridge (key = API key client ID):

| Parameter | Default | Rationale |
|---|---|---|
| Bucket capacity | 8 requests | Short burst tolerance |
| Refill rate | 10 requests/hour | Below sustainable ~15 req/h, leaves headroom for priority clients |
| Token-cost weighting | 1 request = 1 unit; `max_tokens` > 2048 costs 2 units | Large completions occupy the slot ~2× longer |
| Priority tiers | `interactive` (default), `batch` (½ rate, lower priority) | Set at key issuance |

## Behavior

- On limit: HTTP `429` + `Retry-After: <seconds>` + JSON body
  `{"error": {"type": "rate_limit_exceeded"}}`.
- Limits are evaluated **before** forwarding to Ollama; in-flight requests
  are never aborted by the limiter.
- State is in-memory; bridge restart resets buckets (acceptable — limits
  are protective, not billing).

## Configuration

Defined in the bridge config (vault-managed per-client overrides):

```yaml
rate_limit:
  default:
    capacity: 8
    refill_per_hour: 10
    large_request_threshold_tokens: 2048
  clients: {}            # per-client overrides keyed by client-id
```

Changes require PR + platform-lead review (affects downstream contracts —
see `docs/01-architecture/service-dependencies.md`).

## Observability

- `llm.queue_depth`, 429-rate chart, and per-client-id (hashed)
  consumption in the audit dashboard.
- Alert: client exhausting bucket repeatedly (>10×429/day) → capacity
  planning review, not automatic limit raising.

## Anti-abuse notes

- mTLS + per-client keys make evasion via new identities a cert-issuance
  event (visible), not an anonymous one.
- Request body size capped at the bridge (1 MiB) to bound prompt-injection
  surface and RAM use.
