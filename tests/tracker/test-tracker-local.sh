#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/tracker/helpers.sh
. "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

repo=$(make_repo local)
tickets="$repo/docs/superpowers/tickets"

echo "tracker: register-parent"
summary="$TEST_ROOT/summary.md"
printf 'Work is session-bound; the tracker adds a frontier and a claim.\n' >"$summary"
parent=$(tracker "$repo" register-parent spec "Tracker Bridge: Design" docs/superpowers/specs/2026-10-04-tracker-bridge-design.md 5d79504 "$summary")
assert_eq "register-parent prints the parent ref" "tracker-bridge-design/00" "$parent"
pfile="$tickets/tracker-bridge-design/00-spec.md"
assert_file_exists "parent file is 00-<kind>.md under the slug directory" "$pfile"
assert_file_has_line "parent title line" "$pfile" "# 00: Tracker Bridge: Design"
assert_file_has_line "parent kind" "$pfile" "Kind: spec"
assert_file_has_line "parent status" "$pfile" "Status: open"
assert_file_has_line "parent spec pointer" "$pfile" "Spec: docs/superpowers/specs/2026-10-04-tracker-bridge-design.md @ 5d79504"
assert_file_has_line "parent summary" "$pfile" "Work is session-bound; the tracker adds a frontier and a claim."
assert_file_has_line "parent tickets heading" "$pfile" "## Tickets"
assert_eq "register-parent leaves the file uncommitted" "?? docs/superpowers/" "$(g -C "$repo" status --porcelain)"
assert_fails "registering the same title twice is refused" "parent already registered: tracker-bridge-design/00" tracker "$repo" register-parent spec "Tracker Bridge: Design" docs/x.md 0000000
assert_fails "registering with a missing summary file is refused" "no such file" tracker "$repo" register-parent spec "Another" docs/x.md 0000000 "$TEST_ROOT/missing.md"
bare_parent=$(tracker "$repo" register-parent spec "Bare" docs/y.md 1111111)
assert_eq "the summary file is optional" "bare/00" "$bare_parent"
assert_file_has_line "a parent without summary still has the tickets heading" "$tickets/bare/00-spec.md" "## Tickets"

