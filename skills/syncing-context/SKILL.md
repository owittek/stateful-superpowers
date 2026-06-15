---
name: syncing-context
description: Bootstrap a CONTEXT.md domain glossary in an existing repo that adopted stateful-superpowers partway through its life, OR re-run later to top up and sharpen the glossary as the codebase grows. Reconciles CONTEXT.md with the vocabulary the code already uses (the `uv sync` model). Glossary only — never writes ADRs.
argument-hint: "(optional) a subtree or context to focus on"
---

# Syncing Context

Reconcile `CONTEXT.md` — the project's domain glossary — with the vocabulary the codebase
already uses. First run on an empty repo bootstraps the glossary; later runs top it up and
sharpen it. Bootstrap is just the case where the existing glossary is empty: it is one
operation either way (the `uv sync` model — make recorded state match reality).

This skill writes **only** `CONTEXT.md` (and, rarely, `CONTEXT-MAP.md`). It never writes
ADRs, never mines git history, and never writes anything without explicit human approval.

## When this runs

- The user explicitly invokes it (skill or `/sync-context`): adoption, or an ongoing refresh.
- It is **never** auto-suggested. A repo where this skill is never invoked behaves exactly
  like stateless superpowers — do not nag about a missing `CONTEXT.md`.

## Procedure

### 1. Read what exists

Read `CONTEXT.md` at the repo root if present (and `CONTEXT-MAP.md` → each context's
`CONTEXT.md` if multi-context). These constrain the sync: existing entries are the human's
opinionated choices and are **sacrosanct**. If nothing exists, this is a bootstrap.

### 2. Explore in a subagent

Dispatch an `Explore` subagent to read the repo's **code and existing docs** (README,
`docs/`, specs) and return candidate domain terms — the project-specific nouns that name
aggregates, entities, modules, domain states, and concepts. Sources are code + docs **only**;
do not mine git history. The subagent returns a curated candidate list, not raw file dumps,
so the main session stays lean. If the user passed an argument, scope exploration to it.

For each candidate the subagent MUST cite the artifact it came from (e.g. `OrderAggregate`
in `src/ordering/order.ts`) so nothing is fabricated.

### 3. Filter to a tight, opinionated glossary

Apply the rules in [../grilling/CONTEXT-FORMAT.md](../grilling/CONTEXT-FORMAT.md):
- Only **project-specific domain terms**. Drop general programming concepts (string, timeout,
  repository-pattern, DTO) even if heavily used.
- One- or two-sentence definitions — what the term **is**, not what it does.
- When several words name one concept, pick the canonical one and list the rest under `_Avoid_`.
- Propose **only terms not already in `CONTEXT.md`**. Never reword or delete existing entries.
- **Verify each citation yourself before it reaches the draft.** The Explore subagent cites a
  source per candidate, but you are the backstop: confirm the cited artifact actually exists
  (read the file/symbol if in doubt) and drop any term you cannot trace to a real artifact.
  Never pass through an uncited or unverifiable term — that is the never-fabricate guarantee.

### 4. Present the draft for approval (batch — the default)

Show a review table the user can prune and edit in one pass:

| Term | Definition | _Avoid_ | From |
|------|------------|---------|------|
| Order | A customer's request to purchase goods. | purchase, transaction | `OrderAggregate` |

Offer the **deepen** option: "Want to walk any of these one at a time? I can grill each term
with `superpowers:grilling` — say 'done' to stop." Only enter per-term grilling on request;
exit the moment the user says so.

### 5. Surface conflicts, don't fix them

If a candidate contradicts an existing glossary entry (the code uses a term the glossary lists
under `_Avoid_`, or a definition no longer matches usage), **surface it** for the user rather
than silently editing — same spirit as grilling's "challenge against the glossary". Only change
an existing entry on explicit confirmation.

### 6. Write only after approval

Write approved terms into `CONTEXT.md` using the format file. Create the file if absent (this
is the one sanctioned eager write — justified because the human invoked the skill). Append new
terms; leave existing ones untouched.

### Multi-context

Default to a single root `CONTEXT.md`. Only **propose** the multi-context layout
(`CONTEXT-MAP.md` + per-context `CONTEXT.md`) when there is strong structural evidence —
clearly separated top-level domain packages/services with distinct vocabularies. Present it as
a recommendation and wait for confirmation. **Never auto-shard.**

## Done

Report what was written and where. Note that `superpowers:grilling` will now read this glossary
in future sessions, and that ADRs accrue naturally later when a real decision passes grilling's
three-part gate. Do **not** chain into writing-plans — this is not a build front-end.
