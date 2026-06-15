# Commenting Modules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `commenting-modules` skill and wire it into the architecture lifecycle so modules get Ousterhout-style comments as their own reviewed step.

**Architecture:** A new rigid skill (`SKILL.md` + `COMMENT-TYPES.md` + `REVIEW.md`) runs four stages: resolve target set → cross-module exploration → per-module comment-writing subagents → fresh-subagent comment review. `improving-architecture` gains a 3-way routing question (architecture / commenting / both); `writing-plans` appends a terminal commenting phase when scope=both; `using-superpowers` gains a routing pointer.

**Tech Stack:** Markdown skill files. "Tests" are subagent pressure/application scenarios per `superpowers:writing-skills` (RED-GREEN-REFACTOR). No runtime code.

**REQUIRED BACKGROUND:** Read `superpowers:writing-skills` and `superpowers:test-driven-development` before starting. The Iron Law applies: **no skill (or skill edit) without a failing test first.** Every authoring task below baselines behavior WITHOUT the change before writing it.

**Spec:** `docs/superpowers/specs/2026-06-15-commenting-modules-design.md`

---

## Source material (fixed — from APOSD ch. 13, already resolved in the spec)

These are not speculative; they are the canonical criteria the skill encodes. Reuse verbatim where the tasks reference them.