echo "tracker: publish-ticket"
body="$TEST_ROOT/body.md"
printf '## What to build\n\nThe port.\n\n## Acceptance criteria\n\n- [ ] It works\n' >"$body"
t1=$(tracker "$repo" publish-ticket "$parent" ticket "Local adapter" "$body")
t2=$(tracker "$repo" publish-ticket "$parent" ticket "GitHub adapter" "$body" "$t1")
t3=$(tracker "$repo" publish-ticket "$parent" ticket "Setup wizard" "$body" docs/superpowers/tickets/tracker-bridge-design/01-local-adapter.md)
assert_eq "first ticket ref" "tracker-bridge-design/01" "$t1"
assert_eq "second ticket ref" "tracker-bridge-design/02" "$t2"
assert_eq "third ticket ref" "tracker-bridge-design/03" "$t3"
f1="$tickets/tracker-bridge-design/01-local-adapter.md"
f2="$tickets/tracker-bridge-design/02-github-adapter.md"
f3="$tickets/tracker-bridge-design/03-setup-wizard.md"
assert_file_exists "ticket 1 file" "$f1"
assert_file_exists "ticket 2 file" "$f2"
assert_file_exists "ticket 3 file" "$f3"
assert_eq "one parent file" 1 "$(find "$tickets/tracker-bridge-design" -name '00-*.md' | wc -l | tr -d ' ')"
assert_eq "three ticket files" 3 "$(find "$tickets/tracker-bridge-design" -name '[0-9][0-9]-*.md' ! -name '00-*' | wc -l | tr -d ' ')"
assert_file_has_line "ticket 1 title" "$f1" "# 01: Local adapter"
assert_file_has_line "ticket 1 kind" "$f1" "Kind: ticket"
assert_file_has_line "ticket 1 parent" "$f1" "Parent: tracker-bridge-design/00"
assert_file_has_line "ticket 1 has no blockers" "$f1" "Blocked by: None (can start immediately)"
assert_file_has_line "ticket 1 is ready" "$f1" "Status: ready"
assert_file_has_line "ticket 1 keeps the body" "$f1" "- [ ] It works"
assert_file_has_line "ticket 2 parent" "$f2" "Parent: tracker-bridge-design/00"
assert_file_has_line "ticket 2 blocked by 1" "$f2" "Blocked by: tracker-bridge-design/01"
assert_file_has_line "ticket 2 is ready" "$f2" "Status: ready"
assert_file_has_line "ticket 3 blocked by 1 given as a path" "$f3" "Blocked by: tracker-bridge-design/01"
assert_file_has_line "ticket 3 is ready" "$f3" "Status: ready"
assert_file_has_line "parent lists ticket 1" "$pfile" "- 01-local-adapter.md"
assert_file_has_line "parent lists ticket 2" "$pfile" "- 02-github-adapter.md"
assert_file_has_line "parent lists ticket 3" "$pfile" "- 03-setup-wizard.md"
t4=$(tracker "$repo" publish-ticket "$parent" ticket "Integration run" "$body" "$t2" "$t3")
f4="$tickets/tracker-bridge-design/04-integration-run.md"
assert_eq "fourth ticket ref" "tracker-bridge-design/04" "$t4"
assert_file_has_line "several blockers are comma-separated" "$f4" "Blocked by: tracker-bridge-design/02, tracker-bridge-design/03"
assert_fails "publishing under a missing parent is refused" "no such ref: nope/00" tracker "$repo" publish-ticket nope/00 ticket "Nope" "$body"
assert_fails "publishing with a missing blocker is refused" "no such ref: tracker-bridge-design/09" tracker "$repo" publish-ticket "$parent" ticket "Nope" "$body" tracker-bridge-design/09
assert_fails "publishing under a ticket instead of a parent is refused" "is not a parent" tracker "$repo" publish-ticket "$t1" ticket "Nope" "$body"
assert_fails "publishing with a missing body file is refused" "no such file" tracker "$repo" publish-ticket "$parent" ticket "Nope" "$TEST_ROOT/missing.md"
assert_eq "a refused publish writes nothing" 4 "$(find "$tickets/tracker-bridge-design" -name '[0-9][0-9]-*.md' ! -name '00-*' | wc -l | tr -d ' ')"

echo "tracker: fetch"
out=$(tracker "$repo" fetch "$t2")
assert_line "fetch prints the ref" "ref: tracker-bridge-design/02" "$out"
assert_line "fetch prints the kind" "kind: ticket" "$out"
assert_line "fetch prints the title" "title: GitHub adapter" "$out"
assert_line "fetch prints the state" "state: ready" "$out"
assert_line "fetch prints no assignee" "assignee: none" "$out"
assert_line "fetch prints the parent" "parent: tracker-bridge-design/00" "$out"
assert_line "fetch prints the blockers" "blockers: tracker-bridge-design/01" "$out"
assert_line "fetch prints the body" "## What to build" "$out"
assert_line "fetch prints the body's criteria" "- [ ] It works" "$out"
assert_no_line "fetch does not repeat header lines in the body" "Status: ready" "$out"
assert_eq "fetch separates fields from body with one blank line" "## What to build" "$(printf '%s\n' "$out" | sed -n '9p')"
out=$(tracker "$repo" fetch "$t4")
assert_line "fetch lists several blockers space-separated" "blockers: tracker-bridge-design/02 tracker-bridge-design/03" "$out"
out=$(tracker "$repo" fetch "$parent")
assert_line "fetch on the parent prints its kind" "kind: spec" "$out"
assert_line "fetch on the parent prints open" "state: open" "$out"
assert_line "fetch on the parent has no parent" "parent: none" "$out"
assert_line "fetch on the parent has no blockers" "blockers: none" "$out"
assert_line "fetch on the parent prints the spec pointer" "Spec: docs/superpowers/specs/2026-10-04-tracker-bridge-design.md @ 5d79504" "$out"
assert_line "fetch on the parent lists children in the body" "- 01-local-adapter.md" "$out"
out=$(tracker "$repo" fetch docs/superpowers/tickets/tracker-bridge-design/02-github-adapter.md)
assert_line "fetch accepts a file path as the ref" "ref: tracker-bridge-design/02" "$out"
out=$(tracker "$repo" fetch tracker-bridge-design/02-github-adapter)
assert_line "fetch accepts a ref with its slug suffix" "ref: tracker-bridge-design/02" "$out"

