#!/usr/bin/env bash
# test_egress_blocking.sh — air-gap verification.
# Confirms default-deny egress (UFW) blocks external destinations, while
# required internal routes still work. Every external probe MUST fail;
# any success is a hard fail (air-gap violated).
set -Eeuo pipefail

TIMEOUT="${TIMEOUT:-5}"
FAILURES=0
pass() { printf '[egress-test] PASS — %s\n' "$*"; }
fail() { printf '[egress-test] FAIL — %s\n' "$*"; FAILURES=$((FAILURES + 1)); }

# 1. External HTTPS/HTTP probes — all must time out or be refused.
blocked_probe() {
  local label="$1" url="$2"
  if timeout "${TIMEOUT}" curl -sS -o /dev/null --connect-timeout 3 "${url}" 2>/dev/null; then
    fail "${label} reachable (${url}) — egress NOT blocked"
  else
    pass "${label} blocked"
  fi
}

blocked_probe "ollama.com (model CDN)"        https://ollama.com
blocked_probe "registry.ollama.ai"            https://registry.ollama.ai
blocked_probe "telemetry — example.com"       https://example.com
blocked_probe "DNS over HTTPS (cloudflare)"   https://1.1.1.1/dns-query

# 2. Raw TCP egress probes on common exfil ports.
blocked_port() {
  local label="$1" host="$2" port="$3"
  if timeout "${TIMEOUT}" bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null; then
    fail "TCP ${host}:${port} (${label}) open — egress NOT blocked"
  else
    pass "TCP ${host}:${port} (${label}) blocked"
  fi
}

blocked_port "HTTPS fallback"   1.1.1.1 443
blocked_port "SMTP exfil"       1.1.1.1 25
blocked_port "DNS TXT exfil"    1.1.1.1 53

# 3. UFW default policies sanity (host-side view).
if ufw status verbose 2>/dev/null | grep -qi "deny (outgoing)"; then
  pass "UFW outgoing policy is deny"
else
  fail "UFW outgoing policy is not default deny"
fi

# 4. Positive control: loopback API must still work (service not broken).
if curl -sf --connect-timeout 3 http://127.0.0.1:11434/api/version >/dev/null; then
  pass "loopback Ollama API unaffected"
else
  fail "loopback Ollama API down — host itself broken, result invalid"
fi

# 5. Positive control: internal VLAN route (gateway) must remain reachable.
GW="${JOL_GATEWAY:-10.40.10.1}"
if ping -c1 -W2 "${GW}" >/dev/null 2>&1; then
  pass "internal gateway ${GW} reachable"
else
  printf '[egress-test] WARN — gateway %s not reachable (verify network)\n' "${GW}"
fi

if (( FAILURES > 0 )); then
  printf '[egress-test] RESULT: %s check(s) FAILED — air-gap compromised\n' "${FAILURES}"
  exit 1
fi
printf '[egress-test] RESULT: ALL CHECKS PASSED — air-gap holds\n'