**Four comment categories:** interface, field/variable, implementation, cross-module.
**Two augmentation directions:** lower-level = *precision* (units, inclusive/exclusive bounds, null meaning, resource ownership/lifetime, invariants); higher-level = *intuition* (what & why, "how we get here").
**Two Red Flags:** *Comment Repeats Code* (incl. reusing the entity's own name-words); *Implementation Documentation Contaminates Interface*.
**Reader test:** could someone write this comment just by reading the code next to it? Yes → delete.
**Nouns not verbs** for declarations. **Shallowness signal:** an interface comment that can't avoid implementation detail means the module is shallow.

---

## Test fixture (shared by baseline + verification tasks)

Create one throwaway fixture used to baseline and then verify agent behavior. It is deleted at the end (Task 11).

**File:** `/tmp/commenting-fixture/rate-limiter.ts` — a deliberately uncommented module with non-obvious facts (units, an inclusive bound, a null meaning, an invariant, and a cross-module dependency) so good vs. bad comments are distinguishable.

```typescript
export class RateLimiter {
  private tokens: number;
  private last: number;
  private readonly capacity: number;
  private readonly refillPerSec: number;

  constructor(capacity: number, refillPerSec: number) {
    this.capacity = capacity;
    this.refillPerSec = refillPerSec;
    this.tokens = capacity;
    this.last = epochSeconds();
  }

  // returns null when allowed; a number (seconds to wait) when throttled
  tryAcquire(cost: number): number | null {
    const now = epochSeconds();
    this.tokens = Math.min(this.capacity, this.tokens + (now - this.last) * this.refillPerSec);
    this.last = now;
    if (cost <= this.tokens) {
      this.tokens -= cost;
      return null;
    }
    return (cost - this.tokens) / this.refillPerSec;
  }
}
```

`epochSeconds()` is assumed to live in a shared `clock.ts`; treat the clock source as the cross-module dependency.

---

## Task 1: RED — baseline `commenting-modules` failures

**Files:**
- Create: `/tmp/commenting-fixture/rate-limiter.ts` (fixture above)
- Create: `docs/superpowers/plans/notes/2026-06-15-commenting-baseline.md` (observations)

- [ ] **Step 1: Write the fixture**

Create `/tmp/commenting-fixture/rate-limiter.ts` with the fixture code above.

- [ ] **Step 2: Run the baseline scenario (no skill)**

Dispatch THREE fresh general-purpose subagents, each with exactly this prompt and NO mention of the commenting skill:

> Add comments to this module so a new developer can use and maintain it. Return the fully commented file.
> [paste rate-limiter.ts]

- [ ] **Step 3: Record verbatim failures**

In `notes/2026-06-15-commenting-baseline.md`, record, per agent, every comment that exhibits:
- repeats the code / reuses a name-word (e.g. `// the capacity`),
- vague declaration comment missing units/bound/null-meaning/invariant,
- implementation detail in what should be an interface comment,
- missing the cross-module (clock) dependency note.

Expected baseline (the failure we're proving): agents restate names, omit that `refillPerSec` is tokens-per-second, omit that `tryAcquire`'s `null` means "allowed", and omit the invariant `tokens ∈ [0, capacity]`.

- [ ] **Step 4: Commit the baseline notes**

```bash
git add docs/superpowers/plans/notes/2026-06-15-commenting-baseline.md
git commit -m "test(commenting-modules): baseline agent commenting failures (RED)"
```

---

## Task 2: GREEN — write `COMMENT-TYPES.md`

Reference content first; `SKILL.md` links to it.

**Files:**
- Create: `skills/commenting-modules/COMMENT-TYPES.md`

- [ ] **Step 1: Write the file**

```markdown
# Comment Types

Reuses the architecture glossary (`../improving-architecture/LANGUAGE.md`): **Interface** = everything a caller must know; **Implementation** = what's inside. Ousterhout's interface-vs-implementation comment split maps directly onto those.

**Guiding principle:** comments describe what is *not obvious from the code next to them*. "Obvious" is judged from a first-time reader, not the author.

## The four categories

### 1. Interface comment (most important)
Precedes a module/class or method. Defines the abstraction a caller perceives — NOT how it works inside.
- Class: the overall abstraction, what an instance represents, key limitations.
- Method: behavior as callers see it, each argument + return value, side effects, exceptions, preconditions.
- The caller must be able to use it **without reading the body**.

### 2. Field / variable comment (most important)
Next to instance/static vars and non-obvious locals. Carries *precision*:
- units, inclusive/exclusive bounds, what `null`/empty means, who owns/frees a resource, invariants.
- **Think nouns, not verbs** — what the variable *represents*, not how it is manipulated.

### 3. Implementation comment (often unnecessary)
Inside a method. *What & why, not how.* Block headers ("Phase 1: …"), loop-intent headers, "how we get here". Only where non-obvious.

### 4. Cross-module comment (rare)
A decision spanning module seams. Place it at the **natural focal point** every dependent path routes through; thin pointer comments elsewhere. No central notes file (it goes stale).

## Two directions

- **Lower-level → precision.** Clarifies exact meaning. Best for declarations.
- **Higher-level → intuition.** Omits detail, gives intent. Best for interface comments and block headers.
- A comment at the *same* level as the code just repeats it.

## Worked examples

**Repeats the code (delete):**
`// the capacity` above `private readonly capacity: number;`

**Precision (keep):**
`// Max tokens the bucket holds; tryAcquire never lets tokens exceed this. Invariant: tokens ∈ [0, capacity].`

**Vague → precise (field):**
`// current offset` → `// Position in this buffer of the first byte not yet returned to the caller.`

**Implementation leaks into interface (fix):**
`// Uses a DCFT rule engine to …` on a public method → move inside; the interface comment states only the observable contract.

**Intuition (block header):**
`// Refill the bucket for elapsed time, then spend `cost` if affordable.`
```

- [ ] **Step 2: Commit**

```bash
git add skills/commenting-modules/COMMENT-TYPES.md
git commit -m "feat(commenting-modules): add COMMENT-TYPES reference"
```

---

## Task 3: GREEN — write `REVIEW.md`

**Files:**
- Create: `skills/commenting-modules/REVIEW.md`

- [ ] **Step 1: Write the file**

```markdown
# Comment Review

Run by a FRESH subagent with no memory of writing the comments (same reason code review uses fresh eyes). Verdict per comment: **keep / fix / delete**; apply fixes and re-check. Criteria are Ousterhout's (APOSD ch. 13).

## Per comment
- **Not obvious from adjacent code** — reader test: could someone write this comment just by reading the code next to it? Yes → delete. Judge "obvious" from a first-time reader, not the author.
- **Doesn't repeat the code, doesn't reuse the entity's name-words** (Red Flag: Comment Repeats Code).
- **Right level** — adds *precision* (lower) or *intuition* (higher). A same-level mirror of the code is the failure.

## Per declaration (field / arg / return)
- Carries precision where it applies: **units, inclusive/exclusive bounds, null meaning, resource ownership/lifetime, invariants**. Vague is the dominant failure.
- **Nouns not verbs** — what it represents, not how it is manipulated.

## Per interface comment
- Usable without reading the body: behavior as callers see it, each **arg + return, side effects, exceptions, preconditions**.
- **No implementation detail** (Red Flag: Implementation Contaminates Interface). If it can't be written without leaking implementation → raise the **shallowness flag** (do not refactor here; record "module X resists a clean interface comment → candidate for deepening").

## Per module (coverage)
- Every class, method, and class variable has an interface comment — except the genuinely obvious (a plain getter/setter).
```

- [ ] **Step 2: Commit**

```bash
git add skills/commenting-modules/REVIEW.md
git commit -m "feat(commenting-modules): add REVIEW criteria"
```

---

## Task 4: GREEN — write `SKILL.md`

**Files:**
- Create: `skills/commenting-modules/SKILL.md`

- [ ] **Step 1: Write the file**

````markdown
---
name: commenting-modules
description: Use when adding comments to modules after a refactor, or when asked to document/comment a module, class, layer, or function. Symptoms it prevents: comments that repeat the code or reuse the entity's name, vague field docs (missing units/bounds/null-meaning/invariants), implementation detail leaking into interface docs.
---

# Commenting Modules

Add Ousterhout-style comments (APOSD ch. 13) and review them. **Rigid skill — follow the stages and the Red Flags exactly.** Agents are reliably bad at this when left to judgment; that is why it is its own step.

**Core principle:** comments describe what is **not obvious from the code next to them**, judged from a first-time reader.

Reuses the architecture glossary: `../improving-architecture/LANGUAGE.md`. Comment categories, precision-vs-intuition, and worked examples: `COMMENT-TYPES.md`. Review criteria: `REVIEW.md`.

## Stages

### Stage 0 — Resolve & confirm the target set (entry-aware)
- **From a refactor (architecture / both):** seed from `git diff --name-only <base>..HEAD` — comment exactly what changed. Optionally suggest adjacent modules.
- **Commenting only:** the user gives a *direction* ("this layer", named modules). Use the Agent tool with `subagent_type=Explore` to resolve it to a concrete candidate set.
- Present the set; get confirmation before writing anything.

### Stage 1 — Cross-module exploration (before any writing)
Use the Agent tool with `subagent_type=Explore` to trace usage/dependencies across the confirmed set. For each decision spanning module seams, find the **natural focal point** (the declaration/seam every dependent path routes through). The cross-module comment goes there; thin pointers elsewhere. Most runs find none. No central notes file.

### Stage 2 — Per-module comment-writing subagents
One subagent per module (or small batch). Each writes the categories in `COMMENT-TYPES.md` that apply, following the language's doc-tool conventions (Javadoc/godoc/JSDoc/rustdoc/Doxygen) and placing only the stage-1 pointer comments for cross-module.

**Shallowness flag:** if a clean interface comment can't be written without leaking implementation, the subagent records "module X resists a clean interface comment → candidate for deepening" and writes the best honest comment. It does NOT refactor.

### Stage 3 — Comment review
A FRESH subagent runs `REVIEW.md` over the result. Verdict per comment: keep / fix / delete; fixes applied and re-checked.

## After the stages
- Report all shallowness flags: in a **both** run they are re-entry candidates for `superpowers:improving-architecture`; commenting-only surfaces them to the user.
- **Commenting-only** path is gated, not free: it runs inside a worktree (`superpowers:using-git-worktrees`), stage-3 review is mandatory, then the human reviews the diff against the same `REVIEW.md` criteria, then `superpowers:finishing-a-development-branch`. No plan/TDD (no behavior change).

## Red Flags — STOP and fix

| Comment | Why it fails | Fix |
|---------|--------------|-----|
| Repeats the code (`// increment i`) | Adds nothing — reader test fails | Delete |
| Reuses the entity's own name-words (`// the capacity` on `capacity`) | Restates the name | Replace with a fact not in the code (units/bound/null/invariant) |
| Implementation detail in an interface comment | Contaminates the abstraction | Move inside the method; or if unavoidable → shallowness flag |
| Vague declaration (`// current offset`) | No precision | Add units, bounds inclusivity, null meaning, ownership, invariant |
| Verb-style field comment (how it's mutated) | Mirrors code structure | Rewrite as a noun: what it represents |

**Violating the letter of these is violating the spirit.** If a reader says a comment isn't obvious-free, it isn't — clarify, don't argue.
````

- [ ] **Step 2: Verify frontmatter is under 1024 chars and name is hyphen-only**

Run: `head -5 skills/commenting-modules/SKILL.md`
Expected: `name: commenting-modules`, description starts with "Use when".

- [ ] **Step 3: Commit**

```bash
git add skills/commenting-modules/SKILL.md
git commit -m "feat(commenting-modules): add SKILL"
```

---

## Task 5: GREEN verify — re-run scenarios WITH the skill

**Files:**
- Modify: `docs/superpowers/plans/notes/2026-06-15-commenting-baseline.md` (append "WITH skill" results)

- [ ] **Step 1: Run stage-2 behavior with the skill**

Dispatch THREE fresh subagents. Give each `SKILL.md` + `COMMENT-TYPES.md` + the fixture, and instruct: comment `rate-limiter.ts` per the skill. Collect the commented files.

- [ ] **Step 2: Run stage-3 review with the skill**

Dispatch a fresh subagent with `REVIEW.md` over each result; collect keep/fix/delete verdicts.

- [ ] **Step 3: Check the GREEN bar**

The reviewed output MUST: name the units of `refillPerSec` (tokens/sec), state that `tryAcquire` returns `null` when allowed / seconds-to-wait when throttled, state the `tokens ∈ [0, capacity]` invariant, note the clock cross-module dependency, and contain NO name-restating comments. Record pass/fail per item in the notes.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/notes/2026-06-15-commenting-baseline.md
git commit -m "test(commenting-modules): verify skill closes baseline failures (GREEN)"
```

---

## Task 6: REFACTOR — close loopholes

**Files:**
- Modify: `skills/commenting-modules/SKILL.md` (Red Flags / description only, as needed)

- [ ] **Step 1: Identify NEW rationalizations**

From Task 5 notes, list any failure that survived the skill (e.g. an agent argued a vague comment was "good enough", or padded the interface comment with implementation "for completeness").

- [ ] **Step 2: Add explicit counters**

For each surviving failure, add a row to the Red Flags table or tighten the description's symptom list. Do not add content for hypothetical failures — only observed ones.

- [ ] **Step 3: Re-test until clean**

Re-run Task 5 Steps 1–3 with the updated skill. Repeat until the GREEN bar passes with no surviving rationalizations.

- [ ] **Step 4: Commit**

```bash
git add skills/commenting-modules/SKILL.md
git commit -m "refactor(commenting-modules): close loopholes from pressure testing"
```

---

## Task 7: Edit `improving-architecture` — 3-way routing

**Files:**
- Modify: `skills/improving-architecture/SKILL.md` (add a routing step before "### 1. Explore")

- [ ] **Step 1: RED — confirm current behavior skips the choice**

Dispatch a fresh subagent with the current `improving-architecture/SKILL.md` and the prompt "improve the architecture of this module". Confirm it never asks whether the user wants commenting. Note it in the baseline file.

- [ ] **Step 2: GREEN — add the routing question**

Insert immediately after the Glossary/intro, before `### 1. Explore`:

```markdown
### 0. Choose scope

Before exploring, ask the user — one question, recommend **both**:

> Do you want **architecture only**, **commenting only**, or **both** (recommended — refactor, then comment what changed)?

- **architecture only** → continue with the steps below.
- **commenting only** → skip to `superpowers:commenting-modules` (its Stage 0 resolves the target set from your direction). Do not run the steps below.
- **both** → run the steps below; the plan's final phase will comment the touched modules (see `superpowers:writing-plans`).
```

- [ ] **Step 3: Verify**

Re-run Step 1's scenario with the edited skill; confirm it now asks the 3-way question. Record pass.

- [ ] **Step 4: Commit**

```bash
git add skills/improving-architecture/SKILL.md docs/superpowers/plans/notes/2026-06-15-commenting-baseline.md
git commit -m "feat(improving-architecture): add architecture/commenting/both routing"
```

---

## Task 8: Edit `writing-plans` — terminal commenting phase for scope=both

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (add a subsection before "## Self-Review")

- [ ] **Step 1: RED — confirm plans omit a commenting phase**

Dispatch a fresh subagent with current `writing-plans/SKILL.md` and a both-scope refactor spec; confirm the produced plan has no commenting phase. Note in baseline file.

- [ ] **Step 2: GREEN — add the instruction**

Insert before `## Self-Review`:

```markdown
## Terminal Commenting Phase (scope = both)

If the architecture work was scoped **both** (see `superpowers:improving-architecture`), append a FINAL phase to the plan: "Comment the touched modules". Its first step resolves the module set at run time via `git diff --name-only <base>..HEAD`, then invokes `superpowers:commenting-modules` over that set. It is last so every refactor task is already done and reviewed before commenting — comments are added *after* refactoring, not interleaved. Do not add this phase for architecture-only or non-refactor plans.
```

- [ ] **Step 3: Verify**

Re-run Step 1's scenario; confirm the plan now ends with the commenting phase referencing `commenting-modules` and the git-diff resolution. Record pass.

- [ ] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md docs/superpowers/plans/notes/2026-06-15-commenting-baseline.md
git commit -m "feat(writing-plans): append terminal commenting phase for both-scope refactors"
```

---

## Task 9: Edit `using-superpowers` — routing pointer

**Files:**
- Modify: `skills/using-superpowers/SKILL.md` (the "Routing by intent" list)

- [ ] **Step 1: Add the routing line**

In the "### Routing by intent" list, add:

```markdown
- **Document or comment a module (interfaces, fields, non-obvious internals)** → `superpowers:commenting-modules`
```

- [ ] **Step 2: Verify the bootstrap copy stays in sync**

The same routing list appears in the SessionStart bootstrap text. Confirm whether this repo generates the bootstrap from `SKILL.md` or stores a copy; if a copy, update it identically.

Run: `grep -rl "Routing by intent" skills/using-superpowers`
Expected: the file(s) containing the list; edit each.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers
git commit -m "docs(using-superpowers): route comment/document intent to commenting-modules"
```

---

## Task 10: Integration dry-walk

**Files:** none (verification only)

- [ ] **Step 1: Commenting-only walk**

In a fresh subagent, start from `using-superpowers` + "comment this layer: <fixture dir>". Confirm the path: routing → `commenting-modules` Stage 0 (Explore resolves set) → stages 1–3 → worktree/finish gating described. Confirm no `writing-plans`/TDD is invoked.

- [ ] **Step 2: Both walk**

In a fresh subagent, start from "improve and comment this module". Confirm: `improving-architecture` asks the 3-way, "both" routes through `writing-plans`, and the produced plan ends with the commenting phase. Confirm comments come after refactor tasks.

- [ ] **Step 3: Record results**

Append both walks' outcomes to the baseline notes. If either path breaks, return to the relevant task.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/notes/2026-06-15-commenting-baseline.md
git commit -m "test(commenting-modules): integration dry-walk of both entry points"
```

---

## Task 11: Cleanup

**Files:**
- Delete: `/tmp/commenting-fixture/` (throwaway fixture)

- [ ] **Step 1: Remove the fixture**

```bash
rm -rf /tmp/commenting-fixture
```

The baseline notes under `docs/superpowers/plans/notes/` stay — they are the eval record this repo requires for skill changes.

- [ ] **Step 2: Final review**

Confirm `skills/commenting-modules/` has exactly `SKILL.md`, `COMMENT-TYPES.md`, `REVIEW.md`, and that the three edited skills reference `commenting-modules` consistently.

---

## Notes for the PR (later, not part of implementation)

Per `CLAUDE.md`: this modifies behavior-shaping skill content, targets `dev` not `main`, must disclose the authoring environment, and must carry the before/after eval evidence (the baseline notes) — keep fork-local until that bar is met.
