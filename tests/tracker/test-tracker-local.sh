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

finish
