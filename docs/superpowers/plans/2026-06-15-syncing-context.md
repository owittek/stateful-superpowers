# Syncing Context Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `syncing-context` skill plus a `/sync-context` command that retroactively bootstraps and idempotently re-syncs a repo's `CONTEXT.md` glossary from its code and docs, without violating the stateful substrate discipline.

**Architecture:** One new single-file skill (`skills/syncing-context/SKILL.md`) that dispatches an `Explore` subagent to extract project-specific domain terms, diffs them against any existing `CONTEXT.md`, presents a curated draft for human approval (batch mode) with an opt-in per-term `grilling` pass (deepen mode), then writes approved terms using the existing `skills/grilling/CONTEXT-FORMAT.md`. A thin `/sync-context` command provides an explicit, discoverable entry point. No ADRs, no git-history mining, no auto-sharding, no session-start nagging.

**Tech Stack:** Markdown skills + a Markdown slash command (Claude Code plugin format). "Tests" are RED/GREEN pressure scenarios run against fresh subagents (RED = baseline fails without the skill; GREEN = complies with it), per `superpowers:writing-skills`. No code/runtime.

**Spec:** `docs/superpowers/specs/2026-06-15-syncing-context-design.md`

**Standard skill-authoring notes:**
- `CONTEXT.md` format is owned by `skills/grilling/CONTEXT-FORMAT.md` — reference it, never duplicate it.
- Prose cross-references to sibling skills use the repo convention `superpowers:<skill>` (e.g. `superpowers:grilling`), matching existing skill bodies.
- Each pressure scenario is a "test": dispatch a fresh `general-purpose` subagent in a scratch fixture, record behavior, compare to expected.

---

## File Structure

- `skills/syncing-context/SKILL.md` — **create.** The skill. Sole responsibility: drive the explore → diff → curate → write reconciliation of `CONTEXT.md`.
- `commands/sync-context.md` — **create.** New `commands/` dir (first command in this plugin). Thin wrapper invoking the skill.
- `README.md` — **modify.** Add one bullet under the **Meta** skills list.
- `package.json`, `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `gemini-extension.json` — **modify** via `scripts/bump-version.sh` (version bump).

---

## Task 1: Author the `syncing-context` skill

**Files:**
- Create: `skills/syncing-context/SKILL.md`
- Reference (read, do not edit): `skills/grilling/CONTEXT-FORMAT.md`, `skills/zoom-out/SKILL.md` (style), `skills/handoff/SKILL.md` (single-file style)

- [ ] **Step 1: RED — baseline pressure scenario (bootstrap), no skill**

Create a scratch fixture and dispatch a fresh `general-purpose` subagent WITHOUT the skill.

```bash
mkdir -p /tmp/sync-fixture/src/ordering
printf 'export class OrderAggregate {}\nexport type InvoiceId = string\nexport class Customer {}\n' > /tmp/sync-fixture/src/ordering/order.ts
printf '# Shop\nCustomers place Orders. An Invoice is raised after dispatch.\n' > /tmp/sync-fixture/README.md
```

Dispatch (Task tool, `general-purpose`): *"Here is a repo at /tmp/sync-fixture. Set up a CONTEXT.md domain glossary for it."* No skill mention.

Record behavior. **Expected (RED):** dumps many terms unfiltered OR invents definitions OR writes `CONTEXT.md` with no human review OR includes general programming concepts (e.g. "string", "class"). Save notes to compare against GREEN.

- [ ] **Step 2: Write `skills/syncing-context/SKILL.md`**

```markdown
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
```

- [ ] **Step 3: GREEN — same bootstrap scenario WITH the skill**

Reset the fixture (re-run Step 1's `mkdir`/`printf` block), then dispatch a fresh `general-purpose` subagent: *"Use superpowers:syncing-context on the repo at /tmp/sync-fixture."*

**Expected (GREEN):** dispatches an Explore subagent; proposes a tight table (Order, Invoice, Customer — NOT "string"/"class"); each term cites a source artifact; presents the draft and waits for approval before writing; offers the deepen option. Confirm it did not write `CONTEXT.md` before approval and did not produce any ADR.

- [ ] **Step 4: REFACTOR — close loopholes**

If GREEN wrote `CONTEXT.md` without approval, included general-programming terms, skipped source citations, or auto-entered per-term grilling, tighten the offending section and re-run Step 3 until compliant.

- [ ] **Step 5: Commit**

```bash
git add skills/syncing-context/SKILL.md
git commit -m "feat(syncing-context): retroactive CONTEXT.md glossary bootstrap and re-sync

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Re-sync, multi-context, and clean-repo-silence scenarios

