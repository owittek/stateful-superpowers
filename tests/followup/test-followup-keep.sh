#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/followup/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

echo "followup: keep moves an item off its branch"
repo=$(make_repo keep)
list="$repo/.superpowers/followups.md"
feat="$TEST_ROOT/keep-feat"
g -C "$repo" worktree add -q -b feat "$feat"
fu "$feat" add "long-lived" --source review >/dev/null
fu "$feat" add "text with [*] inside" >/dev/null
fu "$feat" keep 1
assert_file_has_line "keep re-tags the item [*]" "$list" "- [ ] 1. [*] long-lived (review)"
assert_eq "the branch's list no longer shows it" "- [ ] 2. [feat] text with [*] inside" "$(fu "$feat" list --open)"
assert_eq "list --kept shows it from another branch" "- [ ] 1. [*] long-lived (review)" "$(fu "$repo" list --kept)"
assert_eq "list --all still shows it" 2 "$(fu "$repo" list --all | wc -l | tr -d ' ')"
assert_eq "count leaves kept items out" 1 "$(fu "$repo" count)"

echo "followup: kept items are never orphans"
g -C "$repo" worktree remove "$feat"
g -C "$repo" branch -q -D feat
assert_eq "list --open --orphaned shows the deleted branch's item, not the kept one" \
  "- [ ] 2. [feat] text with [*] inside" "$(fu "$repo" list --open --orphaned)"

echo "followup: closing and refusing"
printf '%s\n' "- [ ] 7. no tag here" >>"$list"
before=$(cat "$list")
assert_fails "keep an untagged hand-edited line" "no branch tag" fu "$repo" keep 7
assert_fails "keep an already kept item" "already kept" fu "$repo" keep 1
assert_fails "keep a missing item" "no follow-up 9" fu "$repo" keep 9
assert_fails "keep a bad number" "bad follow-up number" fu "$repo" keep x
assert_eq "refusals leave the list unchanged" "$before" "$(cat "$list")"
fu "$repo" "done" 1 --as dropped
assert_file_has_line "done closes a kept item" "$list" "- [x] 1. [*] long-lived (review) → dropped"
assert_eq "list --kept hides closed items" "" "$(fu "$repo" list --kept)"
assert_fails "keep a closed item" "already closed" fu "$repo" keep 1

finish
