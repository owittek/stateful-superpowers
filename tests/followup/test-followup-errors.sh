#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/followup/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

repo=$(make_repo errors)

echo "followup: usage errors exit 2"
status=0
out=$("$FOLLOWUP" 2>&1) || status=$?
assert_eq "no op exits 2" 2 "$status"
assert_eq "no op prints usage" "usage: followup [-C DIR] add TEXT [--source S]" "$(printf '%s\n' "$out" | head -1)"
assert_status "unknown op exits 2" 2 fu "$repo" frobnicate
assert_status "list with an unknown flag exits 2" 2 fu "$repo" list --bogus
assert_status "add with an unknown flag exits 2" 2 fu "$repo" add "x" --bogus
assert_status "add without text exits 2" 2 fu "$repo" add
assert_status "add --source without a value exits 2" 2 fu "$repo" add "x" --source
assert_status "count with an argument exits 2" 2 fu "$repo" count extra
assert_status "done without --as exits 2" 2 fu "$repo" "done" 1
assert_status "done --as ticket without a ref exits 2" 2 fu "$repo" "done" 1 --as ticket
assert_status "done --as an unknown disposition exits 2" 2 fu "$repo" "done" 1 --as later
assert_status "done --as now with a stray argument exits 2" 2 fu "$repo" "done" 1 --as now extra
assert_status "-C a missing directory exits 2" 2 fu "$TEST_ROOT/nope" count

echo "followup: failures exit 1 with a one-line reason"
outside="$TEST_ROOT/outside"
mkdir -p "$outside"
assert_fails "add outside a git repo" "not inside a git work tree" fu "$outside" add "x"
assert_fails "list outside a git repo" "not inside a git work tree" fu "$outside" list
assert_fails "count outside a git repo" "not inside a git work tree" fu "$outside" count
assert_fails "empty text" "must not be empty" fu "$repo" add ""
assert_fails "multi-line text" "single line" fu "$repo" add "two
lines"
assert_fails "multi-line source" "single line" fu "$repo" add "x" --source "a
b"
fu "$repo" add "one" >/dev/null
assert_fails "non-numeric N" "bad follow-up number: abc" fu "$repo" "done" abc --as now
assert_fails "zero N" "bad follow-up number: 0" fu "$repo" "done" 0 --as now
assert_fails "unknown N" "no follow-up 99" fu "$repo" "done" 99 --as now
fu "$repo" "done" 1 --as now
assert_fails "closing a closed item" "follow-up 1 is already closed" fu "$repo" "done" 1 --as dropped
empty=$(make_repo errors-empty)
assert_fails "done with no list file" "no follow-up 1" fu "$empty" "done" 1 --as now

echo "followup: detached HEAD"
g -C "$repo" checkout -q --detach
assert_fails "add on a detached HEAD" "detached HEAD" fu "$repo" add "x"
assert_fails "list on a detached HEAD" "detached HEAD" fu "$repo" list
assert_eq "list --all works on a detached HEAD" "- [x] 1. [main] one → now" "$(fu "$repo" list --all)"
assert_eq "count works on a detached HEAD" 0 "$(fu "$repo" count)"

finish
