#!/usr/bin/env bash
# Live tests for the GitHub adapter. They run against a scratch repository
# (TRACKER_TEST_REPO, default owittek/tracker-scratch) through GH_REPO, from a
# throwaway git repo with no remote that holds the GitHub tracker config.
# Skipped, not failed, when `gh auth status` fails. Every title carries a
# unique run tag, and the EXIT trap closes every issue the run created.
set -euo pipefail

# shellcheck source=tests/tracker/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo "tracker github: SKIPPED (gh missing or not authenticated)"
  exit 0
fi

# The script under test runs with a faked HOME, so hand gh the token directly
GH_TOKEN=$(gh auth token)
export GH_TOKEN
export GH_REPO="${TRACKER_TEST_REPO:-owittek/tracker-scratch}"
RUN_TAG="trk-$(date +%s)-$$"
CREATED="$TEST_ROOT/created"
: >"$CREATED"

close_created() {
  local n
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    gh issue close "$n" --reason "not planned" >/dev/null 2>&1 || true
  done <"$CREATED"
  cleanup
}
trap close_created EXIT

# created REF -> remember REF's issue for the EXIT trap, print REF back
created() {
  printf '%s\n' "${1#\#}" >>"$CREATED"
  printf '%s\n' "$1"
}

# ghapi PATH [ARGS...] -> gh api against the scratch repo, outside any clone
ghapi() {
  (cd "$TEST_ROOT" && gh api "$@")
}

# eventually DESCRIPTION LINE CMD... -> CMD's output contains LINE within
# about 30 seconds: issue listings lag writes, so list-based ops are retried
eventually() {
  local description=$1 line=$2 out i
  shift 2
  for i in 1 2 3 4 5 6 7 8 9 10; do
    out=$("$@" 2>&1) || true
    if printf '%s\n' "$out" | grep -Fqx -- "$line"; then
      pass "$description"
      return 0
    fi
    [ "$i" = 10 ] || sleep 3
  done
  fail "$description"
  echo "    expected line: $line"
  printf '%s\n' "$out" | sed 's/^/      /'
}

# eventually_absent DESCRIPTION LINE CMD... -> CMD's output stops containing
# LINE within about 30 seconds
eventually_absent() {
  local description=$1 line=$2 out i
  shift 2
  for i in 1 2 3 4 5 6 7 8 9 10; do
    out=$("$@" 2>&1) || true
    if ! printf '%s\n' "$out" | grep -Fqx -- "$line"; then
      pass "$description"
      return 0
    fi
    [ "$i" = 10 ] || sleep 3
  done
  fail "$description"
  echo "    did not expect line: $line"
}

repo=$(make_repo github "Issue tracker: GitHub")
echo "tracker github: running against $GH_REPO, tag $RUN_TAG"

echo "tracker github: register-parent"
summary="$TEST_ROOT/summary.md"
printf 'Work is session-bound; the tracker adds a frontier and a claim.\n' >"$summary"
parent=$(created "$(tracker "$repo" register-parent spec "Spec $RUN_TAG" docs/specs/x.md 5d79504 "$summary")")
case "$parent" in
  "#"[0-9]*) pass "register-parent prints a #N ref" ;;
  *) fail "register-parent prints a #N ref"; echo "    got: $parent" ;;
