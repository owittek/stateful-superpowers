#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/followup/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

echo "followup: backslashes in a ticket ref are stored literally"
repo=$(make_repo backslash)
list="$repo/.superpowers/followups.md"
fu "$repo" add "one" >/dev/null
fu "$repo" "done" 1 --as ticket 'GH\n#5'
assert_file_has_line "an escape sequence in REF is not expanded" "$list" '- [x] 1. [main] one → GH\n#5'
assert_eq "the list keeps one line" 1 "$(wc -l <"$list" | tr -d ' ')"

echo "followup: a hand-edited list without a trailing newline"
printf -- '- [ ] 9. [main] hand' >>"$list"
assert_eq "add after an unterminated last line takes the next number" 10 "$(fu "$repo" add "a")"
assert_eq "and the one after that too" 11 "$(fu "$repo" add "b")"
assert_file_has_line "the hand-edited item stays on its own line" "$list" "- [ ] 9. [main] hand"
assert_eq "count sees all three open items" 3 "$(fu "$repo" count)"

echo "followup: a tag with the branch's name"
g -C "$repo" checkout -q -b feat-x
fu "$repo" add "before tag" >/dev/null
g -C "$repo" tag feat-x
fu "$repo" add "after tag" >/dev/null
assert_file_has_line "items are tagged with the plain branch name" "$list" "- [ ] 13. [feat-x] after tag"
assert_eq "list still finds the branch's items" 2 "$(fu "$repo" list | wc -l | tr -d ' ')"

finish
