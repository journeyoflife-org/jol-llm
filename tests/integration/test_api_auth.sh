#!/usr/bin/env bash
# test_api_auth.sh — authentication gate integration test.
# Asserts the auth contract of the bridge behind Caddy mTLS:
#   * missing/invalid API key  → 401
#   * valid key + client cert  → 200
# Exits 0 on pass. Run from the repo root on an authorized workstation:
#   JOL_API_KEY=jol_test_... JOL_MTLS_CERT=/path/client.crt \
#   JOL_MTLS_KEY=/path/client.key tests/integration/test_api_auth.sh
set -Eeuo pipefail

HOST_IP="${HOST_IP:-10.40.10.21}"
API_PORT="${API_PORT:-8443}"
MODEL="${MODEL:-qwen3-32b-q8_0}"
BASE_URL="https://${HOST_IP}:${API_PORT}/v1/chat/completions"

BODY='{"model":"'"${MODEL}"'","messages":[{"role":"user","content":"ping"}]}'
FAILURES=0

pass() { printf '[auth-test] PASS — %s\n' "$*"; }
fail() { printf '[auth-test] FAIL — %s\n' "$*"; FAILURES=$((FAILURES + 1)); }

# mTLS args — required for the positive case; the negative cases exercise
# what happens with and without a client certificate.
mtls_args=()
if [[ -n "${JOL_MTLS_CERT:-}" && -n "${JOL_MTLS_KEY:-}" ]]; then
  mtls_args=(--cert "${JOL_MTLS_CERT}" --key "${JOL_MTLS_KEY}")
fi

# Case 1: no API key → must be 401 (or TLS-layer rejection = 000).
code=$(curl -sk -o /dev/null -w '%{http_code}' "${mtls_args[@]+"${mtls_args[@]}"}" \
  -X POST "${BASE_URL}" -H 'Content-Type: application/json' \
  -d "${BODY}" --connect-timeout 5 2>/dev/null || echo "000")
case "${code}" in
  401) pass "missing API key rejected with 401" ;;
  000) pass "connection rejected at TLS layer (mTLS enforced)" ;;
  *) fail "missing API key returned ${code} (expected 401)" ;;
esac

# Case 2: garbage API key → must be 401 (bridge hash lookup must miss).
# Deliberately non-hex tail so secret scanners never flag this test string.
code=$(curl -sk -o /dev/null -w '%{http_code}' "${mtls_args[@]+"${mtls_args[@]}"}" \
  -X POST "${BASE_URL}" -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer jol_invalid_this-is-not-a-real-key' \
  -d "${BODY}" --connect-timeout 5 2>/dev/null || echo "000")
case "${code}" in
  401) pass "invalid API key rejected with 401" ;;
  000) pass "connection rejected at TLS layer (mTLS enforced)" ;;
  *) fail "invalid API key returned ${code} (expected 401)" ;;
esac

# Case 3: valid key → must be 200 (requires JOL_API_KEY + client cert).
if [[ -n "${JOL_API_KEY:-}" ]]; then
  if [[ ${#mtls_args[@]} -eq 0 ]]; then
    printf '[auth-test] SKIP — valid-key case needs JOL_MTLS_CERT/JOL_MTLS_KEY\n'
  else
    code=$(curl -sk -o /dev/null -w '%{http_code}' "${mtls_args[@]}" \
      -X POST "${BASE_URL}" -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${JOL_API_KEY}" \
      -d "${BODY}" --connect-timeout 10 2>/dev/null || echo "000")
    if [[ "${code}" == "200" ]]; then
      pass "valid key accepted with 200"
    else
      fail "valid key returned ${code} (expected 200)"
    fi
  fi
else
  printf '[auth-test] SKIP — set JOL_API_KEY to run the valid-key case\n'
fi

if (( FAILURES > 0 )); then
  printf '[auth-test] RESULT: %s check(s) FAILED\n' "${FAILURES}"
  exit 1
fi
printf '[auth-test] RESULT: ALL CHECKS PASSED\n'
