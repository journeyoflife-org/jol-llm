---
name: Bug report
about: Something in the jol-llm platform is broken or misbehaving
labels: ["bug", "triage"]
---

## Summary

<!-- One paragraph: what is broken, since when, blast radius. -->

## Environment

- Host: [ ] llm-prod-lt01 [ ] llm-stg-01 [ ] other: ___
- Component: <!-- ollama / caddy / api-bridge / netdata / ansible / scripts -->
- Version/commit: <!-- `git rev-parse HEAD` of jol-llm + ollama --version -->

## Steps to reproduce

1.
2.
3.

## Expected behavior

## Actual behavior

<!-- Paste exact error messages. NEVER paste prompt/completion content or
     API keys. Redact client identifiers if not relevant. -->

## Evidence

- Relevant journal lines (`journalctl -u <unit> --since ...`, redacted):
- Netdata chart links (if applicable):
- Audit log reference IDs (not content):

## Impact & severity

- [ ] Service outage (no inference)
- [ ] Degraded performance
- [ ] Security concern → STOP and use the security advisory template instead
- [ ] Cosmetic / documentation

## Checklist

- [ ] No secrets or prompt content included
- [ ] Checked runbooks (`docs/04-operations/runbooks/`) before filing