echo "tracker: frontier"
tracker "$repo" publish-ticket "$bare_parent" ticket "Other work" "$body" >/dev/null
assert_eq "frontier lists only the unblocked, unclaimed ticket" "$(printf 'tracker-bridge-design/01\tLocal adapter')" "$(tracker "$repo" frontier ticket "$parent")"
assert_eq "frontier without a parent spans every parent" "$(printf 'bare/01\tOther work\ntracker-bridge-design/01\tLocal adapter')" "$(tracker "$repo" frontier ticket)"
out=$(tracker "$repo" frontier decision "$parent")
assert_eq "frontier filters by kind" "" "$out"

echo "tracker: claim"
g -C "$repo" add -- "$pfile"
assert_eq "claim prints ok" ok "$(tracker "$repo" claim "$t1")"
assert_file_has_line "claim sets the status" "$f1" "Status: claimed"
assert_file_has_line "claim records the assignee" "$f1" "Assignee: Test Bot"
assert_file_has_line "claim keeps the body" "$f1" "- [ ] It works"
assert_eq "claim commits the ticket file" "chore(tracker): claim tracker-bridge-design/01" "$(g -C "$repo" log -1 --format=%s)"
assert_eq "claim leaves the ticket file clean" "" "$(g -C "$repo" status --porcelain -- "$f1")"
assert_eq "claim commits only the ticket file" "docs/superpowers/tickets/tracker-bridge-design/01-local-adapter.md" "$(g -C "$repo" diff-tree --no-commit-id --name-only -r HEAD)"
assert_eq "claim leaves other staged files staged" "A  docs/superpowers/tickets/tracker-bridge-design/00-spec.md" "$(g -C "$repo" status --porcelain -- "$pfile")"
head=$(g -C "$repo" rev-parse HEAD)
assert_eq "claim by the same claimant twice succeeds" ok "$(tracker "$repo" claim "$t1")"
assert_eq "a repeated claim adds no commit" "$head" "$(g -C "$repo" rev-parse HEAD)"
out=$(tracker "$repo" fetch "$t1")
assert_line "fetch shows the claimed state" "state: claimed" "$out"
assert_line "fetch shows the assignee" "assignee: Test Bot" "$out"
out=$(tracker "$repo" frontier ticket "$parent")
assert_eq "frontier is empty after the claim" "" "$out"
g -C "$repo" config user.name "Other Dev"
assert_fails "claim on a ticket claimed by another names them" "tracker-bridge-design/01 is claimed by Test Bot" tracker "$repo" claim "$t1"
g -C "$repo" config --unset user.name
assert_fails "claim without a git identity is refused" "git user.name is not set" tracker "$repo" claim "$t2"
g -C "$repo" config user.name "Test Bot"
assert_fails "claim on a parent is refused" "tracker-bridge-design/00 is a parent, not a ticket" tracker "$repo" claim "$parent"

