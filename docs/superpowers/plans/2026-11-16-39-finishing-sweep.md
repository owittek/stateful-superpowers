# Finishing Runs the Pattern Sweep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finishing Step 0 dispatches the pattern sweep before listing follow-ups; the sort knows how to handle sweep items.

**Ticket:** #39 — acceptance criteria are its five checkboxes.

**Architecture:** Prose insertion in finishing SKILL.md Step 0 (glue), sweep-item rules in `references/follow-up-sort.md`, upstream-sync item 9, a static wiring test.

**Tech Stack:** Markdown, bash 3.2.

**Spec:** `docs/superpowers/specs/2026-11-16-pattern-sweep-design.md` @ 0e6b1b8, Architecture row "Step 0 sweep insertion", "Sort semantics for sweep items".

## Global Constraints

- Source tag verbatim: `--source sweep`; follow-up text `<pattern> → <canonical choice>`.
- Skip the sweep on: detached HEAD, a discard request already made, diff of only docs/tests/config.
- BASE: merge-base with the known base branch, else with the default branch (`git symbolic-ref refs/remotes/origin/HEAD`, fallback `main`).
- PRIOR: `followup list` lines containing `(sweep)`.
- Ticket threshold: more than 10 outside-diff sites or more than one area.
- Ticket body sections added: `## Canonical choice`, `## Enforcement`; no paths.
- SKILL.md < 20000 bytes.

## Review Focus

- Re-running finishing after a declined sort → sweep gets PRIOR with the open items and doesn't duplicate them.
- Sweep returns NO FINDINGS → Step 0 continues exactly as before (silent if the list is empty).
- Compaction between sweep and sort → line text alone suffices for ticket/drop; "now" re-greps.
- Sweep subagent unavailable (no subagent tool) → run the prompt yourself inline, not skip silently.

---

### Task 1: Wiring + sort rules + sync record

**Files:** Modify `skills/finishing-a-development-branch/SKILL.md` (Step 0), `skills/finishing-a-development-branch/references/follow-up-sort.md`, `docs/upstream-sync.md`; Create `tests/pattern-sweep/test-finishing-sweep-wiring.sh`.

- [ ] Step 1: Wiring test asserts: SKILL.md references `references/pattern-sweep-prompt.md` on an earlier line than `followup list --open --orphaned`; SKILL.md contains `--source sweep`, `detached HEAD`, `discard`; follow-up-sort.md contains `## Canonical choice`, `## Enforcement`, `more than 10`, `(sweep)`; upstream-sync.md finishing entry contains `(9)` and `pattern sweep`. Run → FAIL.
- [ ] Step 2: Write the Step 0 sweep paragraph, the sort's "Sweep items" section, sync item 9. Run test, skill-size, helper-paths → PASS.
- [ ] Step 3: Commit `feat(finishing): run the pattern sweep before the follow-up sort`.
