#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/tracker/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

# assert_every_op_fails REPO NEEDLE SUFFIX -> every op but init exit non-zero with
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
  assert_fails "find $suffix" "$needle" tracker "$repo" find followup text
}

echo "tracker: usage"
status=0
out=$("$TRACKER" 2>&1) || status=$?
assert_eq "no op exits 2" 2 "$status"
assert_line "no op prints usage" "usage: tracker [-C DIR] <op> [args]" "$out"
status=0
"$TRACKER" frobnicate >/dev/null 2>&1 || status=$?
assert_eq "unknown op exits 2" 2 "$status"
status=0
"$TRACKER" fetch >/dev/null 2>&1 || status=$?
assert_eq "wrong arity exits 2" 2 "$status"
status=0
"$TRACKER" -C "$TEST_ROOT/missing" fetch x/01 >/dev/null 2>&1 || status=$?
assert_eq "-C with a missing directory exits 2" 2 "$status"
status=0
"$TRACKER" -C >/dev/null 2>&1 || status=$?
assert_eq "-C without a directory exits 2" 2 "$status"

echo "tracker: outside a git work tree"
outside="$TEST_ROOT/outside"
mkdir -p "$outside"
assert_fails "fetch outside a repo" "not inside a git work tree" tracker "$outside" fetch x/01

echo "tracker: missing config"
bare="$TEST_ROOT/bare"
mkdir -p "$bare"
g -C "$bare" -c init.defaultBranch=main init -q
assert_every_op_fails "$bare" "no tracker configured: run tracker init" "without config points at tracker init"

echo "tracker: unsupported backends"
jira=$(make_repo jira "Issue tracker: Jira")
assert_every_op_fails "$jira" '"Jira" is not supported' "on an unknown backend refuses"
noh1=$(make_repo noh1)
printf 'Just prose, no heading.\n' >"$noh1/docs/agents/issue-tracker.md"
assert_every_op_fails "$noh1" "no H1 naming the issue tracker" "without a backend H1 refuses"

echo "tracker: GitHub backend without a usable gh"
github=$(make_repo github "Issue tracker: GitHub")
(
  gh_unauth_env
  assert_every_op_fails "$github" "gh is not authenticated: run gh auth login" "with gh unauthenticated fails loudly"
  [ "$FAILURES" -eq 0 ]
) || FAILURES=$((FAILURES + 1))
(
  path_without_gh
  assert_every_op_fails "$github" "gh is not installed" "without gh fails loudly"
  [ "$FAILURES" -eq 0 ]
) || FAILURES=$((FAILURES + 1))

echo "tracker: GitHub backend when gh calls fail midway"
# A stub gh: authenticated, with canned answers for a few issues and HTTP 502
# on the calls each case below breaks; it logs every call
stub="$TEST_ROOT/stub-gh-fail"
mkdir -p "$stub"
cat >"$stub/gh" <<'STUB_EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_STUB_LOG"
fail502() { echo "gh: Server Error (HTTP 502)" >&2; exit 1; }
case "$*" in
  "auth status") exit 0 ;;
  "label create"*) exit 0 ;;
  *"issues/5/dependencies/blocked_by"*) fail502 ;;
  *"issues?state=open&per_page=100&labels=ticket"*) printf '5\tT\n' ;;
  *"issues?state=open&labels=followups"*) fail502 ;;
  "api repos/{owner}/{repo}/issues/5 "*) printf 'open\n\nticket\nT\n555\n' ;;
  "api repos/{owner}/{repo}/issues/1 "*) printf 'open\n\nspec\nP\n111\n' ;;
  "api --method POST repos/{owner}/{repo}/issues -f"*) printf '7\t777\n' ;;
  *"issues/1/sub_issues"*) fail502 ;;
  *) echo "stub gh: unexpected call: $*" >&2; exit 1 ;;
esac
STUB_EOF
chmod +x "$stub/gh"
export GH_STUB_LOG="$TEST_ROOT/stub-gh-fail.log"
: >"$GH_STUB_LOG"
stub_body="$TEST_ROOT/stub-body.md"
printf 'Body\n' >"$stub_body"
stubbed() {
  PATH="$stub:$PATH" tracker "$@"
}
assert_fails "frontier fails when a blocker lookup fails" "HTTP 502" stubbed "$github" frontier ticket
assert_fails "a follow-up publish fails when the Follow-ups lookup fails" "HTTP 502" stubbed "$github" publish-ticket - followup "A title" "$stub_body"
if grep -q '^api --method POST' "$GH_STUB_LOG"; then fail "a failed Follow-ups lookup creates nothing"; else pass "a failed Follow-ups lookup creates nothing"; fi
assert_fails "a publish whose linking fails names the created issue" "created #7 but could not link it" stubbed "$github" publish-ticket "#1" ticket "A title" "$stub_body"

echo "tracker: unknown refs"
local=$(make_repo local)
assert_fails "publish-ticket with an unknown parent" "no such ref: x/00" tracker "$local" publish-ticket x/00 ticket "A title" /dev/null
assert_fails "fetch of an unknown ref" "no such ref: x/01" tracker "$local" fetch x/01
assert_fails "fetch of a malformed ref" "no such ref: 11" tracker "$local" fetch 11

assert_fails "claim of an unknown ref" "no such ref: x/01" tracker "$local" claim x/01
assert_fails "frontier scoped to an unknown parent" "no such ref: x/00" tracker "$local" frontier ticket x/00
out=$(tracker "$local" frontier ticket)
assert_eq "frontier with no tickets directory prints nothing" "" "$out"
out=$(tracker "$local" find followup text)
assert_eq "find with no tickets directory prints nothing" "" "$out"
assert_fails "comment on an unknown ref" "no such ref: x/01" tracker "$local" comment x/01 /dev/null
assert_fails "resolve of an unknown ref" "no such ref: x/01" tracker "$local" resolve x/01 abc1234

finish
