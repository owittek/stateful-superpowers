#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/followup/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

echo "followup: list and count with no list file"
empty=$(make_repo empty)
assert_eq "list prints nothing" "" "$(fu "$empty" list)"
assert_eq "list --all prints nothing" "" "$(fu "$empty" list --all)"
assert_eq "count prints 0" 0 "$(fu "$empty" count)"
if [ -e "$empty/.superpowers" ]; then
  fail "read ops create no .superpowers directory"
else
  pass "read ops create no .superpowers directory"
fi

echo "followup: list filters by branch"
repo=$(make_repo list)
list="$repo/.superpowers/followups.md"
fu "$repo" add "on main" >/dev/null
feat="$TEST_ROOT/list-feat"
featx="$TEST_ROOT/list-featx"
g -C "$repo" worktree add -q -b feat "$feat"
g -C "$repo" worktree add -q -b feat-x "$featx"
fu "$feat" add "on feat" --source review >/dev/null
fu "$featx" add "on feat-x" >/dev/null
# A closed item, written the way done writes it, so --open has something to hide.
printf '%s\n' "- [x] 4. [feat] closed on feat → dropped" >>"$list"

assert_eq "list shows only the current branch, not a branch it prefixes" \
  "- [ ] 2. [feat] on feat (review)
- [x] 4. [feat] closed on feat → dropped" "$(fu "$feat" list)"
assert_eq "list --open hides closed items" "- [ ] 2. [feat] on feat (review)" "$(fu "$feat" list --open)"
assert_eq "list in the main checkout shows main's items" "- [ ] 1. [main] on main" "$(fu "$repo" list)"
assert_eq "list --all shows every branch" "$(cat "$list")" "$(fu "$feat" list --all)"
assert_eq "list --open --all shows every open item" \
  "- [ ] 1. [main] on main
- [ ] 2. [feat] on feat (review)
- [ ] 3. [feat-x] on feat-x" "$(fu "$feat" list --all --open)"
assert_eq "count counts open items across branches" 3 "$(fu "$featx" count)"

echo "followup: awkward text"
odd='a ] (b) 3. → c'
assert_eq "text with brackets, parens, digits and arrows takes the next number" 5 "$(fu "$repo" add "$odd")"
assert_file_has_line "awkward text is stored verbatim" "$list" "- [ ] 5. [main] $odd"
assert_eq "the next add still numbers after it" 6 "$(fu "$repo" add "after")"
assert_eq "git status stays clean" "" "$(g -C "$repo" status --porcelain)"

finish
