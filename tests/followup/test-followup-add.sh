#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/followup/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

echo "followup: add in the main checkout"
repo=$(make_repo add)
list="$repo/.superpowers/followups.md"
assert_eq "first add prints 1" 1 "$(fu "$repo" add "first")"
assert_file_has_line "first item is open and tagged main" "$list" "- [ ] 1. [main] first"
assert_eq "second add prints 2" 2 "$(fu "$repo" add "second" --source review)"
assert_file_has_line "source is recorded in parentheses" "$list" "- [ ] 2. [main] second (review)"
assert_eq "git status stays clean without a prior ignore rule" "" "$(g -C "$repo" status --porcelain)"

echo "followup: add from a linked worktree"
wt="$TEST_ROOT/add-wt"
g -C "$repo" worktree add -q -b feat/x "$wt"
assert_eq "add from the worktree prints the next number" 3 "$(fu "$wt" add "from wt")"
assert_file_has_line "worktree item lands in the main checkout tagged with its branch" "$list" "- [ ] 3. [feat/x] from wt"
if [ -e "$wt/.superpowers" ]; then
  fail "worktree gets no .superpowers directory"
else
  pass "worktree gets no .superpowers directory"
fi
mkdir -p "$wt/sub/dir"
assert_eq "-C a subdirectory of the worktree resolves the same list" 4 "$(fu "$wt/sub/dir" add "from subdir")"
assert_file_has_line "subdirectory item is tagged with the worktree's branch" "$list" "- [ ] 4. [feat/x] from subdir"
assert_eq "worktree git status stays clean" "" "$(g -C "$wt" status --porcelain)"

echo "followup: existing .superpowers/.gitignore"
own=$(make_repo own-ignore)
mkdir -p "$own/.superpowers"
printf 'followups.md\n.gitignore\n' >"$own/.superpowers/.gitignore"
before=$(cat "$own/.superpowers/.gitignore")
fu "$own" add "kept" >/dev/null
assert_eq "an existing .superpowers/.gitignore is left untouched" "$before" "$(cat "$own/.superpowers/.gitignore")"

finish
