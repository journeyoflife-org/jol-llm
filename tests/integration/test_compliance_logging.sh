#!/usr/bin/env bash
# test_compliance_logging.sh — 0-day prompt retention guard.
# Injects a unique sentinel prompt through the API, then scans every
# persistent log sink on the host for the sentinel. Any match is a
# GDPR Art. 5(1)(e) retention violation → hard fail.
#
# Run on llm-prod-lt01 as root (reads /var/log/jol-audit, journald,
# Ollama service logs, Caddy access logs):
#   sudo tests/integration/test_compliance_logging.sh
set -Eeuo pipefail

HOST_IP="${HOST_IP:-10.40.10.21}"
API_PORT="${API_PORT:-8443}"
MODEL="${MODEL:-qwen3-32b-q8_0}"
BASE_URL="https://${HOST_IP}:${API_PORT}/v1/chat/completions"

# Unique sentinel — random per run so stale matches can't false-pass.
SENTINEL="jol-sentinel-$(openssl rand -hex 12 2>/dev/null || date +%s%N)"
printf '[compliance-test] sentinel: %s\n' "${SENTINEL}"

if [[ -z "${JOL_API_KEY:-}" || -z "${JOL_MTLS_CERT:-}" || -z "${JOL_MTLS_KEY:-}" ]]; then
  printf '[compliance-test] ERROR — JOL_API_KEY, JOL_MTLS_CERT, JOL_MTLS_KEY required\n' >&2
  exit 2
fi

# 1. Inject the sentinel prompt through the full path.
code=$(curl -sk -o /dev/null -w '%{http_code}' \
  --cert "${JOL_MTLS_CERT}" --key "${JOL_MTLS_KEY}" \
  -H "Authorization: Bearer ${JOL_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"model":"'"${MODEL}"'","messages":[{"role":"user","content":"Repeat this marker: '"${SENTINEL}"'"}],"max_tokens":16,"stream":false}' \
  "${BASE_URL}" --connect-timeout 10 --max-time 120 || echo "000")
if [[ "${code}" != "200" ]]; then
  printf '[compliance-test] ERROR — injection request failed (HTTP %s); cannot test\n' "${code}" >&2
  exit 2
fi
printf '[compliance-test] sentinel injected (HTTP %s)\n' "${code}"

# Let asynchronous log writers flush.
sleep 3

# 2. Scan all persistent sinks. Prompt content must appear nowhere.
FAILURES=0
fail() { printf '[compliance-test] FAIL — %s\n' "$*"; FAILURES=$((FAILURES + 1)); }
pass() { printf '[compliance-test] PASS — %s\n' "$*"; }

scan() {
  local sink="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    fail "SENTINEL FOUND in ${sink} — prompt content persisted"
  else
    pass "no sentinel in ${sink}"
  fi
}

scan "/var/log/jol-audit (bridge audit log)"   grep -r "${SENTINEL}" /var/log/jol-audit/
scan "/var/log/caddy (proxy access/error log)" grep -r "${SENTINEL}" /var/log/caddy/
scan "journald ollama.service"                 journalctl -u ollama.service --since "5 min ago" --no-pager --output cat
scan "journald ollama-api-bridge.service"      journalctl -u ollama-api-bridge.service --since "5 min ago" --no-pager --output cat
scan "journald caddy.service"                  journalctl -u caddy.service --since "5 min ago" --no-pager --output cat
scan "/var/log/syslog"                         grep -r "${SENTINEL}" /var/log/syslog
scan "netdata logs"                            grep -r "${SENTINEL}" /var/log/netdata/

# 3. Negative control: sentinel must NOT be in the model registry dir either.
scan "/opt/jol/models (must never hold prompts)" grep -r "${SENTINEL}" /opt/jol/models/

if (( FAILURES > 0 )); then
  printf '[compliance-test] RESULT: RETENTION VIOLATION — %s sink(s) contain prompt content\n' "${FAILURES}"
  printf '[compliance-test] Escalate per security/policies/incident-response-policy.md (SEV-2 minimum)\n'
  exit 1
fi
printf '[compliance-test] RESULT: ALL SINKS CLEAN — 0-day retention holds\n'
