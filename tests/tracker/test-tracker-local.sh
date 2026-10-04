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

finish