echo "tracker: comment"
note="$TEST_ROOT/note.md"
printf 'PR opened: https://example.test/pr/1\n' >"$note"
assert_eq "comment prints ok" ok "$(tracker "$repo" comment "$t1" "$note")"
assert_file_has_line "comment adds the heading" "$f1" "## Comments"
assert_file_has_line "comment appends the text" "$f1" "PR opened: https://example.test/pr/1"
assert_file_has_line "comment is dated and attributed" "$f1" "### $(date +%Y-%m-%d) Test Bot"
assert_eq "comment does not commit" " M docs/superpowers/tickets/tracker-bridge-design/01-local-adapter.md" "$(g -C "$repo" status --porcelain -- "$f1")"
printf 'Second note' >"$note"
tracker "$repo" comment "$t1" "$note" >/dev/null
assert_eq "the Comments heading appears once" 1 "$(grep -c '^## Comments$' "$f1")"
assert_file_has_line "later comments append under it" "$f1" "Second note"
assert_eq "the file ends with a newline" "" "$(tail -c 1 "$f1")"
assert_line "fetch keeps the comments in the body" "Second note" "$(tracker "$repo" fetch "$t1")"
assert_fails "comment with a missing text file is refused" "no such file" tracker "$repo" comment "$t1" "$TEST_ROOT/missing.md"

echo "tracker: resolve"
assert_eq "resolve prints ok" ok "$(tracker "$repo" resolve "$t1" "merge abc1234")"
assert_file_has_line "resolve sets done" "$f1" "Status: done"
assert_file_has_line "resolve keeps the assignee" "$f1" "Assignee: Test Bot"
assert_file_has_line "resolve records what resolved it" "$f1" "Resolved by merge abc1234"
assert_eq "resolve commits the ticket file" "chore(tracker): resolve tracker-bridge-design/01" "$(g -C "$repo" log -1 --format=%s)"
assert_eq "resolve leaves the ticket file clean" "" "$(g -C "$repo" status --porcelain -- "$f1")"
assert_line "fetch shows done" "state: done" "$(tracker "$repo" fetch "$t1")"
assert_eq "frontier lists the other two after the resolve" "$(printf 'tracker-bridge-design/02\tGitHub adapter\ntracker-bridge-design/03\tSetup wizard')" "$(tracker "$repo" frontier ticket "$parent")"
assert_fails "claim on a done ticket is refused" "tracker-bridge-design/01 is done" tracker "$repo" claim "$t1"

echo "tracker: standing Follow-ups parent"
fbody="$TEST_ROOT/followup-body.md"
printf '## What\n\nThe frontier ignores Stale Blockers.\n\n## Acceptance criteria\n\n- [ ] Fixed\n' >"$fbody"
fu1=$(tracker "$repo" publish-ticket - followup "Retry flaky claim" "$fbody")
assert_eq "the first follow-up lands under follow-ups" "follow-ups/01" "$fu1"
fpfile="$tickets/follow-ups/00-followups.md"
assert_file_exists "the Follow-ups parent is created on first use" "$fpfile"
assert_file_has_line "Follow-ups parent title" "$fpfile" "# 00: Follow-ups"
assert_file_has_line "Follow-ups parent kind" "$fpfile" "Kind: followups"
assert_file_has_line "Follow-ups parent status" "$fpfile" "Status: open"
if grep -q '^Spec:' "$fpfile"; then fail "Follow-ups parent points at no spec"; else pass "Follow-ups parent points at no spec"; fi
fu1file="$tickets/follow-ups/01-retry-flaky-claim.md"
assert_file_has_line "follow-up parent line" "$fu1file" "Parent: follow-ups/00"
assert_file_has_line "follow-up kind" "$fu1file" "Kind: followup"
fu2=$(tracker "$repo" publish-ticket - followup "Docs typo in fetch" "$body" "$fu1")
assert_eq "the second follow-up reuses the parent" "follow-ups/02" "$fu2"
assert_eq "still one Follow-ups parent" 1 "$(find "$tickets/follow-ups" -name '00-*.md' | wc -l | tr -d ' ')"
assert_file_has_line "Follow-ups parent lists the first" "$fpfile" "- 01-retry-flaky-claim.md"
assert_file_has_line "Follow-ups parent lists the second" "$fpfile" "- 02-docs-typo-in-fetch.md"
out=$(tracker "$repo" fetch follow-ups/00)
assert_line "fetch on the Follow-ups parent prints its kind" "kind: followups" "$out"
assert_line "fetch on the Follow-ups parent prints open" "state: open" "$out"
assert_fails "parent - with another kind is refused" "parent - is only for kind followup" tracker "$repo" publish-ticket - ticket "Nope" "$body"
fresh=$(make_repo fresh-followups)
assert_fails "a refused follow-up publish is refused" "no such file" tracker "$fresh" publish-ticket - followup "Nope" "$TEST_ROOT/missing.md"
if [ -e "$fresh/docs/superpowers/tickets/follow-ups" ]; then fail "a refused follow-up publish creates no parent"; else pass "a refused follow-up publish creates no parent"; fi
assert_fails "a missing blocker creates no parent either" "no such ref: x/01" tracker "$fresh" publish-ticket - followup "Nope" "$body" x/01
if [ -e "$fresh/docs/superpowers/tickets/follow-ups" ]; then fail "a bad blocker creates no parent"; else pass "a bad blocker creates no parent"; fi
clash=$(make_repo clash)
tracker "$clash" register-parent spec "Follow ups" docs/z.md 3333333 >/dev/null
assert_fails "a follow-ups directory holding another parent is refused" "follow-ups/00 is not the Follow-ups parent" tracker "$clash" publish-ticket - followup "Nope" "$body"