esac
pn=${parent#\#}
assert_line "the parent carries the spec label" spec "$(ghapi "repos/{owner}/{repo}/issues/$pn" --jq '.labels[].name')"
pbody=$(ghapi "repos/{owner}/{repo}/issues/$pn" --jq .body)
assert_line "the parent body points at the spec" "Spec: docs/specs/x.md @ 5d79504" "$pbody"
assert_line "the parent body carries the summary" "Work is session-bound; the tracker adds a frontier and a claim." "$pbody"

echo "tracker github: publish-ticket"
body="$TEST_ROOT/body.md"
printf '## What to build\n\nThe port.\n\n## Acceptance criteria\n\n- [ ] It works\n' >"$body"
t1=$(created "$(tracker "$repo" publish-ticket "$parent" ticket "One $RUN_TAG" "$body")")
t2=$(created "$(tracker "$repo" publish-ticket "$parent" ticket "Two $RUN_TAG" "$body" "$t1")")
t3=$(created "$(tracker "$repo" publish-ticket "$parent" ticket "Three $RUN_TAG" "$body" "${t1#\#}")")
n1=${t1#\#}
n2=${t2#\#}
n3=${t3#\#}
assert_eq "the parent has the three tickets as sub-issues" "$(printf '%s\n%s\n%s' "$n1" "$n2" "$n3")" \
  "$(ghapi "repos/{owner}/{repo}/issues/$pn/sub_issues" --jq '.[].number')"
assert_line "tickets carry the ticket label" ticket "$(ghapi "repos/{owner}/{repo}/issues/$n2" --jq '.labels[].name')"
assert_eq "the second is blocked by the first" "$n1" "$(ghapi "repos/{owner}/{repo}/issues/$n2/dependencies/blocked_by" --jq '.[].number')"
assert_eq "the third is blocked by the first" "$n1" "$(ghapi "repos/{owner}/{repo}/issues/$n3/dependencies/blocked_by" --jq '.[].number')"
assert_eq "the first has no blockers" "" "$(ghapi "repos/{owner}/{repo}/issues/$n1/dependencies/blocked_by" --jq '.[].number')"
assert_fails "publishing with a missing blocker is refused" "no such ref: #999999" tracker "$repo" publish-ticket "$parent" ticket "Nope $RUN_TAG" "$body" "#999999"
assert_fails "publishing under a missing parent is refused" "no such ref: #999999" tracker "$repo" publish-ticket "#999999" ticket "Nope $RUN_TAG" "$body"
assert_fails "publishing with a malformed ref is refused" "no such ref: abc" tracker "$repo" publish-ticket abc ticket "Nope $RUN_TAG" "$body"
assert_fails "publishing under a ticket is refused" "$t1 is not a parent" tracker "$repo" publish-ticket "$t1" ticket "Nope $RUN_TAG" "$body"
assert_fails "publishing with a missing body file is refused" "no such file" tracker "$repo" publish-ticket "$parent" ticket "Nope $RUN_TAG" "$TEST_ROOT/missing.md"
d4=$(created "$(tracker "$repo" publish-ticket "$parent" decision "Four $RUN_TAG" "$body")")
assert_eq "refused publishes create no issue" "#$((n3 + 1))" "$d4"

echo "tracker github: fetch"
out=$(tracker "$repo" fetch "$t2")
assert_line "fetch prints the ref" "ref: $t2" "$out"
assert_line "fetch prints the kind" "kind: ticket" "$out"
assert_line "fetch prints the title" "title: Two $RUN_TAG" "$out"
assert_line "fetch prints the state" "state: ready" "$out"
assert_line "fetch prints no assignee" "assignee: none" "$out"
assert_line "fetch prints the parent" "parent: $parent" "$out"
assert_line "fetch prints the blockers" "blockers: $t1" "$out"
assert_eq "fetch separates fields from body with one blank line" "## What to build" "$(printf '%s\n' "$out" | sed -n '9p')"
assert_line "fetch prints the body" "- [ ] It works" "$out"
out=$(tracker "$repo" fetch "$pn")
assert_line "fetch accepts a bare number" "ref: $parent" "$out"
assert_line "fetch on the parent prints its kind" "kind: spec" "$out"
assert_line "fetch on the parent prints open" "state: open" "$out"
assert_line "fetch on the parent has no parent" "parent: none" "$out"
assert_line "fetch on the parent has no blockers" "blockers: none" "$out"
assert_fails "fetch of an unknown ref" "no such ref: #999999" tracker "$repo" fetch "#999999"

echo "tracker github: frontier"
assert_eq "frontier lists only the unblocked ticket" "$(printf '%s\t%s' "$t1" "One $RUN_TAG")" "$(tracker "$repo" frontier ticket "$parent")"
assert_eq "frontier filters by kind" "$(printf '%s\t%s' "$d4" "Four $RUN_TAG")" "$(tracker "$repo" frontier decision "$parent")"
eventually "frontier without a parent includes the ticket" "$(printf '%s\t%s' "$t1" "One $RUN_TAG")" tracker "$repo" frontier ticket
assert_no_line "frontier without a parent skips blocked tickets" "$(printf '%s\t%s' "$t2" "Two $RUN_TAG")" "$(tracker "$repo" frontier ticket)"

echo "tracker github: claim"
me=$(gh api user --jq .login)
assert_eq "claim prints ok" ok "$(tracker "$repo" claim "$t1")"
assert_eq "claim assigns the current user" "$me" "$(ghapi "repos/{owner}/{repo}/issues/$n1" --jq '.assignees[].login')"
assert_eq "claim by the same user twice succeeds" ok "$(tracker "$repo" claim "$t1")"
assert_eq "a repeated claim keeps one assignee" "$me" "$(ghapi "repos/{owner}/{repo}/issues/$n1" --jq '.assignees[].login')"
assert_line "fetch shows the claim" "state: claimed" "$(tracker "$repo" fetch "$t1")"
assert_line "fetch shows the assignee" "assignee: $me" "$(tracker "$repo" fetch "$t1")"
assert_eq "frontier is empty for the parent after the claim" "" "$(tracker "$repo" frontier ticket "$parent")"
# A gh that reports someone else as the current user makes the real
# assignee "another user"
other_bin="$TEST_ROOT/other-user-bin"
mkdir -p "$other_bin"
printf '#!/usr/bin/env bash\nif [ "$1 $2" = "api user" ]; then echo someone-else; exit 0; fi\nexec %q "$@"\n' "$(command -v gh)" >"$other_bin/gh"
chmod +x "$other_bin/gh"
as_someone_else() {
  PATH="$other_bin:$PATH" tracker "$@"
}
assert_fails "claim on a ticket assigned to another names them" "$t1 is claimed by $me" as_someone_else "$repo" claim "$t1"
assert_eq "the refused claim leaves the assignee alone" "$me" "$(ghapi "repos/{owner}/{repo}/issues/$n1" --jq '.assignees[].login')"
assert_fails "claim on a parent is refused" "$parent is a parent, not a ticket" tracker "$repo" claim "$parent"
assert_fails "claim of an unknown ref" "no such ref: #999999" tracker "$repo" claim "#999999"

echo "tracker github: comment"
note="$TEST_ROOT/note.md"
printf 'PR opened: https://example.test/pr/1\n' >"$note"
assert_eq "comment prints ok" ok "$(tracker "$repo" comment "$t1" "$note")"
assert_line "comment posts the text" "PR opened: https://example.test/pr/1" "$(ghapi "repos/{owner}/{repo}/issues/$n1/comments" --jq '.[].body')"
assert_fails "comment with a missing text file is refused" "no such file" tracker "$repo" comment "$t1" "$TEST_ROOT/missing.md"
assert_fails "comment on an unknown ref" "no such ref: #999999" tracker "$repo" comment "#999999" "$note"

echo "tracker github: resolve"
assert_eq "resolve prints ok" ok "$(tracker "$repo" resolve "$t1" "merge abc1234")"
assert_eq "resolve closes the issue" closed "$(ghapi "repos/{owner}/{repo}/issues/$n1" --jq .state)"
assert_line "resolve comments what resolved it" "Resolved by merge abc1234" "$(ghapi "repos/{owner}/{repo}/issues/$n1/comments" --jq '.[].body')"
assert_line "fetch shows done" "state: done" "$(tracker "$repo" fetch "$t1")"
assert_eq "frontier lists both others after the resolve" "$(printf '%s\t%s\n%s\t%s' "$t2" "Two $RUN_TAG" "$t3" "Three $RUN_TAG")" "$(tracker "$repo" frontier ticket "$parent")"
assert_fails "claim on a done ticket is refused" "$t1 is done" tracker "$repo" claim "$t1"
assert_fails "resolve of an unknown ref" "no such ref: #999999" tracker "$repo" resolve "#999999" x

echo "tracker github: standing Follow-ups parent"
fbody="$TEST_ROOT/followup-body.md"
printf '## What\n\nThe frontier ignores Stale Blockers %s.\n\n## Acceptance criteria\n\n- [ ] Fixed\n' "$RUN_TAG" >"$fbody"
fu1=$(created "$(tracker "$repo" publish-ticket - followup "Retry flaky claim $RUN_TAG" "$fbody")")
fpn=$(ghapi "repos/{owner}/{repo}/issues/${fu1#\#}/parent" --jq .number)
# A Follow-ups parent newer than this run's first issue was created by it
if [ "$fpn" -gt "$pn" ]; then created "#$fpn" >/dev/null; fi
assert_eq "the Follow-ups parent is titled Follow-ups" "Follow-ups" "$(ghapi "repos/{owner}/{repo}/issues/$fpn" --jq .title)"
assert_eq "the Follow-ups parent carries the followups label" followups "$(ghapi "repos/{owner}/{repo}/issues/$fpn" --jq '.labels[].name')"
assert_eq "the Follow-ups parent is open" open "$(ghapi "repos/{owner}/{repo}/issues/$fpn" --jq .state)"
assert_line "the follow-up carries the followup label" followup "$(ghapi "repos/{owner}/{repo}/issues/${fu1#\#}" --jq '.labels[].name')"
fu2=$(created "$(tracker "$repo" publish-ticket - followup "Docs typo in fetch $RUN_TAG" "$body" "$fu1")")
assert_eq "the second follow-up reuses the parent" "$fpn" "$(ghapi "repos/{owner}/{repo}/issues/${fu2#\#}/parent" --jq .number)"
assert_eq "the second follow-up is blocked by the first" "${fu1#\#}" "$(ghapi "repos/{owner}/{repo}/issues/${fu2#\#}/dependencies/blocked_by" --jq '.[].number')"
out=$(tracker "$repo" fetch "#$fpn")
assert_line "fetch on the Follow-ups parent prints its kind" "kind: followups" "$out"
assert_line "fetch on the Follow-ups parent prints open" "state: open" "$out"
assert_fails "parent - with another kind is refused" "parent - is only for kind followup" tracker "$repo" publish-ticket - ticket "Nope $RUN_TAG" "$body"

echo "tracker github: find"
fu1_line=$(printf '%s\t%s' "$fu1" "Retry flaky claim $RUN_TAG")
eventually "find matches the title case-insensitively" "$fu1_line" tracker "$repo" find followup "FLAKY CLAIM $RUN_TAG"
eventually "find matches the body" "$fu1_line" tracker "$repo" find followup "stale blockers $RUN_TAG"
assert_eq "find matches another ticket's body only by its own text" "$(printf '%s\t%s' "$fu2" "Docs typo in fetch $RUN_TAG")" "$(tracker "$repo" find followup "typo in fetch $RUN_TAG")"
assert_eq "find filters by kind" "" "$(tracker "$repo" find ticket "flaky claim $RUN_TAG")"
assert_eq "find matches literally, not as a pattern" "" "$(tracker "$repo" find followup "flaky.claim $RUN_TAG")"
status=0
out=$(tracker "$repo" find followup "no such words $RUN_TAG") || status=$?
assert_eq "find with no match prints nothing" "" "$out"
assert_eq "find with no match exits 0" 0 "$status"
tracker "$repo" resolve "$fu1" "merge 4444444" >/dev/null
eventually_absent "find skips closed issues" "$fu1_line" tracker "$repo" find followup "flaky claim $RUN_TAG"

finish
