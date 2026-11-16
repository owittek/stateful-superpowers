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

# open_tagged -> number of open issues whose title carries this run's tag
open_tagged() {
  ghapi --paginate "repos/{owner}/{repo}/issues?state=open&per_page=100" \
    --jq "[.[] | select(.title | contains(\"$RUN_TAG\"))] | length" \
    | awk '{ s += $1 } END { print s + 0 }'
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
before=$(open_tagged)
assert_fails "publishing with a missing blocker is refused" "no such ref: #999999" tracker "$repo" publish-ticket "$parent" ticket "Nope $RUN_TAG" "$body" "#999999"
assert_fails "publishing under a missing parent is refused" "no such ref: #999999" tracker "$repo" publish-ticket "#999999" ticket "Nope $RUN_TAG" "$body"
assert_fails "publishing with a malformed ref is refused" "no such ref: abc" tracker "$repo" publish-ticket abc ticket "Nope $RUN_TAG" "$body"
assert_fails "publishing under a ticket is refused" "$t1 is not a parent" tracker "$repo" publish-ticket "$t1" ticket "Nope $RUN_TAG" "$body"
assert_fails "publishing with a missing body file is refused" "no such file" tracker "$repo" publish-ticket "$parent" ticket "Nope $RUN_TAG" "$TEST_ROOT/missing.md"
assert_eq "refused publishes create no issue" "$before" "$(open_tagged)"

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

finish
