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

echo "tracker: init github with a stub gh"
# A stub gh: authenticated, issues disabled, every label created; it logs
# its arguments so the test sees what init asked of it
stub="$TEST_ROOT/stub-gh"
mkdir -p "$stub"
cat >"$stub/gh" <<'STUB_EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_STUB_LOG"
case "$1 $2" in
  "auth status") exit 0 ;;
  "label create") exit 0 ;;
  "api repos/{owner}/{repo}") echo "false stub/repo"; exit 0 ;;
esac
echo "stub gh: unexpected call: $*" >&2
exit 1
STUB_EOF
chmod +x "$stub/gh"
export GH_STUB_LOG="$TEST_ROOT/stub-gh.log"
: >"$GH_STUB_LOG"
ghrepo=$(fresh_repo gh)
status=0
out=$(PATH="$stub:$PATH" tracker "$ghrepo" init github 2>"$TEST_ROOT/init-err") || status=$?
assert_eq "init github exits 0" 0 "$status"
assert_eq "init github prints ok" ok "$out"
assert_eq "with issues disabled init github prints a one-line hint" \
  "issues are disabled on stub/repo; enable them with: gh repo edit stub/repo --enable-issues" "$(cat "$TEST_ROOT/init-err")"
if grep -q '^repo edit' "$GH_STUB_LOG"; then fail "init github does not change repo settings"; else pass "init github does not change repo settings"; fi
for kind in spec ticket followup followups; do
  assert_line "init github creates the $kind label" "label create $kind --description Tracker kind: $kind" "$(cat "$GH_STUB_LOG")"
done
ghconfig="$ghrepo/docs/agents/issue-tracker.md"
assert_file_has_line "init github writes the GitHub H1" "$ghconfig" "# Issue tracker: GitHub"
assert_file_has_line "init github documents the ticket operations" "$ghconfig" "## Ticket operations"
assert_file_has_line "init github keeps the conventions section" "$ghconfig" "## Conventions"
assert_eq "init github leaves the config uncommitted" "?? docs/" "$(g -C "$ghrepo" status --porcelain)"
cp "$ghconfig" "$TEST_ROOT/ghconfig-before"
assert_eq "re-running init github prints ok" ok "$(PATH="$stub:$PATH" tracker "$ghrepo" init github 2>/dev/null)"
if cmp -s "$ghconfig" "$TEST_ROOT/ghconfig-before"; then pass "re-running init github leaves the config alone"; else fail "re-running init github leaves the config alone"; fi
assert_fails "init github over a Local Markdown config is refused" 'already names "Local Markdown"; not overwriting' tracker "$repo" init github
assert_fails "init local over the GitHub config is refused" 'already names "GitHub"; not overwriting' tracker "$ghrepo" init local
unauth=$(fresh_repo gh-unauth)
(
  gh_unauth_env
  assert_fails "init github with gh unauthenticated fails loudly" "gh is not authenticated: run gh auth login" tracker "$unauth" init github
  [ "$FAILURES" -eq 0 ]
) || FAILURES=$((FAILURES + 1))
if [ -e "$unauth/docs" ]; then fail "a failed init github writes nothing"; else pass "a failed init github writes nothing"; fi

echo "tracker: init bad backends"
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
