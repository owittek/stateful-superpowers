# Commenting Modules — Design

## Problem

The architecture workflow (`improving-architecture` → `writing-plans` → execute) makes modules deeper but says nothing about *documenting* them. Ousterhout's other half — commenting modules the right way (A Philosophy of Software Design, ch. 13) — is missing, and it matters for both humans and AI navigating a codebase.

Crucially, agents are bad at this when left to their own judgment. They write comments that repeat the code, restate the entity's own name, leak implementation detail into interface comments, and stay too vague to add precision. So commenting cannot be a sentence buried in a refactor skill's description — it has to be **its own step in the lifecycle**, with its own discipline and its own review.

## Scope of the change

Three things:

1. A new **rigid** skill, `commenting-modules`, that adds Ousterhout-style comments to a confirmed set of modules and reviews them against his criteria.
2. A **routing change** in `improving-architecture`: ask, up front, whether the user wants architecture only, commenting only, or **both (recommended)**.
3. A **terminal-phase instruction** in `writing-plans`: when scope = both, append a final "comment the touched modules" phase to the plan.

This is a skill-authoring change. Skill content shapes agent behavior, so it must be developed with `writing-skills` and pressure-tested, not just written once.

## Routing (entry point)

`improving-architecture`'s front-end asks the 3-way question before exploring:

- **architecture only** → today's flow, unchanged.
- **commenting only** → skip the refactor entirely; go straight to `commenting-modules` against modules the user names *by direction* (see stage 0).
- **both (recommended)** → run the refactor, then comment the modules it actually touched.

One front door, one shared vocabulary. No new top-level routing skill.

## The `commenting-modules` skill

Rigid skill. Reuses the `improving-architecture` glossary exactly (Module / Interface / Implementation / Seam / …) — Ousterhout's interface-vs-implementation comment split maps directly onto Interface (everything a caller must know) vs Implementation (what's inside).

### Stages

**Stage 0 — Resolve & confirm the target set (entry-aware).**

- *architecture / both:* seed from `git diff --name-only <base>..HEAD` on the refactor branch — comment exactly what the refactor *actually* changed (refactors drift from the plan). Optionally suggest adjacent modules worth commenting in the same pass.
- *commenting only:* the user gives a *direction*, not a list ("this functionality", "this layer", some named modules). An **Explore-agent pass** resolves that into a concrete candidate set — same mechanism as `improving-architecture` step 1.

Both converge on a **confirmed module set** before anything is written.

**Stage 1 — Cross-module exploration.**

Run *before* dispatching any per-module subagent, because a per-module subagent can't see decisions that span modules. The exploration agent **traces actual usage/dependencies** across the confirmed set to:

- identify any decision that spans module seams, and
- locate its **natural focal point** — the declaration or seam every dependent code path routes through (Ousterhout's `Status`-enum example).

The cross-module comment goes *at that focal point, next to the code*. Each dependent site gets a thin pointer comment. **No central `designNotes`/`design-notes.md` file** — it risks staleness (Ousterhout's own caveat) and the glossary (`CONTEXT.md`) and ADRs don't fit. Only if there is genuinely no focal point does it fall back to documenting at the primary module with pointer comments from the rest.

Cross-module work is rare; most runs find none.

**Stage 2 — Per-module comment-writing subagents.**

One subagent per module (or small batch), each producing the four Ousterhout categories where they apply:

1. **Interface comments** — module/class + every method: the abstraction as callers perceive it, each arg + return, side effects, exceptions, preconditions. Caller must be able to use it without reading the body.
2. **Field / variable comments** — instance/static vars and non-obvious locals; carry precision (units, inclusive/exclusive bounds, null meaning, resource ownership/lifetime, invariants). *Think nouns, not verbs.*
3. **Implementation comments** — only where non-obvious; *what & why, not how*; block/loop headers, "how we get here".
4. **Cross-module** — only the pointer comments placed per stage 1.

Follow the language's doc-tool conventions (Javadoc / godoc / JSDoc / rustdoc / Doxygen).

**Stage 3 — Comment review.**

A **fresh subagent** (no memory of writing them — same reason code review uses fresh eyes) runs the criteria in `REVIEW.md`. Verdict per comment: **keep / fix / delete**, fix applied and re-checked.

### Shallowness flag (carried throughout)

When a subagent *cannot* write an interface comment without leaking implementation detail, that signals the module is still shallow (Ousterhout: "the act of writing comments can provide clues about the quality of a design"). The subagent **flags it, does not act** — records "module X resists a clean interface comment → candidate for deepening" and writes the best honest comment it can. At the end the step reports the flags:

- in a **both** run → re-entry candidates for `improving-architecture`;
- in a **commenting-only** run → surfaced to the user as "these would comment better if deepened first".

No automatic mid-flight loop-back.

## Review criteria (`REVIEW.md`) — from Ousterhout ch. 13

**Per comment**
- *Not obvious from adjacent code* — the reader test: could someone write this comment just by reading the code next to it? Yes → delete. "Obvious" is judged from a first-time reader, not the author (13.8).
- *Doesn't repeat the code, doesn't reuse the entity's name-words* (Red Flag: Comment Repeats Code).
- *Right level* — adds **precision** (lower) or **intuition** (higher). A same-level comment that mirrors the code is the failure.

**Per declaration (field / arg / return)**
- Carries precision where it applies: **units, inclusive/exclusive bounds, null meaning, resource ownership/lifetime, invariants**. Vague is the dominant failure. **Nouns not verbs.**

**Per interface comment**
- Complete enough to use without reading the body: behavior as callers see it, each **arg + return, side effects, exceptions, preconditions**.
- **No implementation detail** (Red Flag: Implementation Contaminates Interface) — if it can't be written without leaking implementation, raise the **shallowness flag**.

**Per module (coverage)**
- Every class, method, and class variable has an interface comment — except the genuinely obvious (a plain getter/setter).

Same checklist drives the stage-3 subagent and the human sign-off.

## Lifecycle integration

### Both path

`improving-architecture` (scope=both) → `writing-plans`, instructed to append a **terminal commenting phase** listing the modules to comment (resolved at run time via the stage-0 git diff). The existing execute spine carries it; because it's the last phase, every refactor task is already done and per-task-reviewed before commenting begins — satisfying "comment *after* refactored and reviewed". Stage-3 review + human sign-off ride along in the normal branch finish.

### Commenting-only path

Not "free" — a lighter but real process, because the comments must be held to the criteria and that judgment needs a gate, not a self-pass:

1. **worktree** (`using-git-worktrees`) — a reviewable changeset.
2. **commenting step** stages 0–2.
3. **stage-3 comment review** — fresh subagent, the `REVIEW.md` criteria (mandatory).
4. **human diff review against those same criteria** — user signs off that the comments are correct, adhere, and earn their place. The changeset is small and readable by design.
5. **`finishing-a-development-branch`**.

No `writing-plans`, no TDD — there is no behavior change to specify or test. The discipline is the two review layers (automated criteria review + human criteria review).

## Files

Mirrors `improving-architecture`'s split:

- `skills/commenting-modules/SKILL.md` — front-matter, glossary reuse, the four stages, the shallowness flag, Red Flags table (repeats-code, impl-contaminates-interface, name-restating).
- `skills/commenting-modules/COMMENT-TYPES.md` — the four categories, precision-vs-intuition, "nouns not verbs", and worked before/after examples drawn from the chapter. Keeps `SKILL.md` terse; subagents read it.
- `skills/commenting-modules/REVIEW.md` — the criteria checklist above.

Edits to existing skills:

- `skills/improving-architecture/SKILL.md` — the 3-way routing question at the front.
- `skills/writing-plans/SKILL.md` — the terminal-commenting-phase instruction for scope=both.
- `skills/using-superpowers/SKILL.md` — routing-by-intent note pointing "document/comment a module" at `commenting-modules`.

## Out of scope

- Auto-generating prose docs or README content.
- Linters / doc-coverage tooling (zero-dependency plugin).
- Touching the `improving-architecture` deletion-test / depth heuristics.

## Validation

This modifies behavior-shaping skill content. Per repo policy: develop with `writing-skills`, pressure-test `commenting-modules` across multiple sessions (especially the agent's tendency to repeat-code / leak-implementation), and capture before/after eval evidence before any upstream PR. Fork-local until that bar is met.
