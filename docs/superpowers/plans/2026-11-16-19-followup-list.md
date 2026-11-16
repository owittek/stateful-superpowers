# Follow-up List Helper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `followup` script that notes, lists, closes and counts follow-ups in one git-ignored per-repo file reachable from any worktree, with shell tests for every op.

**Ticket:** #19 — `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` @ `044ac20`, Architecture row "Follow-up list". Acceptance criteria are the ticket's seven checkboxes; nothing else is in scope.

**Architecture:** One bash script, `skills/finishing-a-development-branch/scripts/followup`: argument parsing (`-C DIR`, op dispatch), a resolver for `<main checkout>/.superpowers/followups.md` via `git rev-parse --git-common-dir`, and one function per op. The file is plain markdown, one line per item, never pruned. Tests in `tests/followup/` in the style of `tests/tracker/`, driven from `tests/followup/run-tests.sh`.

**Tech Stack:** bash 3.2, git, POSIX awk/sed/grep.

**Spec:** `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md`

## Global Constraints

- Work only in worktree `.claude/worktrees/ticket-19-followup-list`, branch `ticket/19-followup-list`. Do not touch `skills/picking-up-ticket/`, the tracker script, or other worktrees.
- Interface verbatim: `followup [-C DIR] add TEXT [--source S]` → prints `N`; `list [--open] [--all]` (default current branch, open and closed); `done N --as now|dropped|ticket REF`; `count` → open items across branches.
- File: `<main checkout>/.superpowers/followups.md`. Open line `- [ ] N. [branch] text (source)`; closed `- [x] N. [branch] text (source) → now|dropped|REF`. Without `--source` the ` (source)` part is omitted.
- Numbers never reused: next N = max N in file + 1 (closed lines stay in the file).
- Self-ignoring rule: create-only `.superpowers/.gitignore` containing `*` (as `sdd-workspace` does for `.superpowers/sdd/`).
- Clean repo behaves as 0.9.0: read ops (`list`, `count`) never create files.
- Conventions as `sdd-workspace`: `#!/usr/bin/env bash`, `set -euo pipefail`, header comment, usage errors exit 2, failures exit 1 with one stderr line, results on stdout, executable bit. bash 3.2 / BSD-safe (no `sed -i`, no `mapfile`, no `readlink -f`).
- Lint: `bash scripts/lint-shell.sh <files>` clean.
- Conventional commits `feat(followup): ...`, no attribution trailers.

## Decisions beyond the spec text

1. Branch = `git symbolic-ref --short -q HEAD`; detached HEAD refuses `add` and branch-scoped `list`; `list --all`, `count`, `done` work detached.
2. `done` addresses any branch's item by its global number; closing an already-closed item fails (`follow-up N is already closed`).
3. Main checkout: common dir named `.git` → its parent; otherwise (bare repo, submodule-style gitdir) fail with `cannot locate the main checkout`.
4. TEXT/SOURCE/REF must be non-empty and single-line.
5. Writes go to a temp file in `.superpowers/` then `mv` (no torn file on interrupt). No locking: concurrent writers are out of scope.

## Review Focus

- `-C` pointing at a subdirectory of a worktree → same file as from worktree root (test in Task 1).
- Branch name that is a prefix of another (`feat` vs `feat-x`) → `list` must not leak (test in Task 2).
- TEXT containing `]`, `(`, `→` or digits-dot → stored verbatim, numbering unaffected (test in Task 2).
- `done` on an item from another branch → closes it (test in Task 3).
- Existing `.superpowers/.gitignore` a repo committed → left untouched (test in Task 1).

---

### Task 1: Script skeleton, resolution, `add`

**Files:**
- Create: `skills/finishing-a-development-branch/scripts/followup`
- Create: `tests/followup/helpers.sh`, `tests/followup/test-followup-add.sh`, `tests/followup/run-tests.sh`

**Interfaces:**
- Produces: `followup [-C DIR] add TEXT [--source S]` prints `N`; helpers `make_repo NAME`, `fu DIR ARGS...` (runs script with `-C DIR` under fake HOME), `assert_eq`, `assert_line`, `assert_fails`, `finish` (copied from `tests/tracker/helpers.sh`).

- [ ] **Step 1: Write failing tests** in `test-followup-add.sh`:
  - fresh repo on `main`: `fu repo add "first"` prints `1`; file line `- [ ] 1. [main] first`; second add `--source review` prints `2`, line `- [ ] 2. [main] second (review)`.
  - `git status --porcelain` empty after adds (repo has no ignore rule).
  - linked worktree on `feat/x` (`git worktree add -b feat/x`): add prints `3`, line `- [ ] 3. [feat/x] from wt` lands in `<repo>/.superpowers/followups.md`; no `.superpowers` in the worktree.
  - `-C <worktree>/sub` same file.
  - pre-existing committed `.superpowers/.gitignore` with `followups.md\n.gitignore\n` left byte-identical.
- [ ] **Step 2: Run** `bash tests/followup/run-tests.sh` → FAIL (script missing).
- [ ] **Step 3: Implement** skeleton, `-C`, resolver, `add`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(followup): add op with main-checkout resolution`.

### Task 2: `list` and `count`

**Files:** modify script; create `tests/followup/test-followup-list.sh`; add to `run-tests.sh`.

- [ ] **Step 1: Failing tests:** items on `main`, `feat`, `feat-x`; from `feat`: `list` shows only `[feat]` lines; `list --all` shows all; `list --open` hides closed (seed a closed line by hand until Task 3 — or order test after done; use hand-written `- [x]` line); `count` = open total across branches; no file → `list` empty, `count` prints `0`, no `.superpowers` created; text `a ] (b) 3. → c` round-trips and next add gets the next number.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** with awk prefix match on `- [?] N. [branch] `. **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(followup): list and count ops`.

### Task 3: `done`

**Files:** modify script; create `tests/followup/test-followup-done.sh`.

- [ ] **Step 1: Failing tests:** `done 1 --as now` → line `- [x] 1. [main] first → now`; `--as dropped` → `→ dropped`; `--as ticket #42` → `→ #42`; after closing the highest, next add prints max+1 (not reused); `done` on another branch's item from `main` works; `count` drops accordingly.
- [ ] **Step 2–4:** FAIL → implement (rewrite matching line via awk to temp, `mv`) → PASS.
- [ ] **Step 5: Commit** `feat(followup): done op with dispositions`.

### Task 4: Errors

**Files:** create `tests/followup/test-followup-errors.sh`.

- [ ] **Step 1: Tests:** no op / unknown op / unknown flag (`list --bogus`, `add x --bogus`) exit 2; `-C /nonexistent` exit 2; non-git dir → exit 1 one line `not inside a git work tree`; detached HEAD `add` → one line `detached HEAD`; `done abc`, `done 0` → `bad follow-up number`; `done 99` → `no follow-up 99`; closing twice → `already closed`; `done 1 --as ticket` without REF → exit 2; `--as later` → exit 2; empty TEXT / multi-line TEXT → exit 1.
- [ ] **Step 2–4:** run, fix any gap, PASS.
- [ ] **Step 5:** lint `bash scripts/lint-shell.sh skills/finishing-a-development-branch/scripts/followup tests/followup/*.sh`; run `tests/sdd-helper-paths`, `tests/skill-layout`. Commit `test(followup): error cases`.