**Files:**
- Modify (only if a scenario exposes a loophole): `skills/syncing-context/SKILL.md`

- [ ] **Step 1: GREEN — additive re-sync / sharpen**

Build a fixture that already has a partial, human-curated glossary plus new code:

```bash
mkdir -p /tmp/sync-resync/src
printf '# Shop\n\n## Language\n\n**Order**:\nA customer request to purchase goods.\n_Avoid_: purchase\n' > /tmp/sync-resync/CONTEXT.md
printf 'export class OrderAggregate {}\nexport class Shipment {}\nexport type RefundId = string\n' > /tmp/sync-resync/src/order.ts
```

Dispatch a fresh subagent: *"Use superpowers:syncing-context on /tmp/sync-resync."*

**Expected:** proposes only the missing terms (Shipment, Refund); leaves the existing **Order**
entry byte-for-byte untouched; does not re-propose Order. Verify `CONTEXT.md`'s Order block is
unchanged after approval.

- [ ] **Step 2: GREEN — conflict surfacing**

Add code whose name collides with the glossary's `_Avoid_`:

```bash
printf 'export class Purchase {}\n' >> /tmp/sync-resync/src/order.ts
```

Dispatch a fresh subagent on `/tmp/sync-resync`.

**Expected:** it surfaces that the code uses `Purchase`, which the glossary lists under
`_Avoid_` for Order, and asks the user how to resolve — rather than silently adding a `Purchase`
term or editing the Order entry.

- [ ] **Step 3: GREEN — multi-context proposal, no auto-shard**

```bash
mkdir -p /tmp/sync-multi/src/ordering /tmp/sync-multi/src/billing
printf 'export class OrderAggregate {}\nexport class Cart {}\n' > /tmp/sync-multi/src/ordering/o.ts
printf 'export class Invoice {}\nexport class LedgerEntry {}\n' > /tmp/sync-multi/src/billing/b.ts
```

Dispatch a fresh subagent on `/tmp/sync-multi`.

**Expected:** it *proposes* a multi-context layout (an `ordering` and a `billing` context) and
waits for confirmation; it does not create `CONTEXT-MAP.md` or per-context files unprompted.

- [ ] **Step 4: GREEN — clean-repo silence**

```bash
mkdir -p /tmp/sync-silent/src && printf 'export const add = (a,b)=>a+b\n' > /tmp/sync-silent/src/u.ts
```

Dispatch a fresh subagent: *"Help me add a multiply function to the repo at /tmp/sync-silent."*
(Do NOT mention syncing-context; assume the SessionStart bootstrap context is loaded.)

**Expected:** the agent just helps with the function. It does **not** auto-invoke syncing-context
or nag about a missing `CONTEXT.md`. This guards the stateless-equivalence invariant.

- [ ] **Step 5: REFACTOR + commit (only if any scenario exposed a loophole)**

Tighten `SKILL.md`, re-run the failing scenario until compliant, then:

```bash
git add skills/syncing-context/SKILL.md
git commit -m "fix(syncing-context): close loopholes from re-sync/multi-context/silence scenarios

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

If no changes were needed, record "no loopholes found — no change" and skip the commit.

---

## Task 3: Add the `/sync-context` slash command

**Files:**
- Create: `commands/sync-context.md`

- [ ] **Step 1: Write the command file**

```markdown
---
description: Bootstrap or re-sync this repo's CONTEXT.md domain glossary from its code and docs.
argument-hint: "(optional) a subtree or context to focus on"
---

