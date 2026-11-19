#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/followup/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

root=$(cd "$(dirname "$0")/../.." && pwd)
skill="$root/skills/finishing-a-development-branch/SKILL.md"
sort_doc="$root/skills/finishing-a-development-branch/references/follow-up-sort.md"
routing="$root/skills/using-superpowers/SKILL.md"

has() { # has LABEL FILE FIXED-STRING
  if grep -qF -- "$3" "$2"; then pass "$1"; else fail "$1"; fi
}

echo "followup: keep is wired into finishing and routing"
step0=$(awk '/^## Step 0/ { on = 1 } /^## Step 1/ { on = 0 } on' "$skill")
if printf '%s\n' "$step0" | grep -qF 'list --kept'; then pass "Step 0 runs list --kept"; else fail "Step 0 runs list --kept"; fi
has "the sort offers keep" "$sort_doc" '**keep**'
has "keep runs FOLLOWUP keep N" "$sort_doc" '`FOLLOWUP keep N`'
has "the sort message ends with the kept reminder" "$sort_doc" 'Still kept (no action needed):'
discard=$(awk '/^## 6\. Discard path/ { on = 1 } on' "$sort_doc")
if printf '%s\n' "$discard" | grep -qF 'FOLLOWUP keep N'; then pass "discard keep uses FOLLOWUP keep"; else fail "discard keep uses FOLLOWUP keep"; fi
has "routing keeps to-dos out of memory" "$routing" 'never in memory files'

finish
