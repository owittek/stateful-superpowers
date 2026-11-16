# Finishing: Follow-up Sort and Ticket Resolution — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** finishing-a-development-branch sorts the branch's open follow-ups (now / ticket / drop) before the test run and resolves the branch's ticket on integration.

**Ticket:** #16 — acceptance criteria are its six checkboxes; nothing else is in scope.

**Architecture:** Skill prose only, over the two existing scripts (`followup`, `tracker`). SKILL.md stays upstream's file plus named insertion points; the sort's dialogue lives in a new fork-only `references/follow-up-sort.md`, read at Step 0 only when the list is non-empty, so a clean branch reads nothing new. Resolution edits are one line each in Steps 2 and 5.

**Tech Stack:** Markdown skill text; bash scripts already on `next`.

**Spec:** `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` @ 044ac20, Architecture rows "Follow-up sort", "finishing: resolve", "Follow-up ticket body", Constraints, Anti-goals; ADRs 0002, 0004, 0005; `docs/superpowers/specs/2026-10-04-tracker-bridge-design.md` finishing seam and Testing item 4.

## Global Constraints

- Worktree `.claude/worktrees/ticket-16-finishing-sort`, branch `ticket/16-finishing-sort`. Do not edit `scripts/tracker`, `scripts/followup`, writing-plans or using-superpowers (#13, #21 in sibling worktrees).
- Clean repo (no tracker config, no follow-ups) behaves exactly as 0.9.0: empty list → no output, continue.
- Scripts are referenced as "this skill's `scripts/<name>` ... by its absolute path, from the working tree you're executing in" (executing-plans style, `tests/sdd-helper-paths`).
- Every SKILL.md edit is an insertion point listed in `docs/upstream-sync.md`.
- "ticket" is offered only for a backend the script implements: Local Markdown yes; GitHub only once `tracker` stops refusing it (probe: `tracker find followup <words>` — exit 0 = implemented; "not implemented" on stderr = not).
- Follow-up ticket body: sections What / Why it matters / Found during (`Branch <name> @ <sha>, <source>`) / Acceptance criteria; no file paths or code.
- Ticket ref: `git config branch.<current>.ticket`; absent → no ticket behaviour.
- SKILL.md under 20,000 bytes (`tests/skill-size`).
- Commits: conventional, no attribution trailer.

## Review Focus

- Branch has open follow-ups AND the human asks to discard: only keep/drop offered, ticket never. Covered in reference text; checked by reading.
- Follow-ups on other branches (`list --all`) never appear in the sort: `list --open` without `--all`.
- Merge is a fast-forward (no merge commit): resolve with the post-merge `HEAD` sha.
- PR to a non-default base: `Closes` doesn't fire; report that the ticket is resolved by hand after merge.
- Local ref on the PR path: no `Closes`; `tracker comment` with the PR URL; ticket stays claimed.

---

### Task 1: RED baselines on 0.9.0

**Files:** scratch only (`$SCRATCH/pt/`), no repo files.

- [ ] **Step 1:** Write `$SCRATCH/pt/mk-fixture.sh SCENARIO DIR` building a git repo with `main` + feature branch `feat/x` (one commit, a `test.sh` that passes), plus per scenario: (a) 2 open follow-ups on `feat/x`, 1 on another branch, Local Markdown config; (b) no follow-ups, no config; (c) 1 open follow-up whose text matches an existing local follow-up ticket `follow-ups/01`; (d) local config, ticket `demo/01` claimed, `branch.feat/x.ticket=demo/01` (local-merge run) and a variant with GitHub H1, `branch.feat/x.ticket=#7`, a bare `origin`, no `gh` (PR run, body written to `PR_BODY.md`).
- [ ] **Step 2:** Dispatch one fresh subagent per scenario (a, b, c, d-merge, d-PR) told to follow `<0.9.0 cache>/skills/finishing-a-development-branch/SKILL.md` in the fixture, with scripted human replies; record transcripts' key points.
- [ ] **Step 3:** Expected RED: (a) no sort; (c) no find/link; (d) no resolve, no `Closes #7`. (b) is the equivalence baseline.

### Task 2: Step 0 follow-up sort

**Files:**
- Create: `skills/finishing-a-development-branch/references/follow-up-sort.md`
- Modify: `skills/finishing-a-development-branch/SKILL.md` (Overview line, new Step 0, discard section line, rationalization rows)

- [ ] **Step 1:** Step 0 in SKILL.md: run `scripts/followup list --open` by absolute path; empty → say nothing, go to Step 1; else read `references/follow-up-sort.md` and do it before Step 1.
- [ ] **Step 2:** Reference: decide ticket availability (config H1 / probe); one message format (numbered items, recommendation, one-line why, "Reply 'ok' or change any"); dispositions with exact commands; no-config init offer once (local when no github.com remote; GitHub via `init github`, refused → say so, items stay open); body template; local adapter commit with the sort's fixes; discard variant (keep / drop only).
- [ ] **Step 3:** Discard section: "Before the confirmation, run Step 0 reduced to keep or drop."
- [ ] **Step 4:** `tests/skill-size`, `tests/sdd-helper-paths` pass. Commit `feat(finishing): sort follow-ups before the test run`.

### Task 3: Ticket resolution

**Files:** Modify `skills/finishing-a-development-branch/SKILL.md` Step 2, Option 1, Option 2, Option 3, rationalization table.

- [ ] **Step 1:** Step 2: `TICKET=$(git config "branch.$(git branch --show-current).ticket" || true)`; empty → skip every ticket line below.
- [ ] **Step 2:** Option 1, after merged result green, from base: `tracker resolve "$TICKET" "$(git rev-parse HEAD)"`. Option 2: GitHub ref (`#N`) → PR body includes `Closes $TICKET`; non-default base → also say it's resolved by hand after merge; local ref → `tracker comment` with PR URL, stays claimed. Option 3: "Ticket <ref> stays claimed."
- [ ] **Step 3:** Row "The PR will close it anyway" → only if the body says `Closes <ref>`, and only when the base is the default branch.
- [ ] **Step 4:** tests pass. Commit `feat(finishing): resolve the branch's ticket on integration`.

### Task 4: Upstream-sync record

- [ ] Add a `finishing-a-development-branch` bullet listing the insertion points to `docs/upstream-sync.md`. Commit `docs(upstream-sync): finishing insertion points`.

### Task 5: GREEN and eval notes

- [ ] **Step 1:** Rerun Task 1's five scenarios on this branch's skill with fresh subagents.
- [ ] **Step 2:** Write `docs/superpowers/specs/2026-11-16-finishing-sort-eval-notes.md`: what ran (fixture, model, prompts' scripted replies), RED vs GREEN per scenario, any loophole fixed. Commit.

### Task 6: Verify and PR

- [ ] Run `tests/skill-layout`, `tests/skill-size`, `tests/sdd-helper-paths`, `tests/followup/run-tests.sh`, `tests/tracker/run-tests.sh`; all PASS. No shell file changed → no lint needed (state it).
- [ ] Push; `gh pr create -R owittek/stateful-superpowers --base next`, body starting `Closes #16`. Do not merge.
