---
name: commenting-modules
description: Use when adding comments to modules after a refactor, or when asked to document or comment a module, class, layer, or function. Symptoms it prevents: interface/method comments that describe how the code works instead of the caller's contract, and precision (bound inclusivity, sentinel meaning, ordering/preconditions, invariants) asserted confidently but not verified against the code.
---

# Commenting Modules

Add Ousterhout-style comments (APOSD ch. 13) and review them. **Rigid skill — follow the stages and the Red Flags exactly.**

**Core principle:** comments describe what is **not obvious from the code next to them**, judged from a first-time reader.

**Why this is its own step.** Capable agents already recover facts well (units, what a sentinel means, even reading call sites). Baseline testing showed they reliably fail at two things even with full information — this skill exists to stop exactly those:

1. **Implementation leaks into interface comments** — the caller-facing comment describes the strategy (data structures, loops, lazy/eager choices) instead of the contract.
2. **Precision asserted but not verified** — a bound called "inclusive" that's exclusive, a `-1` sentinel called an "error", a missing ordering precondition. A confident wrong comment is worse than none.

Reuses the architecture glossary: `../improving-architecture/LANGUAGE.md`. Comment categories, precision-vs-intuition, worked examples, and the two failure modes in depth: `COMMENT-TYPES.md`. Review criteria: `REVIEW.md`.

## Stages

### Stage 0 — Resolve & confirm the target set (entry-aware)
- **From a refactor (architecture / both):** seed from `git diff --name-only <base>..HEAD` — comment exactly what changed. Optionally suggest adjacent modules.
- **Commenting only:** the user gives a *direction* ("this layer", named modules). Use the Agent tool with `subagent_type=Explore` to resolve it to a concrete candidate set.
- Present the set; get confirmation before writing anything.

### Stage 1 — Cross-module exploration (before any writing)
Use the Agent tool with `subagent_type=Explore` to trace usage/dependencies across the confirmed set. For each decision spanning module seams, find the **natural focal point** (the declaration/seam every dependent path routes through). The cross-module comment goes there; thin pointers elsewhere. Most runs find none. No central notes file.

### Stage 2 — Per-module comment-writing subagents
One subagent per module. **Dispatch each against an isolated copy of the target** (a shared working dir lets agents read each other's edits and cross-contaminate). Each writes the categories in `COMMENT-TYPES.md` that apply, following the language's doc-tool conventions (Javadoc/godoc/JSDoc/rustdoc/Doxygen), and:

- **Writes the contract, not the implementation.** Interface/method comments state what a caller gets and must do — never how it's computed inside.
- **Verifies every precision claim against the code and call sites** before asserting it: inclusive vs exclusive (read the operator), what a `null`/sentinel return means (read how callers branch), ordering/preconditions, invariants. If the code doesn't let you verify it, say so — don't guess.
- **Shallowness flag:** if a clean interface comment can't be written without leaking implementation, record "module X resists a clean interface comment → candidate for deepening" and write the best honest comment. Do NOT refactor.

### Stage 3 — Comment review
A FRESH subagent runs `REVIEW.md` over the result, leading with the two highest-yield checks. Verdict per comment: keep / fix / delete; fixes applied and re-checked.

## After the stages
- Report all shallowness flags: in a **both** run they are re-entry candidates for `superpowers:improving-architecture`; commenting-only surfaces them to the user.
- **Commenting-only** path is gated, not free: it runs inside a worktree (`superpowers:using-git-worktrees`), stage-3 review is mandatory, then the human reviews the diff against the same `REVIEW.md` criteria, then `superpowers:finishing-a-development-branch`. No plan/TDD (no behavior change).

## Red Flags — STOP and fix

| Comment | Why it fails | Fix |
|---------|--------------|-----|
| Interface/method comment describes how it works (data structure, loop, lazy/eager strategy, internal calls) | Contaminates the abstraction — the dominant agent failure | State the caller-facing contract only; move detail inside, or raise the shallowness flag |
| Bound / sentinel / ordering / invariant asserted without checking the code | Confident-but-wrong precision is worse than none | Verify against the operator and call sites first; if unverifiable, say so |
| Repeats the code (`// increment i`) | Reader test fails | Delete |
| Reuses the entity's own name-words (`// the capacity` on `capacity`) | Restates the name | Replace with a fact not in the code |
| Verb-style field comment (how it's mutated) | Mirrors code structure | Rewrite as a noun: what it represents |

**Violating the letter of these is violating the spirit.** If a reader says a comment isn't obvious-free, it isn't — clarify, don't argue.
