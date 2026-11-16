#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/tracker/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

# fresh_repo NAME -> path of a git repo with no tracker config
fresh_repo() {
  local repo="$TEST_ROOT/$1"
  mkdir -p "$repo"
  g -C "$repo" -c init.defaultBranch=main init -q
  printf '%s\n' "$repo"
}

echo "tracker: init local"
repo=$(fresh_repo fresh)
config="$repo/docs/agents/issue-tracker.md"
assert_eq "init local prints ok" ok "$(tracker "$repo" init local)"
assert_file_has_line "init local writes the Local Markdown H1" "$config" "# Issue tracker: Local Markdown"
assert_file_has_line "init local documents the ticket operations" "$config" "## Ticket operations"
assert_eq "init local leaves the config uncommitted" "?? docs/" "$(g -C "$repo" status --porcelain)"
cp "$config" "$TEST_ROOT/config-before"
assert_eq "re-running init local prints ok" ok "$(tracker "$repo" init local)"
if cmp -s "$config" "$TEST_ROOT/config-before"; then pass "re-running init local changes nothing"; else fail "re-running init local changes nothing"; fi
assert_eq "the written config is usable" "" "$(tracker "$repo" frontier ticket)"

echo "tracker: init refuses to overwrite"
github=$(make_repo github "Issue tracker: GitHub")
cp "$github/docs/agents/issue-tracker.md" "$TEST_ROOT/github-before"
assert_fails "init local over a GitHub config is refused" 'already names "GitHub"; not overwriting' tracker "$github" init local
if cmp -s "$github/docs/agents/issue-tracker.md" "$TEST_ROOT/github-before"; then pass "the refused init leaves the config alone"; else fail "the refused init leaves the config alone"; fi
noh1=$(make_repo noh1)
printf 'Just prose, no heading.\n' >"$noh1/docs/agents/issue-tracker.md"
assert_fails "init local over a config without H1 is refused" "has no H1 naming the issue tracker; not overwriting" tracker "$noh1" init local

echo "tracker: init github and bad backends"
assert_fails "init github is not implemented" "init github is not implemented yet (#13)" tracker "$(fresh_repo gh)" init github
status=0
tracker "$repo" init bogus >/dev/null 2>&1 || status=$?
assert_eq "init with an unknown backend exits 2" 2 "$status"
status=0
tracker "$repo" init >/dev/null 2>&1 || status=$?
assert_eq "init without a backend exits 2" 2 "$status"
outside="$TEST_ROOT/outside"
mkdir -p "$outside"
assert_fails "init outside a repo" "not inside a git work tree" tracker "$outside" init local

finish