echo "tracker: find"
assert_eq "find matches the title case-insensitively" "$(printf 'follow-ups/01\tRetry flaky claim')" "$(tracker "$repo" find followup FLAKY)"
assert_eq "find matches the body" "$(printf 'follow-ups/01\tRetry flaky claim')" "$(tracker "$repo" find followup "stale blockers")"
assert_eq "find matches another ticket's body" "$(printf 'follow-ups/02\tDocs typo in fetch')" "$(tracker "$repo" find followup "it works")"
assert_eq "find filters by kind" "" "$(tracker "$repo" find ticket flaky)"
assert_eq "find matches literally, not as a pattern" "" "$(tracker "$repo" find followup "flaky.claim")"
status=0
out=$(tracker "$repo" find followup "no such words") || status=$?
assert_eq "find with no match prints nothing" "" "$out"
assert_eq "find with no match exits 0" 0 "$status"
tracker "$repo" resolve "$fu1" "merge 4444444" >/dev/null
assert_eq "find skips done tickets" "" "$(tracker "$repo" find followup flaky)"
status=0
tracker "$repo" find followup "" >/dev/null 2>&1 || status=$?
assert_eq "find with empty text exits 2" 2 "$status"

echo "tracker: -C DIR"
cparent=$(tracker_c "$repo" register-parent spec "Dash C" docs/c.md 2222222)
assert_eq "-C register-parent" "dash-c/00" "$cparent"
ct=$(tracker_c "$repo" publish-ticket "$cparent" ticket "Via dash C" "$body")
assert_eq "-C publish-ticket" "dash-c/01" "$ct"
assert_eq "-C frontier" "$(printf 'dash-c/01\tVia dash C')" "$(tracker_c "$repo" frontier ticket "$cparent")"
assert_line "-C fetch" "title: Via dash C" "$(tracker_c "$repo" fetch "$ct")"
assert_eq "-C claim" ok "$(tracker_c "$repo" claim "$ct")"
assert_eq "-C claim commits in the target repo" "chore(tracker): claim dash-c/01" "$(g -C "$repo" log -1 --format=%s)"
assert_eq "-C comment" ok "$(tracker_c "$repo" comment "$ct" "$note")"
assert_eq "-C resolve" ok "$(tracker_c "$repo" resolve "$ct" "merge def5678")"
assert_line "-C resolve lands in the target repo" "state: done" "$(tracker "$repo" fetch "$ct")"
assert_eq "-C find" "$(printf 'follow-ups/02\tDocs typo in fetch')" "$(tracker_c "$repo" find followup typo)"
assert_eq "-C init local on a configured repo is a no-op" ok "$(tracker_c "$repo" init local)"

finish
