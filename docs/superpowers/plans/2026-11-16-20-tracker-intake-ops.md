# Tracker Port: Intake Ops — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the tracker port under finishing-a-development-branch and give its Local Markdown adapter what intake needs: `-C DIR`, `init`, a standing Follow-ups parent, `find`, and the "run tracker init" message.

**Ticket:** #20 — acceptance criteria are its six checkboxes; nothing else is in scope.

**Architecture:** Same single script and three layers as #11 (helpers, `local_<op>` adapter, dispatcher). The dispatcher gains a `-C DIR` prefix parsed before the op, and `init` is handled before the config check (it is the op that creates the config). `publish-ticket -` resolves PARENT through a new helper that registers the Follow-ups parent on first use. `find` is a new `local_find`.

**Tech Stack:** bash 3.2-compatible shell, git, POSIX awk/sed/grep.

**Spec:** `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` @ 044ac20, Architecture row "Tracker port", "Follow-up ticket body", Constraints; ADRs 0002, 0004, 0005.

## Global Constraints

- Worktree `.claude/worktrees/ticket-20-tracker-intake-ops`, branch `ticket/20-tracker-intake-ops`. Do not create `followup` or `tests/followup/` (ticket #19, sibling worktree).
- GitHub adapter stays "not implemented" (#13). No skill prose edits (#14–#16).
- Portability and bash pitfalls as in the #11 plan (`docs/superpowers/plans/2026-10-04-11-tracker-port-local.md`, Global Constraints): bash 3.2, BSD+GNU userland, no `local x=$(...)`.
- SDD helper style: `-C DIR` like `git -C` (cd before anything else; relative file args then resolve against DIR), bad DIR → exit 2 `bad -C directory: DIR`; one-line reason on stderr; exit 2 for usage.
- Missing config reason, verbatim: `no tracker configured: run tracker init`.
- Config H1 verbatim: `# Issue tracker: Local Markdown`. Follow-ups parent: kind `followups`, title `Follow-ups`, slug `follow-ups`, file `docs/superpowers/tickets/follow-ups/00-followups.md`, ref `follow-ups/00`, no Spec line.
- Lint: `bash scripts/lint-shell.sh <files>` clean (shellcheck installed).
- Commits: conventional (`feat(tracker): ...`), no attribution trailer.

## Review Focus

- `-C` with a relative BODY_FILE: resolves against DIR (git -C semantics). Documented in header; tests use absolute paths.
- `publish-ticket -` with a kind other than `followup`: refused (`parent - is only for kind followup`), so the standing parent never collects spec tickets.
- A `follow-ups/` directory that holds some other parent (a spec titled "Follow ups"): `publish-ticket -` refuses rather than hanging follow-ups under it. Test in Task 4.
- `find` with regex metacharacters in TEXT (`a.b`, `[x]`): literal substring match (`grep -F`). Test in Task 5.
- `init local` on a config with no H1 or another backend: refused with one line, file unchanged. Test in Task 3.

---

### Task 1: Move the script; missing-config message

**Files:**
- Move: `skills/picking-up-ticket/scripts/tracker` → `skills/finishing-a-development-branch/scripts/tracker` (`git mv`, remove the empty `skills/picking-up-ticket/`)
- Modify: `tests/tracker/helpers.sh` (`TRACKER=` path), `tests/tracker/test-tracker-errors.sh` (missing-config needle)

- [ ] Step 1: In errors test, change missing-config needle to `no tracker configured: run tracker init`; run `bash tests/tracker/run-tests.sh` → FAIL (path missing / message).
- [ ] Step 2: `git mv`, fix `TRACKER` path, change the die to `no tracker configured: run tracker init`; the no-H1 reason drops its setting-up-tracker pointer: `docs/agents/issue-tracker.md has no H1 naming the issue tracker`.
- [ ] Step 3: run tests → PASS; `git grep -n picking-up-ticket -- skills tests` → nothing.
- [ ] Step 4: commit `refactor(tracker): move the port under finishing-a-development-branch`.

### Task 2: `-C DIR` for every op

**Files:** Modify script dispatch + usage; tests: `helpers.sh`, `test-tracker-errors.sh`, `test-tracker-local.sh`.

**Produces:** `tracker [-C DIR] <op> [args]`; helper `tracker_c REPO OP...` in `helpers.sh` runs the script from `$TEST_ROOT` with `-C REPO`.

- [ ] Step 1: Tests: usage line becomes `usage: tracker [-C DIR] <op> [args]`; `-C` with a missing dir exits 2; `-C` without a value exits 2; in `test-tracker-local.sh` a new `tracker: -C DIR` block before `finish` that, from outside the repo, runs every op against `$repo` via `tracker_c`: register-parent (new parent "Dash C"), publish-ticket under it, frontier ticket on it (shows the ticket), fetch, claim (commit lands in `$repo`), comment, resolve, find, init local (no-op `ok`). Run → FAIL.
- [ ] Step 2: Parse `-C DIR` first in dispatch (as `sdd-workspace`), then op.
- [ ] Step 3: run → PASS (find/init lines added in Tasks 3/5 — add them there, not here).
- [ ] Step 4: commit `feat(tracker): accept -C DIR for every op`.

### Task 3: `init local|github`

**Files:** script (new `init_config` path in dispatch, before the config check), `test-tracker-errors.sh`, `test-tracker-local.sh`.

Behaviour:
- `init local`, no config → write `docs/agents/issue-tracker.md` (mkdir -p), print `ok`, leave it uncommitted. Content: H1, one paragraph that tickets live under `docs/superpowers/tickets/`, a `## Ticket operations` section listing the ops one line each and pointing at `skills/finishing-a-development-branch/scripts/tracker`.
- Config already Local Markdown → print `ok`, file byte-identical.
- Config naming another backend (or no H1) → exit 1 `docs/agents/issue-tracker.md already names "<X>"; not overwriting` (no H1: `... has no H1 naming the issue tracker; not overwriting`).
- `init github` → exit 1 `init github is not implemented yet (#13)`. Any other arg / arity → usage (2).
- Works outside "configured" repos; still needs a git work tree.

- [ ] Step 1: Tests (in a fresh `make_repo`-less git repo for init): writes file with H1 line `# Issue tracker: Local Markdown` and line `## Ticket operations`; output `ok`; status shows `?? docs/`; second run `ok` and `cmp` identical; after init, `frontier ticket` works (empty output); on a GitHub-H1 repo refusal and file unchanged; on a no-H1 repo refusal; `init github` refusal mentioning `#13`; `init bogus` exits 2. Add `-C` init line to Task 2's block. Run → FAIL.
- [ ] Step 2: Implement.
- [ ] Step 3: run → PASS. Commit `feat(tracker): init local writes the Local Markdown config`.

### Task 4: Standing Follow-ups parent

**Files:** script (`local_publish_ticket`, new helper `followups_parent` → prints parent file path), `test-tracker-local.sh`, `test-tracker-errors.sh`.

Behaviour: `publish-ticket - followup TITLE BODY_FILE [BLOCKER...]`: if `follow-ups/00-followups.md` exists, reuse; else if `follow-ups/` exists with another parent → die `follow-ups/00 is not the Follow-ups parent`; else create it: title line `# 00: Follow-ups`, `Kind: followups`, `Status: open`, blank, one-sentence body (`Standing parent for deferred follow-up tickets; never closed, points at no spec.`), blank, `## Tickets`. Body file and blockers are validated before the parent is created (a refused publish writes nothing). `-` with kind ≠ `followup` → die `parent - is only for kind followup`.

- [ ] Step 1: Tests: first publish prints `follow-ups/01`; parent file exists with `Kind: followups`, `# 00: Follow-ups`, no line starting `Spec:`; child has `Parent: follow-ups/00`, `Kind: followup`; second publish prints `follow-ups/02` and there is still exactly one `00-*.md`; parent lists both; fetch on `follow-ups/00` prints `kind: followups`, `state: open`; `- ticket` refused; refused publish with missing body file in a fresh repo leaves no `follow-ups/` dir; repo with `follow-ups/00-spec.md` (registered via `register-parent spec "Follow ups" ...`) → refusal. Run → FAIL.
- [ ] Step 2: Implement. Step 3: PASS. Commit `feat(tracker): standing Follow-ups parent for publish-ticket -`.

### Task 5: `find KIND TEXT`

**Files:** script (`local_find`, usage, arity `-eq 2`, empty TEXT → usage), tests.

Behaviour: over every `$TICKETS/*/[0-9][0-9]-*.md`, Kind == KIND and Status ≠ `done`, title or body (`body_of`) contains TEXT, case-insensitive, literal (`grep -Fqi -e`). Print `ref<TAB>title` per match in glob order; no match → no output, exit 0. No tickets dir → no output.

- [ ] Step 1: Tests (on the Task 4 follow-ups): title match with different case; body-only match; kind filter (`find ticket` same text → nothing); regex-ish text `a.b` does not match `axb`; after `resolve` of one, it disappears; no match → empty and exit 0; `find` in the unknown-refs repo with no tickets dir → empty; add `find` to `assert_every_op_fails`; `find ticket ""` exits 2. Add the `-C` find line. Run → FAIL.
- [ ] Step 2: Implement. Step 3: PASS. Commit `feat(tracker): find open tickets by kind and text`.

### Task 6: Header comment and verification

- [ ] Step 1: Rewrite header op list (nine ops), `-C`, init behaviour, Follow-ups parent layout, find contract.
- [ ] Step 2: Run `bash tests/tracker/run-tests.sh`, `bash scripts/lint-shell.sh skills/finishing-a-development-branch/scripts/tracker tests/tracker/*.sh`, `bash tests/sdd-helper-paths/*.sh`, `bash tests/skill-layout/*.sh`, `git grep -n picking-up-ticket -- skills tests` → all clean.
- [ ] Step 3: commit `docs(tracker): header covers find, init, -C and the Follow-ups parent`.
