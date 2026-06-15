# Syncing Context — Design

**Status:** Approved design (pending spec review)
**Date:** 2026-06-15
**Topic:** Retroactively bootstrap and maintain the stateful substrate in an existing repo.

## Problem

Stateful-superpowers adds a persistent domain substrate — `CONTEXT.md` (an opinionated
domain glossary), `docs/adr/` (append-only decision records), and `CONTEXT-MAP.md`
(multi-context map) — governed by *read-if-present / write-sparingly / never-required /
append-only / lazy*. Today that substrate only accrues organically: a term lands in
`CONTEXT.md` when `grilling` happens to resolve it during new feature work.

That means a repo which adopts the framework **partway through its life** starts with an
empty substrate. The stateful skills (`grilling`, `improving-architecture`, `zoom-out`)
have nothing to read, so they behave exactly like stateless superpowers until enough new
work has been grilled to slowly fill the glossary. The framework's headline value —
"remembers your project's language" — is unavailable retroactively.

We need a deliberate way to **reconcile `CONTEXT.md` with the vocabulary the codebase
already uses**, on demand, without violating the substrate discipline.

## Solution

A new skill, **`syncing-context`**, plus a slash command **`/sync-context`**.

The name follows the `uv sync` model: reconcile recorded state (`CONTEXT.md`) with reality
(the codebase). The first run bootstraps an empty glossary; later runs top it up and
sharpen it as the code grows. Bootstrap is simply the degenerate case where the glossary
starts empty — it is the same operation either way, so it is one skill, not two.

### What it does

1. Dispatches an **`Explore` subagent** to read the repo's **code and existing docs**
   (README, `docs/`, specs) and extract candidate domain terms — the project-specific
   nouns that name aggregates, entities, modules, domain enums, and concepts.
2. Reads the existing `CONTEXT.md` (if present) and proposes **only the delta** — terms
   the codebase uses that the glossary doesn't yet capture.
3. Presents a curated **draft glossary** (the default, "batch" mode) as a review table:
   `term → definition → suggested _Avoid_ → source artifact`. The human prunes, edits, and
   approves in a single pass.
4. Optionally, on request, walks individual terms **one-at-a-time via `grilling`** (the
   "deepen" mode) — exitable the moment the user says they're done.
5. Writes the approved terms into `CONTEXT.md` using the format in
   `skills/grilling/CONTEXT-FORMAT.md` (single source for the format — not duplicated).

### What it explicitly does NOT do

- **No ADR derivation.** ADRs record *decisions and their why*; the "why" cannot be
  recovered from code without guessing. `syncing-context` never writes an ADR. (It may
  note that ADRs accrue naturally later via `grilling`.)
- **No git-history mining.** History is about change and rationale (ADR territory), not the
  stable domain vocabulary. Sources are code + existing docs only.
- **No auto-sharding into multiple contexts.** Default is a single root `CONTEXT.md`.
- **No session-start nagging.** It never auto-suggests itself in repos lacking `CONTEXT.md`
  — that would break the "clean repo behaves like stateless / proceed silently" invariant.
  Discoverability comes from the command + README, not from breaking silence.

## Resolved decisions

| # | Decision |
|---|----------|
| 1 | **Glossary only.** Seeds `CONTEXT.md` (+ `CONTEXT-MAP.md` only if genuinely multi-context). Never derives ADRs. |
| 2 | **Human-curated, two modes.** Default **batch** (draft review table → approve in one pass). Opt-in **deepen** (walk terms one-at-a-time via `grilling`, exit anytime). Never writes `CONTEXT.md` without human confirmation. |
| 3 | **New skill + slash command.** `syncing-context` (model-invocable) and `/sync-context`. Triggers on both adoption ("set up CONTEXT.md here") and ongoing sync ("refresh / sharpen the glossary"). |
| 4 | **Sources = code + existing docs**, read by a dispatched `Explore` subagent so raw reads stay isolated; only the curated draft returns to the main session. Git history out of scope. |
| 5 | **Single root `CONTEXT.md` by default.** Multi-context layout (`CONTEXT-MAP.md` + per-context files) only *proposed* on strong structural evidence (clearly separated top-level domain packages/services with distinct vocabularies), always human-confirmed, never auto-sharded. |
| 6 | **Additive & idempotent** (the `uv sync` model). Reads existing `CONTEXT.md` first; proposes only missing terms; never rewrites human-curated entries; surfaces code/glossary conflicts for confirmation rather than silently fixing. Re-running is expected — it doubles as an ongoing sharpening pass. |

## Invariants

- **Never-fabricate.** Every proposed term traces to a real code/doc artifact, shown in the
  draft ("from `OrderAggregate` in `src/ordering/`"). No invented vocabulary.
- **Tight & opinionated.** Applies the `CONTEXT-FORMAT` filter: only project-specific domain
  terms (not general programming concepts), one-or-two-sentence definitions, canonical term
  plus `_Avoid_` synonyms.
- **Sanctioned exception to lazy creation.** `syncing-context` writes `CONTEXT.md` eagerly —
  this is allowed *only because the human explicitly invoked it*. A repo where the skill is
  never invoked still behaves exactly like stateless superpowers.
- **Terminal state.** Returns to the user with the substrate seeded; notes that `grilling`
  will now read this glossary going forward and that ADRs accrue naturally later. Does **not**
  chain into `writing-plans` (it is not a build front-end).

## Relationship to existing skills

- **`grilling`** — the consumer/partner. `syncing-context` reuses `grilling`'s
  `CONTEXT-FORMAT.md` and hands off to `grilling` for the opt-in per-term deepen mode.
  After a sync, `grilling` reads the now-populated glossary in future sessions.
- **`zoom-out`** — related but distinct. `zoom-out` is read-only/ephemeral (returns a module
  map to the conversation, writes nothing). `syncing-context` writes `CONTEXT.md`. The
  exploration styles overlap, but the output contracts differ — not folded together.

## Shape

```
skills/syncing-context/
└── SKILL.md          → references ../grilling/CONTEXT-FORMAT.md (no duplicated format spec)
commands/
└── sync-context.md   → thin wrapper that invokes the syncing-context skill
```

`commands/` is new to this plugin (skills-only today); it is a first-class Claude Code
plugin directory.

## Testing approach

Per `writing-skills`, validation is RED/GREEN pressure scenarios against fresh subagents:

- **GREEN (bootstrap):** empty repo with domain code → skill dispatches Explore, presents a
  curated draft, writes `CONTEXT.md` only after approval, every term traces to an artifact,
  no ADR written, no general-programming terms included.
- **GREEN (sync/sharpen):** repo with a partial `CONTEXT.md` → proposes only missing terms,
  leaves existing entries untouched, surfaces (does not silently fix) a code/glossary conflict.
- **GREEN (multi-context):** repo with distinct top-level domain packages → *proposes* the
  multi-context layout, waits for confirmation, does not auto-shard.
- **Clean-repo silence:** a normal session in a repo with no `CONTEXT.md` and no `/sync-context`
  invocation behaves identically to stateless superpowers — the skill never auto-fires.
