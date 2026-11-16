#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/followup/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

echo "followup: done records the disposition"
repo=$(make_repo "done")
list="$repo/.superpowers/followups.md"
fu "$repo" add "first" >/dev/null
fu "$repo" add "second" --source review >/dev/null
fu "$repo" add "third" >/dev/null
fu "$repo" add "fourth" >/dev/null
assert_eq "done --as now prints nothing" "" "$(fu "$repo" "done" 1 --as now)"
assert_file_has_line "done --as now closes the item" "$list" "- [x] 1. [main] first → now"
fu "$repo" "done" 2 --as dropped
assert_file_has_line "done --as dropped keeps the source" "$list" "- [x] 2. [main] second (review) → dropped"
fu "$repo" "done" 3 --as ticket "#42"
assert_file_has_line "done --as ticket records the ref" "$list" "- [x] 3. [main] third → #42"
assert_file_has_line "other items are untouched" "$list" "- [ ] 4. [main] fourth"
assert_eq "count drops closed items" 1 "$(fu "$repo" count)"

echo "followup: numbers are never reused"
fu "$repo" "done" 4 --as ticket follow-ups/03
assert_file_has_line "a local ticket ref is recorded verbatim" "$list" "- [x] 4. [main] fourth → follow-ups/03"
assert_eq "count is 0 once all are closed" 0 "$(fu "$repo" count)"
assert_eq "add after closing the highest takes max + 1" 5 "$(fu "$repo" add "fifth")"
assert_eq "the list keeps every line" 5 "$(wc -l <"$list" | tr -d ' ')"

echo "followup: done on another branch's item"
wt="$TEST_ROOT/done-wt"
g -C "$repo" worktree add -q -b side "$wt"
fu "$wt" add "side item" >/dev/null
fu "$repo" "done" 6 --as now
assert_file_has_line "done from main closes a side-branch item" "$list" "- [x] 6. [side] side item → now"
assert_eq "git status stays clean" "" "$(g -C "$repo" status --porcelain)"

finish
