#!/usr/bin/env bash
# Pins the pattern sweep prompt's contract (the strings finishing and
# writing-plans rely on) and checks the synthetic fixture builder.
#
# Usage: tests/pattern-sweep/test-pattern-sweep-prompt.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROMPT="$REPO_ROOT/skills/finishing-a-development-branch/references/pattern-sweep-prompt.md"
FAILURES=0

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

echo "pattern sweep: prompt contract"
if [ -f "$PROMPT" ]; then
  for needle in '[BASE_SHA]' '[HEAD_SHA]' '[PRIOR]' '[PATTERN]' '[CANONICAL]' \
    'Kind:' 'Canonical:' 'In diff:' 'Outside diff:' 'Enforce:' 'Recommend:' \
    'helper-exists | drift | not-backported | siblings-disagree' \
    'NO FINDINGS' 'at most 5' 'Branch mode' 'Pattern mode' 'read-only' \
    'does a helper' 'more than 10'; do
    if grep -qF -- "$needle" "$PROMPT"; then pass "prompt has $needle"; else fail "prompt has $needle"; fi
  done
else
  fail "prompt exists at ${PROMPT#"$REPO_ROOT"/}"
fi

echo "pattern sweep: fixture"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
out=$(HOME="$tmp" GIT_CONFIG_NOSYSTEM=1 bash "$SCRIPT_DIR/make-fixture.sh" "$tmp/repo" 2>&1) || fail "make-fixture.sh exits 0: $out"
base=$(printf '%s\n' "$out" | sed -n 's/^BASE=//p')
head=$(printf '%s\n' "$out" | sed -n 's/^HEAD=//p')
if [ -n "$base" ] && [ -n "$head" ]; then
  pass "fixture prints BASE and HEAD"
  changed=$(git -C "$tmp/repo" diff --name-only "$base" "$head" | sort | tr '\n' ' ')
  if [ "$changed" = "src/routes/orders.ts src/tables/customer-columns.tsx " ]; then
    pass "fixture diff is exactly the two planted files"
  else
    fail "fixture diff is exactly the two planted files (got: $changed)"
  fi
else
  fail "fixture prints BASE and HEAD"
fi

if [ "$FAILURES" -eq 0 ]; then echo "STATUS: PASSED"; else echo "STATUS: FAILED ($FAILURES failure(s))"; exit 1; fi
