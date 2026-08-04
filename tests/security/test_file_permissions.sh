#!/usr/bin/env bash
# test_file_permissions.sh — least-privilege filesystem assertions.
# Verifies ownership/mode of the sensitive paths documented in
# docs/03-security/access-control-matrix.md. Run on llm-prod-lt01:
#   sudo tests/security/test_file_permissions.sh
set -Eeuo pipefail

FAILURES=0
pass() { printf '[perm-test] PASS — %s\n' "$*"; }
fail() { printf '[perm-test] FAIL — %s\n' "$*"; FAILURES=$((FAILURES + 1)); }

# check <path> <expected-owner> <expected-group> <expected-mode-regex>
check() {
  local path="$1" owner="$2" group="$3" mode_re="$4"
  if [[ ! -e "${path}" ]]; then
    fail "${path} missing"
    return
  fi
  local o g m
  o=$(stat -c '%U' "${path}")
  g=$(stat -c '%G' "${path}")
  m=$(stat -c '%a' "${path}")
  if [[ "${o}" == "${owner}" && "${g}" == "${group}" && "${m}" =~ ${mode_re} ]]; then
    pass "${path} → ${o}:${g} ${m}"
  else
    fail "${path} → ${o}:${g} ${m} (expected ${owner}:${group} mode ~${mode_re})"
  fi
}

# Model store: service account only; group-readable for backup tooling.
check /opt/jol/models                 ollama-svc ollama-svc '^(750|700)$'

# Ollama runtime environment (OLLAMA_HOST etc.) — no secrets, still tight.
check /etc/jol/ollama-environment     root       root       '^(644|640)$'

# API key keystore: bridge-svc only, never world-readable.
check /etc/jol/bridge/keys.db         bridge-svc bridge-svc '^(600|640)$'

# Internal CA key: offline-grade protection.
check /etc/jol/ca/ca.key              root       root       '^400$'

# Audit log directory: root-owned, append-only pipeline writes as root.
check /var/log/jol-audit              root       root       '^(750|700)$'

# Ollama binary: root-owned (installed by Ansible), exec for all.
check /usr/local/bin/ollama           root       root       '^755$'

# Service account shells must be locked (no login shells).
for acct in ollama-svc bridge-svc; do
  sh=$(getent passwd "${acct}" | cut -d: -f7)
  case "${sh}" in
    /usr/sbin/nologin|/bin/false) pass "${acct} shell locked (${sh})" ;;
    *) fail "${acct} has interactive shell: ${sh}" ;;
  esac
done

# No stray world-writable files under /opt/jol (tamper surface).
if ww=$(find /opt/jol -xdev -perm -0002 2>/dev/null); [[ -n "${ww}" ]]; then
  fail "world-writable entries under /opt/jol: ${ww}"
else
  pass "no world-writable entries under /opt/jol"
fi

# auditd rules must be immutable while loaded (-e 2).
if auditctl -s 2>/dev/null | grep -q 'enabled=2'; then
  pass "auditd immutable mode active"
else
  fail "auditd not in immutable mode (-e 2)"
fi

if (( FAILURES > 0 )); then
  printf '[perm-test] RESULT: %s check(s) FAILED\n' "${FAILURES}"
  exit 1
fi
printf '[perm-test] RESULT: ALL CHECKS PASSED\n'
