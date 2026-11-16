#!/usr/bin/env bash
# Checks that writing-plans' Ticket Intake runs the pattern sweep in pattern
# mode for sweep tickets, and that designing-modules allows the targeted
# helper lookup without contradicting "Scoped, not a sweep".
#
# Usage: tests/pattern-sweep/test-pickup-and-design-wiring.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLANS="$REPO_ROOT/skills/writing-plans/SKILL.md"
DESIGN="$REPO_ROOT/skills/designing-modules/SKILL.md"
SYNC="$REPO_ROOT/docs/upstream-sync.md"
FAILURES=0

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

# section FILE START_HEADING -> the lines from START_HEADING to the next "## "
section() {
  awk -v h="$2" '$0 == h { on = 1; print; next } on && /^## / { exit } on { print }' "$1"
}

echo "pattern sweep: ticket pickup and design wiring"
intake=$(section "$PLANS" "## Ticket Intake")
for n in "## Canonical choice" "pattern-sweep-prompt.md" "pattern mode"; do
  case "$intake" in *"$n"*) pass "Ticket Intake has $n" ;; *) fail "Ticket Intake has $n" ;; esac
done
abutting=$(section "$DESIGN" "### 2. Read the abutting code")
for n in "Scoped, not a sweep" "existing helper"; do
  case "$abutting" in *"$n"*) pass "designing-modules step 2 has $n" ;; *) fail "designing-modules step 2 has $n" ;; esac
done
entry=$(grep -F -- '**`writing-plans`**' "$SYNC" || true)
case "$entry" in
  *"(3)"*"pattern mode"*) pass "upstream-sync records pattern mode as writing-plans insertion point 3" ;;
  *) fail "upstream-sync records pattern mode as writing-plans insertion point 3" ;;
esac
case "$(cat "$SYNC")" in
  *"designing-modules"*"helper lookup"*) pass "upstream-sync records the designing-modules helper lookup" ;;
  *) fail "upstream-sync records the designing-modules helper lookup" ;;
esac

if [ "$FAILURES" -eq 0 ]; then echo "STATUS: PASSED"; else echo "STATUS: FAILED ($FAILURES failure(s))"; exit 1; fi
