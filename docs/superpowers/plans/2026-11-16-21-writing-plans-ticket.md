# writing-plans Takes a Ticket; What's Next Routing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** writing-plans accepts a ticket ref and does fetch, refuse, claim, worktree, ticket-scoped plan, resume; using-superpowers routes ticket work and "what's next" to it.

**Ticket:** #21 — acceptance criteria are its six checkboxes; nothing else is in scope.

**Architecture:** Skill-text only. One new section (`## Ticket Intake`) and one optional header line in `skills/writing-plans/SKILL.md`; two routing lines in `skills/using-superpowers/SKILL.md`; both are named insertion points recorded in `docs/upstream-sync.md`. The tracker script (#20) is called by absolute path; no script change.

**Tech Stack:** Markdown skills; bash tests under `tests/`.

**Spec:** `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` @ 044ac20, Architecture rows "writing-plans: ticket intake", "What's next", "finishing: resolve" (branch config), Constraints; ADR 0004. Older `docs/superpowers/specs/2026-10-04-tracker-bridge-design.md`: writing-plans seam, picking-up-ticket Step 0 table and rationalization rows, Testing pressure tests 1–3.

## Global Constraints

- Worktree `.claude/worktrees/ticket-21-writing-plans-ticket`, branch `ticket/21-writing-plans-ticket`. No change to `skills/finishing-a-development-branch/scripts/tracker`.
- No tracker config (`docs/agents/issue-tracker.md` absent) → writing-plans behaves exactly as 0.9.0: the intake section is skipped in full.
- Upstream-tracked files (`writing-plans`, `using-superpowers`): insertions only, each named in `docs/upstream-sync.md`. using-superpowers edit stays on its own lines (a sibling branch adds a "note that for later" line).
- Branch config key verbatim: `git config branch.<branch>.ticket <ref>`. Header line verbatim: `**Ticket:** <ref>`. Branch name `ticket/<slug>`.
- Tracker referenced as `../finishing-a-development-branch/scripts/tracker`, run by its absolute path (tests/sdd-helper-paths style).
- Script backends: Local Markdown only; GitHub and others → the op by hand per `docs/agents/issue-tracker.md`.
- Every SKILL.md under 20,000 bytes. Commits conventional, no attribution trailer.

## Review Focus

- Claim on the local adapter commits on the current branch (often `main`): that commit is the one write before the worktree; nothing else may be written there. Wording in Task 1 says so.
- Ticket ref given while already in a linked worktree on another branch: intake must not record the ticket on an unrelated branch. Task 1 rule: reuse only if the branch has no other ticket recorded.
- Human declines the worktree: never write on the default branch; create `ticket/<slug>` in place. Pressure test 3 pins it.
- Resume when the plan lives in a worktree the session is not in: find it through `git config --get-regexp '^branch\..*\.ticket$'` and `git worktree list`. Pressure test 2 pins it.
- Blockers listed by `fetch` may already be done: refuse only on blockers not done (fetch each). Task 1 wording.

---

### Task 1: writing-plans ticket intake (RED → GREEN)

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (new `## Ticket Intake` after the "Save plans to" block; `**Ticket:**` line after `**Goal:**` in the header template)
- Create: `docs/superpowers/specs/2026-11-16-writing-plans-ticket-eval-notes.md`
- Modify: `tests/sdd-helper-paths/test-sdd-helper-paths.sh` (add `tracker` to the helper alternation so the new references must say "by its absolute path")

- [ ] **Step 1: Build the scratch fixture** in the scratchpad: git repo with a tiny bash project and test, `tracker init local`, a spec file, `register-parent`, and tickets: one free, one blocked by an open ticket, one claimed by "someone-else". Committed on `main`.
- [ ] **Step 2: RED.** Fresh subagents, skills read from `/Users/oli/.claude/plugins/cache/stateful-superpowers-dev/stateful-superpowers/0.9.0/skills`, using-superpowers pasted as bootstrap. Scenarios: (1) "work on <free ref>, it's small, just TDD it" — pass = plan file before any code, claim before any file; (2) compacted re-entry with claimed ticket, worktree, plan with `**Ticket:**` header present — pass = no claim, no new plan, plan reused; (3) on `main`, human declines a worktree — pass = nothing but the claim written on `main`. Plus refusal probes (blocked, foreign-claimed). Record observed behaviour.
- [ ] **Step 3: Write the intake section** addressing the RED failures: trigger (ticket ref/URL/"work on #N" and config present), resume check first, fetch, refuse (blockers not done, other assignee — name them), claim before any file, worktree on `ticket/<slug>` + branch config, plan filename `YYYY-MM-DD-<N>-<slug>.md`, `**Ticket:**` header, scope = acceptance criteria, input = spec pointer (kind `ticket`) or body (kind `followup`), red-flag rows from the old spec.
- [ ] **Step 4: GREEN.** Same scenarios with this worktree's skills. Pass criteria as Step 2. Iterate the text on any failure.
- [ ] **Step 5: Run** `tests/skill-size/test-skill-size.sh`, `tests/sdd-helper-paths/test-sdd-helper-paths.sh` → PASS.
- [ ] **Step 6: Commit** `feat(writing-plans): ticket intake`, `test(sdd-helper-paths): cover tracker references`, `docs(specs): writing-plans ticket eval notes`.

### Task 2: using-superpowers routing + upstream-sync

**Files:**
- Modify: `skills/using-superpowers/SKILL.md` (two bullets at the top of "Routing by intent")
- Modify: `docs/upstream-sync.md` (writing-plans and using-superpowers insertion-point bullets after the brainstorming bullet)

- [ ] **Step 1:** Routing lines: ticket work → `superpowers:writing-plans`; "what's next" / "what's open" → `tracker frontier ticket` and `tracker frontier followup`, titles shown, human picks, then writing-plans. No config → say no tracker is configured.
- [ ] **Step 2: Trigger probe** (fresh subagent, GREEN skills, fixture): "what's next?" → both frontier lists by title, asks to pick, writes nothing. Record in eval notes.
- [ ] **Step 3:** Record insertion points in `docs/upstream-sync.md`.
- [ ] **Step 4: Verify** `tests/skill-layout/test-no-dev-files-in-skills.sh`, `tests/skill-size/test-skill-size.sh`, `tests/sdd-helper-paths/test-sdd-helper-paths.sh`, `tests/tracker/run-tests.sh`, `bash scripts/lint-shell.sh tests/sdd-helper-paths/test-sdd-helper-paths.sh` → all PASS.
- [ ] **Step 5: Commit** `feat(using-superpowers): route ticket work and what's next`, `docs(upstream-sync): writing-plans and using-superpowers insertion points`.
