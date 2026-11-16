# Pattern Mode at Pickup + Helper Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ticket Intake runs the sweep in pattern mode for sweep follow-up tickets; designing-modules step 2 allows one helper lookup per repeated pattern.

**Ticket:** #40 — acceptance criteria are its four checkboxes.

**Architecture:** Two prose insertions plus upstream-sync records and a static wiring test.

**Tech Stack:** Markdown, bash 3.2.

**Spec:** `docs/superpowers/specs/2026-11-16-pattern-sweep-design.md` @ 0e6b1b8, Architecture row "Helper check at design", "Sort semantics for sweep items" (pickup).

## Global Constraints

- Sweep tickets are recognised by a `## Canonical choice` section in the body.
- Pattern mode inputs: PATTERN = the ticket's What, CANONICAL = its Canonical choice section. `NO FINDINGS` → resolve, don't plan.
- designing-modules sentence must sit beside "Scoped, not a sweep" and say "one lookup per pattern, not a survey".

## Review Focus

- A sweep ticket whose sites were already migrated by other work → NO FINDINGS → resolved, not re-planned.
- A non-sweep follow-up ticket → unaffected (no Canonical choice section).

---

### Task 1: Wiring

**Files:** Modify `skills/writing-plans/SKILL.md` (Ticket Intake step 5), `skills/designing-modules/SKILL.md` (step 2), `docs/upstream-sync.md`; Create `tests/pattern-sweep/test-pickup-and-design-wiring.sh`.

- [ ] Step 1: Test asserts Ticket Intake section contains `## Canonical choice`, `pattern-sweep-prompt.md`, `pattern mode`; designing-modules step 2 contains `Scoped, not a sweep` and `existing helper`; upstream-sync writing-plans entry has `(3)` … `pattern mode`, and a designing-modules divergence mentioning `helper lookup`. Run → FAIL.
- [ ] Step 2: Write the insertions. Run test, helper paths, skill size → PASS.
- [ ] Step 3: Commit `feat: pattern mode at ticket pickup; helper lookup in designing-modules`.
