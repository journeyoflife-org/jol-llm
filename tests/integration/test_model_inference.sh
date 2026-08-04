#!/usr/bin/env bash
# test_model_inference.sh — end-to-end inference test.
# Sends a canned chat completion through the full path
# (Caddy mTLS → bridge auth → Ollama) and asserts:
#   * HTTP 200 with a non-empty assistant message
#   * wall-clock latency under the SLA ceiling (default 5 s for a
#     single-token-bounded canned prompt; model warm)
# Uses only canned test strings — never client content
# (security/policies/data-retention-policy.md §3).
set -Eeuo pipefail

HOST_IP="${HOST_IP:-10.40.10.21}"
API_PORT="${API_PORT:-8443}"
MODEL="${MODEL:-qwen3-32b-q8_0}"
MAX_LATENCY_MS="${MAX_LATENCY_MS:-5000}"
BASE_URL="https://${HOST_IP}:${API_PORT}/v1/chat/completions"

for v in JOL_API_KEY JOL_MTLS_CERT JOL_MTLS_KEY; do
  if [[ -z "${!v:-}" ]]; then
    printf '[inference-test] ERROR — %s is required\n' "${v}" >&2
    exit 2
  fi
done

BODY=$(cat <<'EOF'
{
  "model": "__MODEL__",
  "messages": [{"role": "user", "content": "Reply with the single word: OK"}],
  "max_tokens": 8,
  "stream": false
}
EOF
)
BODY="${BODY/__MODEL__/${MODEL}}"

printf '[inference-test] POST %s model=%s\n' "${BASE_URL}" "${MODEL}"

start_ms=$(date +%s%3N)
resp_file=$(mktemp)
trap 'rm -f "${resp_file}"' EXIT

code=$(curl -sk -o "${resp_file}" -w '%{http_code}' \
  --cert "${JOL_MTLS_CERT}" --key "${JOL_MTLS_KEY}" \
  -H "Authorization: Bearer ${JOL_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "${BODY}" "${BASE_URL}" --connect-timeout 10 --max-time 120)
end_ms=$(date +%s%3N)
elapsed_ms=$((end_ms - start_ms))

FAILURES=0
pass() { printf '[inference-test] PASS — %s\n' "$*"; }
fail() { printf '[inference-test] FAIL — %s\n' "$*"; FAILURES=$((FAILURES + 1)); }

if [[ "${code}" == "200" ]]; then
  pass "HTTP 200 (${elapsed_ms} ms)"
else
  fail "HTTP ${code}; body: $(head -c 300 "${resp_file}")"
fi

# Non-empty assistant content (OpenAI-compatible shape).
if python3 - "${resp_file}" <<'EOF'
import json, sys
doc = json.load(open(sys.argv[1]))
content = doc["choices"][0]["message"]["content"]
assert content.strip(), "empty completion"
print(f"[inference-test] completion preview: {content.strip()[:40]!r}")
EOF
then
  pass "non-empty assistant message"
else
  fail "response missing assistant message content"
fi

if (( elapsed_ms <= MAX_LATENCY_MS )); then
  pass "latency ${elapsed_ms} ms ≤ ${MAX_LATENCY_MS} ms SLA"
else
  fail "latency ${elapsed_ms} ms > ${MAX_LATENCY_MS} ms SLA"
fi

if (( FAILURES > 0 )); then
  printf '[inference-test] RESULT: %s check(s) FAILED\n' "${FAILURES}"
  exit 1
fi
printf '[inference-test] RESULT: ALL CHECKS PASSED\n'
