#!/usr/bin/env bash
# Checks that finishing runs the pattern sweep before listing follow-ups and
# that the follow-up sort and the upstream-sync record know about it.
#
# Usage: tests/pattern-sweep/test-finishing-sweep-wiring.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/finishing-a-development-branch/SKILL.md"
SORT="$REPO_ROOT/skills/finishing-a-development-branch/references/follow-up-sort.md"
SYNC="$REPO_ROOT/docs/upstream-sync.md"
FAILURES=0

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

has() { # has LABEL FILE NEEDLE
  if grep -qF -- "$3" "$2"; then pass "$1 has $3"; else fail "$1 has $3"; fi
}

line_of() { grep -nF -- "$2" "$1" | head -1 | cut -d: -f1 || true; }

echo "pattern sweep: finishing wiring"
sweep=$(line_of "$SKILL" "references/pattern-sweep-prompt.md")
list=$(line_of "$SKILL" "followup list --open --orphaned")
if [ -n "$sweep" ] && [ -n "$list" ] && [ "$sweep" -lt "$list" ]; then
  pass "Step 0 dispatches the sweep before listing follow-ups"
else
  fail "Step 0 dispatches the sweep before listing follow-ups (sweep line ${sweep:-none}, list line ${list:-none})"
fi
for n in "--source sweep" "detached HEAD" "discard" "docs, tests or config"; do has SKILL.md "$SKILL" "$n"; done
for n in "## Canonical choice" "## Enforcement" "more than 10" "(sweep)" "pattern mode"; do has follow-up-sort.md "$SORT" "$n"; done
entry=$(grep -F -- '**`finishing-a-development-branch`**' "$SYNC" || true)
case "$entry" in
  *"(9)"*"pattern sweep"*) pass "upstream-sync records the sweep as finishing insertion point 9" ;;
  *) fail "upstream-sync records the sweep as finishing insertion point 9" ;;
esac

if [ "$FAILURES" -eq 0 ]; then echo "STATUS: PASSED"; else echo "STATUS: FAILED ($FAILURES failure(s))"; exit 1; fi
