# Pattern Sweep Prompt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The pattern sweep prompt template, a synthetic fixture repo, and a structural test of the prompt's contract.

**Ticket:** #38 — acceptance criteria are its four checkboxes.

**Architecture:** One prompt file dispatched as a read-only subagent (branch mode / pattern mode). A bash fixture builder makes a throwaway repo with two planted findings; a static test pins the contract strings.

**Tech Stack:** Markdown, bash 3.2 (BSD + GNU userland), git.

**Spec:** `docs/superpowers/specs/2026-11-16-pattern-sweep-design.md` @ 0e6b1b8, Architecture row "Pattern sweep prompt", "Finding shape", Constraints.

## Global Constraints

- Prompt path: `skills/finishing-a-development-branch/references/pattern-sweep-prompt.md`.
- Placeholders verbatim: `[BASE_SHA]`, `[HEAD_SHA]`, `[PRIOR]`, `[PATTERN]`, `[CANONICAL]`.
- Finding shape field labels verbatim: `Kind:`, `Canonical:`, `In diff:`, `Outside diff:`, `Enforce:`, `Recommend:`. Kinds: `helper-exists | drift | not-backported | siblings-disagree`.
- Empty result: exactly `NO FINDINGS`. Branch mode cap: 5.
- Ticket threshold in Recommend: >~10 outside-diff sites or more than one area → ticket.
- No client names; fixture is synthetic. Commits conventional, no attribution.

## Review Focus

- PRIOR item reworded by the sweep (same pattern, different words) → must still be skipped: prompt says match by pattern, not wording.
- Diff with only docs/tests → prompt returns NO FINDINGS rather than sweeping unrelated code.
- A finding whose "canonical" has no precedent (first-ever instance) → Canonical cites a named best practice, never invents precedent.
- Pattern mode on a repo already fully migrated → NO FINDINGS.
- Sweep must not edit files: prompt says read-only explicitly.

---

### Task 1: Prompt, fixture, static test

**Files:**
- Create: `skills/finishing-a-development-branch/references/pattern-sweep-prompt.md`
- Create: `tests/pattern-sweep/make-fixture.sh` (usage `make-fixture.sh DIR` → builds repo in DIR, prints `BASE=<sha>` and `HEAD=<sha>`)
- Create: `tests/pattern-sweep/test-pattern-sweep-prompt.sh`

- [ ] Step 1: Static test asserts the prompt contains every Global Constraints string, `Branch mode`, `Pattern mode`, `read-only`, `does a helper`; and that `make-fixture.sh` in a temp dir prints BASE/HEAD and `git diff --name-only BASE HEAD` lists exactly `src/routes/orders.ts` and `src/tables/customer-columns.tsx`. Run → FAIL.
- [ ] Step 2: Fixture: base commit has `src/lib/service-problem.ts` (`serviceProblem(result)`) used by `src/routes/{users,invoices,products}.ts`, and `src/components/truncated-cell.tsx` used by `src/tables/{user,invoice}-columns.tsx`; head commit adds `orders.ts` hand-rolling `if (result.code === ...) return problem(...)` with `detail: result.error`, and `customer-columns.tsx` using `className="truncate"` without a tooltip.
- [ ] Step 3: Write the prompt. Run test → PASS; shellcheck -S warning clean.
- [ ] Step 4: Eval: dispatch the prompt (branch mode, PRIOR empty) on the fixture → both planted findings, helper-exists first. Re-dispatch with PRIOR = the truncation finding as a closed follow-up line → only the error-mapping finding.
- [ ] Step 5: Commit `feat(finishing): pattern sweep prompt and fixture`.
