#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/tracker/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

# assert_every_op_fails REPO NEEDLE SUFFIX -> all seven ops exit non-zero with
# a one-line reason containing NEEDLE
assert_every_op_fails() {
  local repo=$1 needle=$2 suffix=$3
  assert_fails "register-parent $suffix" "$needle" tracker "$repo" register-parent spec "A title" docs/x.md abc1234
  assert_fails "publish-ticket $suffix" "$needle" tracker "$repo" publish-ticket x/00 ticket "A title" /dev/null
  assert_fails "frontier $suffix" "$needle" tracker "$repo" frontier ticket
  assert_fails "fetch $suffix" "$needle" tracker "$repo" fetch x/01
  assert_fails "claim $suffix" "$needle" tracker "$repo" claim x/01
  assert_fails "resolve $suffix" "$needle" tracker "$repo" resolve x/01 abc1234
  assert_fails "comment $suffix" "$needle" tracker "$repo" comment x/01 /dev/null
}

echo "tracker: usage"
status=0
out=$("$TRACKER" 2>&1) || status=$?
assert_eq "no op exits 2" 2 "$status"
assert_line "no op prints usage" "usage: tracker <op> [args]" "$out"
status=0
"$TRACKER" frobnicate >/dev/null 2>&1 || status=$?
assert_eq "unknown op exits 2" 2 "$status"
status=0
"$TRACKER" fetch >/dev/null 2>&1 || status=$?
assert_eq "wrong arity exits 2" 2 "$status"

echo "tracker: outside a git work tree"
outside="$TEST_ROOT/outside"
mkdir -p "$outside"
assert_fails "fetch outside a repo" "not inside a git work tree" tracker "$outside" fetch x/01

echo "tracker: missing config"
bare="$TEST_ROOT/bare"
mkdir -p "$bare"
g -C "$bare" -c init.defaultBranch=main init -q
assert_every_op_fails "$bare" "run setting-up-tracker" "without config points at setting-up-tracker"

echo "tracker: unsupported backends"
jira=$(make_repo jira "Issue tracker: Jira")
assert_every_op_fails "$jira" '"Jira" is not supported' "on an unknown backend refuses"
noh1=$(make_repo noh1)
printf 'Just prose, no heading.\n' >"$noh1/docs/agents/issue-tracker.md"
assert_every_op_fails "$noh1" "no H1 naming the issue tracker" "without a backend H1 refuses"
github=$(make_repo github "Issue tracker: GitHub")
assert_every_op_fails "$github" "not implemented yet" "on the GitHub backend reports it is not implemented"

echo "tracker: unknown refs"
local=$(make_repo local)
assert_fails "publish-ticket with an unknown parent" "no such ref: x/00" tracker "$local" publish-ticket x/00 ticket "A title" /dev/null
assert_fails "fetch of an unknown ref" "no such ref: x/01" tracker "$local" fetch x/01
assert_fails "fetch of a malformed ref" "no such ref: 11" tracker "$local" fetch 11

assert_fails "claim of an unknown ref" "no such ref: x/01" tracker "$local" claim x/01
assert_fails "frontier scoped to an unknown parent" "no such ref: x/00" tracker "$local" frontier ticket x/00
assert_eq "frontier with no tickets directory prints nothing" "" "$(tracker "$local" frontier ticket)"

finish