Use the `superpowers:syncing-context` skill to reconcile this repository's `CONTEXT.md` domain
glossary with the vocabulary the codebase already uses. If the user provided an argument, pass
it to the skill as the subtree/context to focus on.
```

- [ ] **Step 2: Verify command discovery**

Run: `ls commands/ && cat commands/sync-context.md`
Expected: file present; frontmatter has `description` and `argument-hint`; body invokes
`superpowers:syncing-context`.

- [ ] **Step 3: GREEN — command triggers the skill**

In a session (or fresh subagent) with the plugin loaded, run `/sync-context` against a fixture.
**Expected:** it invokes the `syncing-context` skill and runs the procedure from Task 1.

- [ ] **Step 4: Commit**

```bash
git add commands/sync-context.md
git commit -m "feat(sync-context): add /sync-context command entry point

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Document the skill in the README

**Files:**
- Modify: `README.md` (the **Meta** list, after the `handoff` bullet near line 201)

- [ ] **Step 1: Add the bullet**

After the `- **handoff** - ...` line, add:

```markdown
- **syncing-context** - Bootstrap or re-sync a repo's CONTEXT.md glossary from its code and docs (the `uv sync` model; glossary only, never ADRs)
```

- [ ] **Step 2: Verify**

Run: `grep -n "syncing-context" README.md`
Expected: exactly one new line under the Meta list.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): list the syncing-context skill

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Version bump

A new user-facing skill is an additive feature → minor bump `0.1.0` → `0.2.0`.

**Files (all via the bump script):**
- Modify: `package.json`, `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `gemini-extension.json`

- [ ] **Step 1: Confirm current version**

Run: `./scripts/bump-version.sh --check`
Expected: all declared files report `0.1.0` (no drift).

- [ ] **Step 2: Bump to 0.2.0**

Run: `./scripts/bump-version.sh 0.2.0`
Expected: every declared file updated to `0.2.0`.

- [ ] **Step 3: Audit for missed strings**

Run: `./scripts/bump-version.sh --audit`
Expected: no stray `0.1.0` outside the excluded files.

- [ ] **Step 4: Commit**

```bash
git add package.json .claude-plugin/plugin.json .cursor-plugin/plugin.json .codex-plugin/plugin.json .claude-plugin/marketplace.json gemini-extension.json
git commit -m "chore: bump to 0.2.0 (syncing-context skill)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**1. Spec coverage:**
- Glossary only, never ADRs → Task 1 Step 2 (skill body) ✓
- Two modes (batch default, opt-in deepen via grilling, exitable) → Task 1 Step 2 §4 ✓
- New skill + `/sync-context` command (both) → Tasks 1 & 3 ✓
- Sources = code + docs via Explore subagent; no git history → Task 1 Step 2 §2 ✓
- Single-context default, multi-context proposed only, never auto-shard → Task 1 §Multi-context; Task 2 Step 3 ✓
- Additive/idempotent, never rewrite human entries, surface conflicts → Task 1 §3/§5; Task 2 Steps 1–2 ✓
- Never-fabricate (source citations) → Task 1 §2; GREEN check Task 1 Step 3 ✓
- Tight/opinionated filter via CONTEXT-FORMAT → Task 1 §3 ✓
- No session-start nagging / stateless-equivalence → Task 1 §When-this-runs; Task 2 Step 4 ✓
- Terminal: report + point at grilling, no writing-plans chain → Task 1 §Done ✓
- README + version → Tasks 4 & 5 ✓

**2. Placeholder scan:** No TBD/TODO. Skill body, command body, README line, and all commands are given verbatim. Fixture setup and subagent prompts are concrete.

**3. Type/name consistency:** Skill `name: syncing-context`; command invokes `superpowers:syncing-context`; format reference path `../grilling/CONTEXT-FORMAT.md` matches the repo (verified present). Version target `0.2.0` consistent across Task 5.

**Dependency order:** 1 (skill) → 2 (harden skill) → 3 (command, needs skill) → 4 (README) → 5 (version, last).
