# Tracker Port on the Local Markdown Adapter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the seven tracker-port operations as one `tracker` script whose Local Markdown adapter keeps a parent file and numbered ticket files under `docs/superpowers/tickets/`, with shell tests covering every op.

**Ticket:** #11 — `docs/superpowers/specs/2026-10-04-tracker-bridge-design.md` @ `5d79504`, sections "Tracker port" and "Local adapter". Acceptance criteria are the ticket's six checkboxes; nothing else is in scope.

**Architecture:** One bash script, `skills/picking-up-ticket/scripts/tracker`, in three layers: shared helpers (ref resolution, header-block parsing and editing, comment appending, single-file commits), the Local Markdown adapter (`local_<op>` functions, one per operation), and a dispatcher that reads the backend from the H1 of `docs/agents/issue-tracker.md` and calls `<adapter>_<op>`. The GitHub adapter (ticket #13) later adds `github_<op>` functions behind the same dispatcher; this plan leaves that branch as a one-line refusal. Tests live in `tests/tracker/` in the style of `tests/hooks/test-session-start.sh`, drive the script inside throwaway git repos, and run from `tests/tracker/run-tests.sh`.

**Tech Stack:** bash 3.2-compatible shell, git, POSIX awk/sed/grep. No other dependencies (the plugin is zero-dependency by design: no jq, no node).

## Global Constraints

- Work happens in the worktree `/Users/oli/code/super-claude/superpowers/.claude/worktrees/ticket-11-tracker-port-local` on branch `ticket/11-tracker-port-local`, cut from `next` at `3ec058c`. All paths below are relative to that root. Never leave it.
- **Scope is ticket #11 only.** Out of scope: the GitHub adapter (#13), the setup wizard (#12), the three skills and seam edits (#14, #15, #16). Do not create `skills/picking-up-ticket/SKILL.md`; ticket #15 owns it. Nothing in the repo requires a `SKILL.md` per skill directory (`tests/opencode/test-plugin-loading.sh` only counts the files that exist).
- Do not touch skill prose, `README.md`, `CONTEXT.md`, `docs/agents/issue-tracker.md` (this repo's own config says GitHub, which is correct), or the version files.
- **Portability.** The script must run on macOS `/bin/bash` 3.2 and on Linux: no associative arrays, no `mapfile`, no `${var,,}`, no `"${array[@]}"` on a possibly-empty array under `set -u`. BSD and GNU userland both: no `sed -i`, no `grep -P`, no `sed -z`, no `readlink -f`. Only `git`, `awk`, `sed`, `grep`, `tr`, `cut`, `date`, `basename`, `dirname`, `tail`, `wc`, `find`.
- **Script conventions** (match `skills/subagent-driven-development/scripts/sdd-workspace`): `#!/usr/bin/env bash`, `set -euo pipefail`, a header comment that explains purpose and design, usage errors exit 2 with usage on stderr, failures exit 1 with exactly one line on stderr, results only on stdout. The file is executable (`chmod +x`); git tracks the bit.
- **Bash pitfalls to avoid.** Never `local x=$(cmd)` (masks the exit status under `set -e`); declare, then assign. Never nest a fallible command substitution inside another command's argument list (a `die` inside `$(...)` only exits the subshell); assign it to a variable first so `set -e` sees the failure.
- **Output contract, verbatim** (tests and sibling tickets depend on these strings): refs are `<parent-slug>/<NN>`; `claim`, `resolve`, `comment` print `ok`; `frontier` prints `<ref><TAB><title>` per line; `fetch` prints seven `key: value` lines (`ref`, `kind`, `title`, `state`, `assignee`, `parent`, `blockers`), a blank line, then the body; status values are `ready`, `claimed`, `done` on children and `open` on the parent; error reasons are `no docs/agents/issue-tracker.md: run setting-up-tracker first`, `issue tracker "<X>" is not supported by this script; follow docs/agents/issue-tracker.md by hand`, `GitHub backend is not implemented yet; run gh by hand per docs/agents/issue-tracker.md`, `no such ref: <ref>`, `<ref> is claimed by <name>`, `<ref> is done`; commit subjects are `chore(tracker): claim <ref>` and `chore(tracker): resolve <ref>`.
- **Test conventions** (match `tests/hooks/test-session-start.sh`): `pass`/`fail` helpers, a `FAILURES` counter, `mktemp -d` root with `trap cleanup EXIT`, final `STATUS: PASSED` or `STATUS: FAILED (N failure(s))` with exit 1. Tests need no network and no shellcheck. Run test scripts by path (`./tests/tracker/run-tests.sh`), not as `bash <file>`: this session's worktree guard refuses `bash <file>` invocations.
- **Editing the script across tasks.** Every task inserts code at one of three markers already present after Task 1: `# --- shared helpers ---`, `# --- Local Markdown adapter ---`, `# --- dispatch ---`. Helpers go under the first, `local_<op>` functions under the second, nothing under the third. Bash resolves function names at call time, so order within a section does not matter, but every function must sit above the dispatch block.
- **Editing the tests across tasks.** `tests/tracker/test-tracker-local.sh` is one linear scenario; each task appends its block immediately before the final `finish` line. `tests/tracker/test-tracker-errors.sh` gains one line per op under its `tracker: unknown refs` section (created in Task 3). Blocks reference variables set by earlier blocks (`repo`, `tickets`, `parent`, `pfile`, `bare_parent`, `body`, `t1`…`t4`, `f1`…`f4`); keep those names.
- **Lint.** `scripts/lint-shell.sh` needs shellcheck and shfmt, which are not installed on this machine. Write shellcheck-clean code anyway (quote every expansion, `local` for every function variable, no unquoted `$(...)` in `for … in`, `# shellcheck disable=` only with a reason). If `command -v shellcheck` succeeds where you run, lint the shell files before the final commit.
- Commit after every task, only the task's files. Conventional Commits (`feat(tracker):`), a body that says what the change does, and the trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Never add `.claude/` or `.superpowers/` to a commit.
- Today is 2026-10-04. Comment attribution lines use `date +%Y-%m-%d` at run time, never a hard-coded date.

---

## Decisions this plan makes beyond the spec text

The spec fixes the operations, the file layout and the ticket template; it leaves the local ref grammar and some state details implicit. These are the choices, stated so a reviewer can object to them rather than discover them:

1. **Ref grammar.** A ref is `<parent-slug>/<NN>`. `<parent-slug>/00` is the parent; children are `01`…`99`. The resolver also accepts `<parent-slug>/<NN>-<slug>`, a path under `docs/superpowers/tickets/`, and a `.md` suffix, so a pasted filename works. Every op prints refs in the canonical two-part form. Consequence for ticket #16: a local ticket branch is `ticket/<parent-slug>/<NN>-<slug>`, which contains a slash and dashes; the finishing seam's ref extraction must not assume `ticket/<digits>-…`.
2. **Two header lines the template does not show.** `Kind: <kind>` on every file (GitHub carries kind as a label; `frontier` must filter by it locally) and `Assignee: <name>` written on claim (GitHub carries the assignee natively; the "claimed by another" refusal must name them). Both are tracker state, not content, so they sit in the header block with `Status:`.
3. **The header block.** Line 1 is `# <NN>: <title>`, line 2 is blank, then `Key: value` lines until the first blank line, then the body. Scripts read and rewrite only the header block; the body is the publisher's text and is never rewritten.
4. **Parent file.** `00-<kind>.md` with header `Kind`, `Status: open`; body is `Spec: <path> @ <sha>`, the optional summary paragraph, then `## Tickets` with one `- <NN>-<slug>.md` line per child, appended by `publish-ticket`.
5. **Claimant identity** is `git config user.name` (claim commits, so an identity is required anyway). Empty name → refuse.
6. **`resolve` records its argument.** Besides `Status: done` it appends `Resolved by <what>` under `## Comments`, mirroring the GitHub close comment; otherwise the argument would be dropped.
7. **Comments** append as `### <YYYY-MM-DD> <user.name>` followed by the text, under a `## Comments` heading created at the end of the file on first use.
8. **Only `claim` and `resolve` commit**, as the spec says, and they commit only the ticket file (`git commit -- <file>`), leaving the rest of the index untouched. `register-parent`, `publish-ticket` and `comment` leave their changes in the work tree for the caller to commit.

---

## File Structure

| File | Responsibility |
|---|---|
| `skills/picking-up-ticket/scripts/tracker` | **New.** The port: usage and `die`, shared helpers, the Local Markdown adapter, backend detection and dispatch. |
| `tests/tracker/helpers.sh` | **New.** Sourced by both test files: fixture repos with a chosen config H1, a `tracker` runner with a clean `HOME`, a `g` git wrapper with the same environment, assertions, `finish`. |
| `tests/tracker/test-tracker-errors.sh` | **New.** Usage, outside-a-repo, missing config, unsupported backends, GitHub-not-implemented, unknown refs: every op exits non-zero with one line. |
| `tests/tracker/test-tracker-local.sh` | **New.** One scenario through all seven ops in a temp repo, in the order of the ticket's acceptance criteria. |
| `tests/tracker/run-tests.sh` | **New.** The entry point: runs both test files. |

### Acceptance criteria → tasks

| Criterion | Covered by |
|---|---|
| 1. register-parent + three publish-ticket calls → one parent file, three ticket files, correct `Parent`, `Blocked by`, `Status` lines | Tasks 2, 3 |
| 2. frontier lists only the unblocked, unclaimed ticket; nothing after claim; the other two after resolve | Tasks 5, 6, 8 |
| 3. claim twice by the same claimant succeeds; claim on another's ticket exits non-zero naming them | Task 6 |
| 4. fetch prints body, state, blockers, parent; comment appends under a Comments heading; resolve sets done; claim and resolve commit | Tasks 4, 6, 7, 8 |
| 5. every op exits non-zero with a one-line reason on missing config, unknown backend, unknown ref | Task 1 (config, backend), Tasks 3–8 (refs) |
| 6. shell tests cover all seven ops and run green from the test entry point | Task 1 (entry point), every task (runs it), Task 8 (final run) |

---

## Task 1: Script skeleton, backend detection, test harness

The dispatcher, usage, and the three error exits that do not depend on any op existing. Also the test fixtures every later task builds on.

**Files:**
- Create: `skills/picking-up-ticket/scripts/tracker`
- Create: `tests/tracker/helpers.sh`
- Create: `tests/tracker/test-tracker-errors.sh`
- Create: `tests/tracker/run-tests.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: globals `ROOT` (repo top level), `CONFIG`, `TICKETS` (`$ROOT/docs/superpowers/tickets`), set before any op runs; `die MESSAGE` (one line on stderr, exit 1); `usage` (exit 2); dispatch to `"${adapter}_${op//-/_}" "$@"` with `adapter=local`. Test helpers: `make_repo NAME [H1]`, `tracker REPO OP ARGS…`, `g GIT_ARGS…`, `assert_eq`, `assert_line`, `assert_no_line`, `assert_file_exists`, `assert_file_has_line`, `assert_fails DESCRIPTION NEEDLE CMD…`, `finish`.

- [ ] **Step 1: Write the shared test helpers**

Create `tests/tracker/helpers.sh`:

```bash
#!/usr/bin/env bash
# Shared fixtures and assertions for the tracker-port tests. Source it; do not
# run it. Every test runs the script under test inside a throwaway git repo
# with a faked HOME so the developer's global git config (signing, identity)
# cannot leak into the run.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TRACKER="$REPO_ROOT/skills/picking-up-ticket/scripts/tracker"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
FAKE_HOME="$TEST_ROOT/home"
mkdir -p "$FAKE_HOME"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

# g GIT_ARGS... -> git with the same clean environment the script under test sees
g() {
  HOME="$FAKE_HOME" GIT_CONFIG_NOSYSTEM=1 git "$@"
}

# make_repo NAME [H1] -> path of a fresh repo whose docs/agents/issue-tracker.md
# carries the given H1 (default: the Local Markdown backend), committed
make_repo() {
  local repo="$TEST_ROOT/$1" h1="${2:-Issue tracker: Local Markdown}"
  mkdir -p "$repo/docs/agents"
  g -C "$repo" -c init.defaultBranch=main init -q
  g -C "$repo" config user.name "Test Bot"
  g -C "$repo" config user.email "test@example.com"
  printf '# %s\n\nTracker config for the tests.\n' "$h1" >"$repo/docs/agents/issue-tracker.md"
  g -C "$repo" add -A
  g -C "$repo" commit -q -m "chore: tracker config"
  printf '%s\n' "$repo"
}

# tracker REPO OP [ARGS...] -> run the script under test from inside REPO
tracker() {
  local repo=$1
  shift
  (cd "$repo" && HOME="$FAKE_HOME" GIT_CONFIG_NOSYSTEM=1 "$TRACKER" "$@")
}

# assert_eq DESCRIPTION EXPECTED ACTUAL
assert_eq() {
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1"
    echo "    expected: $2"
    echo "    actual:   $3"
  fi
}

# assert_line DESCRIPTION LINE TEXT -> TEXT contains LINE as a whole line
assert_line() {
  if printf '%s\n' "$3" | grep -Fqx -- "$2"; then
    pass "$1"
  else
    fail "$1"
    echo "    expected line: $2"
    echo "    in:"
    printf '%s\n' "$3" | sed 's/^/      /'
  fi
}

# assert_no_line DESCRIPTION LINE TEXT
assert_no_line() {
  if printf '%s\n' "$3" | grep -Fqx -- "$2"; then
    fail "$1"
    echo "    did not expect line: $2"
  else
    pass "$1"
  fi
}

# assert_file_exists DESCRIPTION FILE
assert_file_exists() {
  if [ -f "$2" ]; then
    pass "$1"
  else
    fail "$1"
    echo "    missing: $2"
  fi
}

# assert_file_has_line DESCRIPTION FILE LINE
assert_file_has_line() {
  if grep -Fqx -- "$3" "$2" 2>/dev/null; then
    pass "$1"
  else
    fail "$1"
    echo "    expected line: $3"
    echo "    in: $2"
    sed 's/^/      /' "$2" 2>/dev/null || echo "      (file missing)"
  fi
}

# assert_fails DESCRIPTION NEEDLE CMD... -> CMD exits non-zero and prints
# exactly one line (stdout+stderr) containing NEEDLE
assert_fails() {
  local description=$1 needle=$2 out status=0 lines
  shift 2
  out=$("$@" 2>&1) || status=$?
  lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  if [ "$status" -eq 0 ]; then
    fail "$description"
    echo "    expected a non-zero exit"
  elif [ "$lines" -ne 1 ]; then
    fail "$description"
    echo "    expected a one-line reason, got $lines lines:"
    printf '%s\n' "$out" | sed 's/^/      /'
  elif printf '%s' "$out" | grep -Fq -- "$needle"; then
    pass "$description"
  else
    fail "$description"
    echo "    expected the reason to contain: $needle"
    printf '%s\n' "$out" | sed 's/^/      /'
  fi
}

finish() {
  if [ "$FAILURES" -gt 0 ]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
  fi
  echo "STATUS: PASSED"
}
```

- [ ] **Step 2: Write the failing error tests**

Create `tests/tracker/test-tracker-errors.sh`:

```bash
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

finish
```

- [ ] **Step 3: Write the entry point and make the test files executable**

Create `tests/tracker/run-tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/test-tracker-errors.sh"
```

Then:

```bash
chmod +x tests/tracker/run-tests.sh tests/tracker/test-tracker-errors.sh
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: many `[FAIL]` lines (the script does not exist yet, so every invocation exits 127 with `No such file or directory`), ending in `STATUS: FAILED (N failure(s))` and exit 1.

- [ ] **Step 5: Write the script skeleton**

Create `skills/picking-up-ticket/scripts/tracker`:

```bash
#!/usr/bin/env bash
# Tracker port: the seven operations behind which the issue tracker's backend
# is hidden (register-parent, publish-ticket, frontier, fetch, claim, resolve,
# comment). Skills call this instead of re-deriving tracker incantations, so
# one caller cannot drift from another.
#
# The backend is the H1 of docs/agents/issue-tracker.md:
#   "# Issue tracker: Local Markdown"  -> files under docs/superpowers/tickets/
#   "# Issue tracker: GitHub"          -> gh (not implemented yet)
# Any other H1 means "other": this script refuses and the skills follow the
# config's prose by hand.
#
# Local Markdown layout. One directory per parent,
# docs/superpowers/tickets/<parent-slug>/, holding 00-<kind>.md (the parent)
# and NN-<slug>.md (its children, numbered from 01). A ref is
# "<parent-slug>/<NN>"; "<parent-slug>/00" is the parent. Each file is a title
# line "# NN: <title>", a blank line, a header block of "Key: value" lines, a
# blank line, then the body. The header block is the tracker's state (ADR
# 0002: the tracker holds graph and state, never content): Kind, Parent,
# Blocked by, Status, Assignee. Status is ready | claimed | done on a child and
# open on the parent. The body is what the publisher wrote and is never
# rewritten; comments append under "## Comments".
#
# Every op prints a machine-readable result on stdout and exits non-zero with
# a one-line reason on stderr (2 for usage errors, 1 otherwise). claim and
# resolve commit the one file they change so other sessions see the
# transition; a concurrent claim surfaces as a commit conflict.
#
# Usage: tracker <op> [args]   (run with no arguments for the op list)
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: tracker <op> [args]
  register-parent KIND TITLE SPEC_PATH SHA [SUMMARY_FILE]  -> ref
  publish-ticket  PARENT KIND TITLE BODY_FILE [BLOCKER...]  -> ref
  frontier        KIND [PARENT]                             -> ref<TAB>title per line
  fetch           REF                                       -> fields, blank line, body
  claim           REF                                       -> ok
  resolve         REF WHAT                                  -> ok
  comment         REF TEXT_FILE                             -> ok
EOF
  exit 2
}

die() {
  echo "$*" >&2
  exit 1
}

# --- shared helpers ---------------------------------------------------------

# --- Local Markdown adapter -------------------------------------------------

# --- dispatch ---------------------------------------------------------------

[ $# -ge 1 ] || usage
op=$1
shift
case "$op" in
  register-parent) [ $# -ge 4 ] && [ $# -le 5 ] || usage ;;
  publish-ticket) [ $# -ge 4 ] || usage ;;
  frontier) [ $# -ge 1 ] && [ $# -le 2 ] || usage ;;
  fetch | claim) [ $# -eq 1 ] || usage ;;
  resolve | comment) [ $# -eq 2 ] || usage ;;
  *) usage ;;
esac

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git work tree"
CONFIG="$ROOT/docs/agents/issue-tracker.md"
TICKETS="$ROOT/docs/superpowers/tickets"
[ -f "$CONFIG" ] || die "no docs/agents/issue-tracker.md: run setting-up-tracker first"

h1=$(grep -m 1 '^# ' "$CONFIG" | sed 's/^# //; s/[[:space:]]*$//' || true)
backend=${h1#"Issue tracker: "}
case "$backend" in
  "Local Markdown") adapter=local ;;
  GitHub) die "GitHub backend is not implemented yet; run gh by hand per docs/agents/issue-tracker.md" ;;
  "") die "docs/agents/issue-tracker.md has no H1 naming the issue tracker; run setting-up-tracker" ;;
  *) die "issue tracker \"$backend\" is not supported by this script; follow docs/agents/issue-tracker.md by hand" ;;
esac

"${adapter}_${op//-/_}" "$@"
```

Then:

```bash
chmod +x skills/picking-up-ticket/scripts/tracker
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: every line `[PASS]`, ending in `STATUS: PASSED`, exit 0.

- [ ] **Step 7: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/helpers.sh tests/tracker/test-tracker-errors.sh tests/tracker/run-tests.sh
git ls-files -s skills/picking-up-ticket/scripts/tracker tests/tracker/run-tests.sh tests/tracker/test-tracker-errors.sh
```

The second command must print three lines starting with `100755` (executable bits recorded). `tests/tracker/helpers.sh` is sourced, not run, and stays `100644`. Then:

```bash
git commit -m "$(cat <<'EOF'
feat(tracker): add the tracker port script with backend detection

The seven-op dispatcher reads the backend from the H1 of
docs/agents/issue-tracker.md and refuses missing config, unknown
trackers and the not-yet-implemented GitHub backend with one-line
reasons. Test fixtures run the script inside throwaway repos with a
clean HOME.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `register-parent`

Creates `docs/superpowers/tickets/<slug>/00-<kind>.md` and prints `<slug>/00`.

**Files:**
- Modify: `skills/picking-up-ticket/scripts/tracker` (helpers section, adapter section)
- Create: `tests/tracker/test-tracker-local.sh`
- Modify: `tests/tracker/run-tests.sh`

**Interfaces:**
- Consumes: `die`, `TICKETS` (Task 1).
- Produces: `slugify TITLE` → lowercase `[a-z0-9]` runs joined by `-`, at most 60 characters, dies on an empty result; `local_register_parent KIND TITLE SPEC_PATH SHA [SUMMARY_FILE]` → prints `<slug>/00`, refuses a second registration of the same slug with `parent already registered: <slug>/00`. Parent file layout per decision 4.

- [ ] **Step 1: Write the failing scenario test**

Create `tests/tracker/test-tracker-local.sh`:

```bash
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
assert_eq "register-parent leaves the file uncommitted" "?? docs/superpowers/tickets/" "$(g -C "$repo" status --porcelain)"
assert_fails "registering the same title twice is refused" "parent already registered: tracker-bridge-design/00" tracker "$repo" register-parent spec "Tracker Bridge: Design" docs/x.md 0000000
assert_fails "registering with a missing summary file is refused" "no such file" tracker "$repo" register-parent spec "Another" docs/x.md 0000000 "$TEST_ROOT/missing.md"
bare_parent=$(tracker "$repo" register-parent spec "Bare" docs/y.md 1111111)
assert_eq "the summary file is optional" "bare/00" "$bare_parent"
assert_file_has_line "a parent without summary still has the tickets heading" "$tickets/bare/00-spec.md" "## Tickets"

finish
```

Add it to `tests/tracker/run-tests.sh` after the errors line:

```bash
bash "$SCRIPT_DIR/test-tracker-local.sh"
```

Then:

```bash
chmod +x tests/tracker/test-tracker-local.sh
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: the errors file passes; the scenario file aborts at the first `tracker … register-parent` call with `local_register_parent: command not found` and a non-zero exit (no `STATUS:` line from it).

- [ ] **Step 3: Implement `slugify` and `local_register_parent`**

Insert under `# --- shared helpers ---`:

```bash
# slugify TITLE -> lowercase, [a-z0-9] runs joined by "-", at most 60 chars
slugify() {
  local slug
  slug=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-60 | sed -E 's/-+$//')
  [ -n "$slug" ] || die "cannot derive a slug from title: $1"
  printf '%s\n' "$slug"
}
```

Insert under `# --- Local Markdown adapter ---`:

```bash
local_register_parent() {
  local kind=$1 title=$2 spec_path=$3 sha=$4 summary_file=${5:-}
  local slug dir file summary=""
  slug=$(slugify "$title")
  dir="$TICKETS/$slug"
  [ ! -e "$dir" ] || die "parent already registered: $slug/00"
  if [ -n "$summary_file" ]; then
    [ -f "$summary_file" ] || die "no such file: $summary_file"
    summary=$(cat "$summary_file")
  fi
  mkdir -p "$dir"
  file="$dir/00-$kind.md"
  {
    printf '# 00: %s\n\n' "$title"
    printf 'Kind: %s\nStatus: open\n\n' "$kind"
    printf 'Spec: %s @ %s\n\n' "$spec_path" "$sha"
    [ -z "$summary" ] || printf '%s\n\n' "$summary"
    printf '## Tickets\n'
  } >"$file"
  printf '%s/00\n' "$slug"
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: both files end in `STATUS: PASSED`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/test-tracker-local.sh tests/tracker/run-tests.sh
git commit -m "$(cat <<'EOF'
feat(tracker): register-parent on the Local Markdown adapter

Creates docs/superpowers/tickets/<slug>/00-<kind>.md with the spec
pointer, optional summary and an empty Tickets list, and prints the
parent ref <slug>/00. A second registration of the same title is
refused.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `publish-ticket`

Numbers the child, writes the header block and body, validates blockers, lists the child under the parent.

**Files:**
- Modify: `skills/picking-up-ticket/scripts/tracker` (helpers section, adapter section)
- Modify: `tests/tracker/test-tracker-local.sh` (insert before `finish`)
- Modify: `tests/tracker/test-tracker-errors.sh` (new section before `finish`)

**Interfaces:**
- Consumes: `slugify`, `die`, `TICKETS`.
- Produces: `resolve_ref REF` → absolute file path or `die "no such ref: REF"`; `canonical_ref FILE` → `<slug>/NN`; `next_number DIR` → next two-digit child number; `ensure_trailing_newline FILE`; `add_child PARENT_FILE CHILD_FILENAME`; `local_publish_ticket PARENT KIND TITLE BODY_FILE [BLOCKER…]` → prints the new ref. Ticket file layout: `# NN: title`, blank, `Kind:`, `Parent:`, `Blocked by:` (`None (can start immediately)` or canonical refs joined by `, `), `Status: ready`, blank, body verbatim.

- [ ] **Step 1: Write the failing tests**

Insert into `tests/tracker/test-tracker-local.sh` before `finish`:

```bash
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
```

Insert into `tests/tracker/test-tracker-errors.sh` before `finish`:

```bash
echo "tracker: unknown refs"
local=$(make_repo local)
assert_fails "publish-ticket with an unknown parent" "no such ref: x/00" tracker "$local" publish-ticket x/00 ticket "A title" /dev/null
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: the errors file ends `STATUS: FAILED (1 failure(s))` (`publish-ticket with an unknown parent` sees `local_publish_ticket: command not found` instead of `no such ref`); `run-tests.sh` stops there with exit 1 because of `set -e`.

- [ ] **Step 3: Implement the ref helpers and `local_publish_ticket`**

Insert under `# --- shared helpers ---` (after `slugify`):

```bash
# resolve_ref REF -> absolute path of the ref's file, or die. Accepts
# "<slug>/NN" and "<slug>/NN-<anything>", with or without the tickets-dir
# prefix and the ".md" suffix, so a pasted filename works as a ref.
resolve_ref() {
  local ref=$1 rel dir nn file
  rel=${ref#"$TICKETS"/}
  rel=${rel#docs/superpowers/tickets/}
  rel=${rel%.md}
  case "$rel" in
    */[0-9][0-9] | */[0-9][0-9]-*) ;;
    *) die "no such ref: $ref" ;;
  esac
  dir=${rel%%/*}
  nn=${rel#*/}
  nn=${nn:0:2}
  file=$(printf '%s\n' "$TICKETS/$dir/$nn"-*.md | head -n 1)
  [ -f "$file" ] || die "no such ref: $ref"
  printf '%s\n' "$file"
}

# canonical_ref FILE -> "<slug>/NN"
canonical_ref() {
  local base
  base=$(basename "$1")
  printf '%s/%s\n' "$(basename "$(dirname "$1")")" "${base:0:2}"
}

# next_number DIR -> the next zero-padded child number in DIR
next_number() {
  local max=0 f n
  for f in "$1"/[0-9][0-9]-*.md; do
    [ -e "$f" ] || continue
    n=$(basename "$f")
    n=$((10#${n:0:2}))
    if [ "$n" -gt "$max" ]; then max=$n; fi
  done
  [ "$max" -lt 99 ] || die "$(basename "$1") already has 99 children"
  printf '%02d\n' "$((max + 1))"
}

ensure_trailing_newline() {
  if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then echo >>"$1"; fi
}

# add_child PARENT_FILE CHILD_FILENAME -> append "- CHILD_FILENAME" to the
# list under the parent's "## Tickets" heading, after its last item; create
# the heading at the end of the file when it is missing
add_child() {
  local file=$1 tmp="$1.tmp"
  awk -v line="- $2" '
    { lines[NR] = $0 }
    /^## Tickets$/ && !start { start = NR }
    END {
      if (!start) {
        for (i = 1; i <= NR; i++) print lines[i]
        print ""; print "## Tickets"; print ""; print line
        exit
      }
      at = start
      for (i = start + 1; i <= NR; i++) {
        if (lines[i] ~ /^- /) at = i
        else if (lines[i] ~ /^## /) break
      }
      for (i = 1; i <= NR; i++) {
        print lines[i]
        if (i == at) { if (at == start) print ""; print line }
      }
    }
  ' "$file" >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}
```

Insert under `# --- Local Markdown adapter ---` (after `local_register_parent`):

```bash
local_publish_ticket() {
  local parent=$1 kind=$2 title=$3 body_file=$4
  shift 4
  local parent_file parent_ref dir slug nn name file blocked="" ref blocker_file
  parent_file=$(resolve_ref "$parent")
  case "$(basename "$parent_file")" in
    00-*) ;;
    *) die "$parent is not a parent" ;;
  esac
  [ -f "$body_file" ] || die "no such file: $body_file"
  for ref in "$@"; do
    blocker_file=$(resolve_ref "$ref")
    ref=$(canonical_ref "$blocker_file")
    blocked="${blocked:+$blocked, }$ref"
  done
  [ -n "$blocked" ] || blocked="None (can start immediately)"
  parent_ref=$(canonical_ref "$parent_file")
  dir=$(dirname "$parent_file")
  slug=$(slugify "$title")
  nn=$(next_number "$dir")
  name="$nn-$slug.md"
  file="$dir/$name"
  {
    printf '# %s: %s\n\n' "$nn" "$title"
    printf 'Kind: %s\nParent: %s\nBlocked by: %s\nStatus: ready\n\n' "$kind" "$parent_ref" "$blocked"
    cat "$body_file"
  } >"$file"
  ensure_trailing_newline "$file"
  add_child "$parent_file" "$name"
  canonical_ref "$file"
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: both files end in `STATUS: PASSED`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/test-tracker-local.sh tests/tracker/test-tracker-errors.sh
git commit -m "$(cat <<'EOF'
feat(tracker): publish-ticket with numbering, blockers and the parent list

Writes NN-<slug>.md with Kind, Parent, Blocked by and Status header
lines above the body file's text, validates every blocker ref before
writing anything, and lists the child under the parent's Tickets
heading. Refs resolve from "<slug>/NN", a slugged form, or a pasted
path.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `fetch`

Prints the header fields a caller needs, a blank line, then the body.

**Files:**
- Modify: `skills/picking-up-ticket/scripts/tracker` (helpers section, adapter section)
- Modify: `tests/tracker/test-tracker-local.sh` (insert before `finish`)
- Modify: `tests/tracker/test-tracker-errors.sh` (under `tracker: unknown refs`)

**Interfaces:**
- Consumes: `resolve_ref`, `canonical_ref`.
- Produces: `title_of FILE`; `header_field FILE KEY` → the value or empty; `body_of FILE` → everything after the header block; `blockers_of FILE` → one canonical ref per line, nothing when unblocked; `local_fetch REF` → lines `ref:`, `kind:`, `title:`, `state:`, `assignee:`, `parent:`, `blockers:` (space-separated refs), blank line, body. Missing values print `none`.

- [ ] **Step 1: Write the failing tests**

Insert into `tests/tracker/test-tracker-local.sh` before `finish`:

```bash
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
```

Insert into `tests/tracker/test-tracker-errors.sh` under `tracker: unknown refs`:

```bash
assert_fails "fetch of an unknown ref" "no such ref: x/01" tracker "$local" fetch x/01
assert_fails "fetch of a malformed ref" "no such ref: 11" tracker "$local" fetch 11
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: the errors file ends `STATUS: FAILED (2 failure(s))` with `local_fetch: command not found` in the printed reasons; exit 1.

- [ ] **Step 3: Implement the header-block readers and `local_fetch`**

Insert under `# --- shared helpers ---` (after `add_child`):

```bash
# title_of FILE -> the title without its "# NN: " prefix
title_of() {
  sed -n '1s/^# [0-9][0-9]: //p' "$1"
}

# header_field FILE KEY -> KEY's value from the header block, or ""
header_field() {
  awk -v key="$2: " '
    NR <= 2 { next }
    /^$/ { exit }
    index($0, key) == 1 { print substr($0, length(key) + 1); exit }
  ' "$1"
}

# body_of FILE -> everything after the header block
body_of() {
  awk 'NR <= 2 { next } !body { if ($0 == "") body = 1; next } { print }' "$1"
}

# blockers_of FILE -> one blocker ref per line, nothing when unblocked
blockers_of() {
  local raw
  raw=$(header_field "$1" "Blocked by")
  case "$raw" in None* | "") return 0 ;; esac
  printf '%s\n' "$raw" | tr ',' '\n' | tr -d ' ' | sed '/^$/d'
}
```

Insert under `# --- Local Markdown adapter ---` (after `local_publish_ticket`):

```bash
local_fetch() {
  local file ref kind title state assignee parent blockers
  file=$(resolve_ref "$1")
  ref=$(canonical_ref "$file")
  kind=$(header_field "$file" Kind)
  title=$(title_of "$file")
  state=$(header_field "$file" Status)
  assignee=$(header_field "$file" Assignee)
  parent=$(header_field "$file" Parent)
  blockers=$(blockers_of "$file" | tr '\n' ' ' | sed 's/ $//')
  printf 'ref: %s\nkind: %s\ntitle: %s\nstate: %s\nassignee: %s\nparent: %s\nblockers: %s\n\n' \
    "$ref" "$kind" "$title" "$state" "${assignee:-none}" "${parent:-none}" "${blockers:-none}"
  body_of "$file"
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: both files end in `STATUS: PASSED`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/test-tracker-local.sh tests/tracker/test-tracker-errors.sh
git commit -m "$(cat <<'EOF'
feat(tracker): fetch prints header fields and body

Seven "key: value" lines (ref, kind, title, state, assignee, parent,
blockers), a blank line, then the body as the publisher wrote it.
Missing values print "none" so callers can test for a fixed word.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `frontier`

Lists children of a kind that are `ready` and whose blockers are all `done`.

**Files:**
- Modify: `skills/picking-up-ticket/scripts/tracker` (adapter section)
- Modify: `tests/tracker/test-tracker-local.sh` (insert before `finish`)
- Modify: `tests/tracker/test-tracker-errors.sh` (under `tracker: unknown refs`)

**Interfaces:**
- Consumes: `resolve_ref`, `canonical_ref`, `header_field`, `blockers_of`, `title_of`.
- Produces: `local_frontier KIND [PARENT]` → `<ref><TAB><title>` per line, directory then number order; scoped to one parent's directory when `PARENT` is given; a blocker that does not resolve counts as open.

- [ ] **Step 1: Write the failing tests**

Insert into `tests/tracker/test-tracker-local.sh` before `finish`:

```bash
echo "tracker: frontier"
tracker "$repo" publish-ticket "$bare_parent" ticket "Other work" "$body" >/dev/null
assert_eq "frontier lists only the unblocked, unclaimed ticket" "$(printf 'tracker-bridge-design/01\tLocal adapter')" "$(tracker "$repo" frontier ticket "$parent")"
assert_eq "frontier without a parent spans every parent" "$(printf 'bare/01\tOther work\ntracker-bridge-design/01\tLocal adapter')" "$(tracker "$repo" frontier ticket)"
assert_eq "frontier filters by kind" "" "$(tracker "$repo" frontier decision "$parent")"
```

Insert into `tests/tracker/test-tracker-errors.sh` under `tracker: unknown refs`:

```bash
assert_fails "frontier scoped to an unknown parent" "no such ref: x/00" tracker "$local" frontier ticket x/00
assert_eq "frontier with no tickets directory prints nothing" "" "$(tracker "$local" frontier ticket)"
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: the errors file ends `STATUS: FAILED (1 failure(s))` (`frontier scoped to an unknown parent` sees `local_frontier: command not found`; the empty-frontier assertion passes vacuously because stdout is empty); exit 1.

- [ ] **Step 3: Implement `local_frontier`**

Insert under `# --- Local Markdown adapter ---` (after `local_fetch`):

```bash
local_frontier() {
  local kind=$1 parent_file f b bf ok
  if [ $# -eq 2 ]; then
    parent_file=$(resolve_ref "$2")
    set -- "$(dirname "$parent_file")"/[0-9][0-9]-*.md
  else
    set -- "$TICKETS"/*/[0-9][0-9]-*.md
  fi
  for f in "$@"; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in 00-*) continue ;; esac
    [ "$(header_field "$f" Kind)" = "$kind" ] || continue
    [ "$(header_field "$f" Status)" = ready ] || continue
    ok=1
    while IFS= read -r b; do
      [ -n "$b" ] || continue
      bf=$(resolve_ref "$b" 2>/dev/null) || { ok=0; break; }
      [ "$(header_field "$bf" Status)" = done ] || { ok=0; break; }
    done <<<"$(blockers_of "$f")"
    [ "$ok" = 1 ] || continue
    printf '%s\t%s\n' "$(canonical_ref "$f")" "$(title_of "$f")"
  done
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: both files end in `STATUS: PASSED`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/test-tracker-local.sh tests/tracker/test-tracker-errors.sh
git commit -m "$(cat <<'EOF'
feat(tracker): frontier lists ready, unblocked tickets by kind

One "ref<TAB>title" line per child whose Kind matches, whose Status is
ready and whose blockers are all done, across every parent or scoped to
one. A blocker that no longer resolves counts as open.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `claim`

Sets `Status: claimed` and `Assignee: <git user.name>`, commits that one file; idempotent for the same claimant, refuses another's ticket by name.

**Files:**
- Modify: `skills/picking-up-ticket/scripts/tracker` (helpers section, adapter section)
- Modify: `tests/tracker/test-tracker-local.sh` (insert before `finish`)
- Modify: `tests/tracker/test-tracker-errors.sh` (under `tracker: unknown refs`)

**Interfaces:**
- Consumes: `resolve_ref`, `canonical_ref`, `header_field`, `ROOT`.
- Produces: `set_header FILE KEY VALUE` (replace the key's line in the header block or add it at the block's end; body untouched); `git_identity` → `git config user.name` or `die`; `commit_file FILE MESSAGE` → stages and commits only that file; `local_claim REF` → `ok`; refusals `<ref> is claimed by <name>` and `<ref> is done`.

- [ ] **Step 1: Write the failing tests**

Insert into `tests/tracker/test-tracker-local.sh` before `finish`:

```bash
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
assert_eq "frontier is empty after the claim" "" "$(tracker "$repo" frontier ticket "$parent")"
g -C "$repo" config user.name "Other Dev"
assert_fails "claim on a ticket claimed by another names them" "tracker-bridge-design/01 is claimed by Test Bot" tracker "$repo" claim "$t1"
g -C "$repo" config --unset user.name
assert_fails "claim without a git identity is refused" "git user.name is not set" tracker "$repo" claim "$t2"
g -C "$repo" config user.name "Test Bot"
```

Insert into `tests/tracker/test-tracker-errors.sh` under `tracker: unknown refs`:

```bash
assert_fails "claim of an unknown ref" "no such ref: x/01" tracker "$local" claim x/01
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: the errors file ends `STATUS: FAILED (1 failure(s))` (`claim of an unknown ref` sees `local_claim: command not found`); exit 1.

- [ ] **Step 3: Implement `set_header`, `git_identity`, `commit_file`, `local_claim`**

Insert under `# --- shared helpers ---` (after `blockers_of`):

```bash
# set_header FILE KEY VALUE -> replace KEY's line in the header block, or add
# one at the block's end. Never touches the body.
set_header() {
  local file=$1 key=$2 value=$3 tmp="$1.tmp"
  awk -v key="$key" -v value="$value" '
    NR <= 2 { print; next }
    !closed && /^$/ { if (!seen) print key ": " value; closed = 1 }
    !closed && index($0, key ": ") == 1 { print key ": " value; seen = 1; next }
    { print }
  ' "$file" >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

# git_identity -> git user.name, or die: claim needs a name to record
git_identity() {
  local me
  me=$(git -C "$ROOT" config user.name || true)
  [ -n "$me" ] || die "git user.name is not set; claim needs an identity"
  printf '%s\n' "$me"
}

# commit_file FILE MESSAGE -> commit this one file, leaving the rest of the
# index and work tree alone
commit_file() {
  git -C "$ROOT" add -- "$1"
  git -C "$ROOT" commit -q -m "$2" -- "$1"
}
```

Insert under `# --- Local Markdown adapter ---` (after `local_frontier`):

```bash
local_claim() {
  local file ref me state assignee
  file=$(resolve_ref "$1")
  ref=$(canonical_ref "$file")
  me=$(git_identity)
  state=$(header_field "$file" Status)
  assignee=$(header_field "$file" Assignee)
  case "$state" in
    claimed)
      [ "$assignee" = "$me" ] || die "$ref is claimed by ${assignee:-someone else}"
      echo ok
      return 0
      ;;
    done) die "$ref is done" ;;
  esac
  set_header "$file" Status claimed
  set_header "$file" Assignee "$me"
  commit_file "$file" "chore(tracker): claim $ref"
  echo ok
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: both files end in `STATUS: PASSED`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/test-tracker-local.sh tests/tracker/test-tracker-errors.sh
git commit -m "$(cat <<'EOF'
feat(tracker): claim records the assignee and commits

Sets Status: claimed and Assignee: <git user.name> in the header block
and commits only that file so other sessions see the claim. A repeat by
the same name is a no-op; another name is refused by naming the holder;
a done ticket is refused.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: `comment`

Appends dated, attributed text under `## Comments`. Does not commit.

**Files:**
- Modify: `skills/picking-up-ticket/scripts/tracker` (helpers section, adapter section)
- Modify: `tests/tracker/test-tracker-local.sh` (insert before `finish`)
- Modify: `tests/tracker/test-tracker-errors.sh` (under `tracker: unknown refs`)

**Interfaces:**
- Consumes: `resolve_ref`, `ensure_trailing_newline`, `ROOT`.
- Produces: `append_comment FILE < text` → creates `## Comments` at the end of the file if absent, then appends `### <YYYY-MM-DD> <user.name|unknown>`, a blank line, the text; `local_comment REF TEXT_FILE` → `ok`. Task 8's `resolve` reuses `append_comment`.

- [ ] **Step 1: Write the failing tests**

Insert into `tests/tracker/test-tracker-local.sh` before `finish`:

```bash
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
```

Insert into `tests/tracker/test-tracker-errors.sh` under `tracker: unknown refs`:

```bash
assert_fails "comment on an unknown ref" "no such ref: x/01" tracker "$local" comment x/01 /dev/null
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: the errors file ends `STATUS: FAILED (1 failure(s))` (`comment on an unknown ref` sees `local_comment: command not found`); exit 1.

- [ ] **Step 3: Implement `append_comment` and `local_comment`**

Insert under `# --- shared helpers ---` (after `commit_file`):

```bash
# append_comment FILE < text -> add the text under "## Comments", dated and
# attributed to git user.name
append_comment() {
  local file=$1 who
  who=$(git -C "$ROOT" config user.name || true)
  ensure_trailing_newline "$file"
  grep -q '^## Comments$' "$file" || printf '\n## Comments\n' >>"$file"
  printf '\n### %s %s\n\n' "$(date +%Y-%m-%d)" "${who:-unknown}" >>"$file"
  cat >>"$file"
  ensure_trailing_newline "$file"
}
```

Insert under `# --- Local Markdown adapter ---` (after `local_claim`):

```bash
local_comment() {
  local file
  file=$(resolve_ref "$1")
  [ -f "$2" ] || die "no such file: $2"
  append_comment "$file" <"$2"
  echo ok
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: both files end in `STATUS: PASSED`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/test-tracker-local.sh tests/tracker/test-tracker-errors.sh
git commit -m "$(cat <<'EOF'
feat(tracker): comment appends under a Comments heading

Each comment lands as "### <date> <git user.name>" followed by the text
file's content, under a "## Comments" heading created on first use. The
change stays uncommitted for the caller, as the spec says.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: `resolve` and the final run

Sets `Status: done`, records what resolved it, commits. Then the whole suite plus the pre-existing infrastructure tests.

**Files:**
- Modify: `skills/picking-up-ticket/scripts/tracker` (adapter section)
- Modify: `tests/tracker/test-tracker-local.sh` (insert before `finish`)
- Modify: `tests/tracker/test-tracker-errors.sh` (under `tracker: unknown refs`)

**Interfaces:**
- Consumes: `resolve_ref`, `canonical_ref`, `set_header`, `append_comment`, `commit_file`.
- Produces: `local_resolve REF WHAT` → `ok`; header `Status: done`; comment `Resolved by <WHAT>`; commit `chore(tracker): resolve <ref>`.

- [ ] **Step 1: Write the failing tests**

Insert into `tests/tracker/test-tracker-local.sh` before `finish`:

```bash
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
```

Insert into `tests/tracker/test-tracker-errors.sh` under `tracker: unknown refs`:

```bash
assert_fails "resolve of an unknown ref" "no such ref: x/01" tracker "$local" resolve x/01 abc1234
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/tracker/run-tests.sh`
Expected: the errors file ends `STATUS: FAILED (1 failure(s))` (`resolve of an unknown ref` sees `local_resolve: command not found`); exit 1.

- [ ] **Step 3: Implement `local_resolve`**

Insert under `# --- Local Markdown adapter ---` (after `local_comment`):

```bash
local_resolve() {
  local file ref
  file=$(resolve_ref "$1")
  ref=$(canonical_ref "$file")
  set_header "$file" Status done
  printf 'Resolved by %s\n' "$2" | append_comment "$file"
  commit_file "$file" "chore(tracker): resolve $ref"
  echo ok
}
```

- [ ] **Step 4: Run the tracker tests to verify they pass**

Run: `./tests/tracker/run-tests.sh`
Expected: both files end in `STATUS: PASSED`, exit 0.

- [ ] **Step 5: Run the pre-existing infrastructure tests to confirm nothing else moved**

Run each by path:

```
./tests/hooks/test-session-start.sh
./tests/kimi/run-tests.sh
./tests/codex/test-marketplace-manifest.sh
```

Expected: `STATUS: PASSED`, `Kimi plugin manifest looks good`, `Codex marketplace manifest looks good`. (`tests/shell-lint/test-lint-shell.sh` is not executable; it passed on the baseline and this plan does not touch `scripts/lint-shell.sh`.)

- [ ] **Step 6: Lint if the tools exist**

Run: `command -v shellcheck shfmt && scripts/lint-shell.sh skills/picking-up-ticket/scripts/tracker tests/tracker/helpers.sh tests/tracker/test-tracker-errors.sh tests/tracker/test-tracker-local.sh tests/tracker/run-tests.sh`
Expected: either `command -v` prints nothing and exits non-zero (tools absent: skip, say so in the task report), or the lint prints no findings. Fix any warning-level finding before committing.

- [ ] **Step 7: Commit**

```bash
git add skills/picking-up-ticket/scripts/tracker tests/tracker/test-tracker-local.sh tests/tracker/test-tracker-errors.sh
git commit -m "$(cat <<'EOF'
feat(tracker): resolve marks done, records what resolved it, commits

Sets Status: done, appends "Resolved by <what>" under Comments (the
local counterpart of GitHub's close comment) and commits the one file.
With this the seven ops of the port are covered by tests/tracker/.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```
