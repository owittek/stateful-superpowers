# Stateful Superpowers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fork superpowers into a stateful framework by absorbing the mechanics of Matt Pocock's engineering skills (grilling, architecture-refactoring, prototyping, navigation, context-handoff) plus a minimal persistent domain substrate (CONTEXT.md + ADRs), without breaking the existing brainstorm→plan→execute spine.

**Architecture:** Superpowers is the spine; the `skills/` engineering repo is a **donor-only** parts source (never shipped). Every graft is a surgical edit to an existing skill or a net-new skill folder under `superpowers/skills/`. A new shared `grilling` skill owns the interview-and-domain-capture discipline; `brainstorming` and `improving-architecture` invoke it. Three stateful artifacts are added (CONTEXT.md, `docs/adr/`, scale-gated PRD) governed by *read-if-present / write-sparingly / never-required / append-only / lazy* — so a clean repo behaves identically to stateless superpowers.

**Tech Stack:** Markdown skills (Claude Code plugin format). "Tests" = pressure scenarios run against fresh subagents (RED = baseline fails without skill, GREEN = complies with skill), per `superpowers:writing-skills`. No code/runtime.

**Source paths (donor, read-only):**
- `../skills/skills/engineering/{grill-with-docs,improve-codebase-architecture,prototype,zoom-out,diagnose,tdd}`
- `../skills/skills/productivity/handoff`

**Standard port adaptations** (apply to EVERY port task unless noted):
1. Strip all references to the engineering `## Agent skills` config block, `docs/agents/`, issue trackers, triage labels, and `setup-matt-pocock-skills`.
2. Rewrite cross-skill references to superpowers equivalents (e.g. donor "grill" → `Use superpowers:grilling`; donor terminal → `Use superpowers:writing-plans`).
3. Keep donor frontmatter `name`/`description` wording where it already triggers correctly; adjust only to disambiguate from existing superpowers skills.
4. Preserve donor prose verbatim except where these adaptations require change — the donor skills are carefully crafted (minimal-diff principle).

---

## Pre-flight (one-time, before Phase 1)

- [ ] **Step 1: Branch off main**

```bash
cd superpowers
git checkout -b stateful-superpowers
```

- [ ] **Step 2: Confirm donor is reachable and read-only**

Run: `ls ../skills/skills/engineering/grill-with-docs`
Expected: `ADR-FORMAT.md  CONTEXT-FORMAT.md  SKILL.md`. Never edit anything under `../skills/`.

---

## Phase 1 — `grilling` skill (FOUNDATION — everything depends on this)

The shared interview engine. Absorbs grill-with-docs' interview + domain-capture discipline. Single source of truth for: relentless one-at-a-time Q&A with recommended answers, challenge-against-glossary, sharpen-fuzzy-terms, concrete-scenario stress-tests, cross-reference-code, inline CONTEXT.md writes, and gated ADR appends.

### Task 1: Create the `grilling` skill

**Files:**
- Create: `skills/grilling/SKILL.md`
- Create: `skills/grilling/CONTEXT-FORMAT.md` (copy of donor `grill-with-docs/CONTEXT-FORMAT.md`)
- Create: `skills/grilling/ADR-FORMAT.md` (copy of donor `grill-with-docs/ADR-FORMAT.md`)
- Reference: `../skills/skills/engineering/grill-with-docs/SKILL.md`

- [ ] **Step 1: Copy the two format files verbatim**

```bash
mkdir -p skills/grilling
cp ../skills/skills/engineering/grill-with-docs/CONTEXT-FORMAT.md skills/grilling/CONTEXT-FORMAT.md
cp ../skills/skills/engineering/grill-with-docs/ADR-FORMAT.md skills/grilling/ADR-FORMAT.md
```

- [ ] **Step 2: Author `skills/grilling/SKILL.md`**

Base it on `grill-with-docs/SKILL.md`, applying the standard port adaptations. Frontmatter:

```markdown
---
name: grilling
description: Relentless interview engine that walks the design tree one question at a time (with a recommended answer per question), challenges the plan against the project's domain language and recorded decisions, and captures resolved terms into CONTEXT.md and hard-to-reverse decisions into docs/adr/ inline. Invoked by brainstorming and improving-architecture for their interview phase; can also be used standalone to stress-test a plan.
---
```

Body MUST retain these donor sections verbatim (minus standard adaptations): the `<what-to-do>` interview directive, "Challenge against the glossary", "Sharpen fuzzy language", "Discuss concrete scenarios", "Cross-reference with code", "Update CONTEXT.md inline" (pointing at `./CONTEXT-FORMAT.md`), and "Offer ADRs sparingly" with the **three-part gate** (hard-to-reverse AND surprising-without-context AND real-trade-off) pointing at `./ADR-FORMAT.md`. Retain the "Domain awareness / File structure" section (CONTEXT.md, docs/adr/, CONTEXT-MAP.md) with lazy-creation.

Add one new explicit invariant block near the top:

```markdown
## State discipline (read-if-present, write-sparingly)

- Read CONTEXT.md and docs/adr/ at the start if they exist; let them constrain the interview. If absent, proceed normally — never require them.
- Write CONTEXT.md inline only when a term is actually resolved. Append an ADR only when the three-part gate passes. Most sessions write zero ADRs.
- ADRs are append-only — supersede, never edit in place.
- This skill returns the resolved design to its caller; it does not itself write specs, plans, or implementation.
```

- [ ] **Step 3: RED — baseline pressure scenario**

Dispatch a fresh subagent (Task tool, general-purpose) with a deliberately fuzzy plan ("I want to add account cancellation") and NO grilling skill. Prompt it to "refine this plan with me." Record behavior.
Expected (RED): it asks a couple of soft questions, does not challenge terminology, does not write CONTEXT.md, jumps toward implementation. Save the transcript notes.

- [ ] **Step 4: GREEN — same scenario with the skill**

Dispatch a fresh subagent, instruct it to `Use superpowers:grilling`, same fuzzy plan.
Expected (GREEN): one question at a time with recommended answers; it challenges "account" (Customer vs User); proposes creating CONTEXT.md on first resolved term; does NOT offer an ADR for a trivially-reversible choice.

- [ ] **Step 5: REFACTOR — close loopholes**

If the GREEN agent skipped CONTEXT.md or offered a gratuitous ADR, tighten the relevant section wording, re-run Step 4 until compliant.

- [ ] **Step 6: Commit**

```bash
git add skills/grilling
git commit -m "feat(grilling): add shared interview+domain-capture engine"
```

---

## Phase 2 — `brainstorming` surgical edit (depends on Phase 1)

One step swapped; multi-feature PRD branch added to the existing decomposition logic. Everything else untouched.

### Task 2: Wire brainstorming to grilling + add scale-gated PRD

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Replace the clarifying-questions step with a grilling invocation**

In the Checklist, change item 3 from "Ask clarifying questions — one at a time…" to:

```markdown
3. **Grill the idea** — invoke `superpowers:grilling` to interview down the design tree (relentless one-at-a-time Q&A with recommended answers, challenge against CONTEXT.md/ADRs, capture resolved terms/decisions inline). Resume here with the resolved design.
```

In "The Process → Understanding the idea", replace the bullet list describing question style with a single line: "Run the interview via `superpowers:grilling` (see Checklist item 3); resume once the design tree is resolved." Leave the scope-decomposition bullets in place — they feed the next step.

- [ ] **Step 2: Add the multi-feature PRD branch to the existing decomposition logic**

In the decomposition guidance ("If the project is too large for a single spec, help the user decompose…"), append:

```markdown
For a genuinely multi-feature initiative, persist the decomposition as a **PRD umbrella** at `docs/superpowers/prds/YYYY-MM-DD-<initiative>.md` — problem statement, success criteria, and the feature list with build order. Synthesize it from the grilling already done; do NOT re-interview. Then brainstorm feature 1 through the normal spec→plan flow; each feature references the PRD. Single-feature work skips the PRD entirely (the spec's purpose section covers requirements).
```

- [ ] **Step 3: Verify the HARD-GATE and terminal state are unchanged**

Run: `grep -n "writing-plans\|HARD-GATE\|do NOT invoke" skills/brainstorming/SKILL.md`
Expected: HARD-GATE block intact; terminal state still "invoke the writing-plans skill". Confirm no other implementation skill is referenced as terminal.

- [ ] **Step 4: GREEN — end-to-end pressure scenario**

Dispatch a fresh subagent, `Use superpowers:brainstorming` on a single-feature request.
Expected: it invokes grilling for the interview, writes a spec, writes NO PRD, terminates by invoking writing-plans. Run again with a 4-subsystem request; expected: it persists a PRD umbrella then brainstorms feature 1.

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat(brainstorming): delegate interview to grilling; add scale-gated PRD umbrella"
```

---

## Phase 3 — `improving-architecture` skill (depends on Phase 1)

Net-new refactoring entry point. Keeps the donor's Explore→HTML-candidate-report front-end and deepening vocabulary; its candidate-grilling loop invokes `superpowers:grilling`; terminates into `writing-plans`.

### Task 3: Port improve-codebase-architecture as `improving-architecture`

**Files:**
- Create: `skills/improving-architecture/SKILL.md`
- Create: `skills/improving-architecture/LANGUAGE.md` (copy donor)
- Create: `skills/improving-architecture/DEEPENING.md` (copy donor)
- Create: `skills/improving-architecture/HTML-REPORT.md` (copy donor)
- Create: `skills/improving-architecture/INTERFACE-DESIGN.md` (copy donor)
- Reference: `../skills/skills/engineering/improve-codebase-architecture/SKILL.md`

- [ ] **Step 1: Copy the four support files verbatim**

```bash
mkdir -p skills/improving-architecture
cp ../skills/skills/engineering/improve-codebase-architecture/{LANGUAGE,DEEPENING,HTML-REPORT,INTERFACE-DESIGN}.md skills/improving-architecture/
```

- [ ] **Step 2: Author `skills/improving-architecture/SKILL.md`**

Base on donor `SKILL.md` with standard adaptations. Frontmatter `name: improving-architecture`; keep the donor description (it already triggers on "improve architecture / refactoring / consolidate tightly-coupled modules"). Retain verbatim: the Glossary, the `### 1. Explore` section (keep `subagent_type=Explore`), `### 2. Present candidates as an HTML report` (pointing at `./HTML-REPORT.md`, `./LANGUAGE.md`), and the side-effects in `### 3. Grilling loop`.

Make exactly two changes to `### 3. Grilling loop`:
- Replace "drop into a grilling conversation. Walk the design tree…" with: "invoke `superpowers:grilling` to walk the design tree (it owns the interview + CONTEXT.md/ADR capture; the donor's inline side-effects are now grilling's job)."
- Append a terminal line: "Once the deepened-module design is resolved, invoke `superpowers:writing-plans` to sequence the refactor — it runs the standard execute/TDD spine."

Update the CONTEXT.md/ADR-format cross-references from `../grill-with-docs/...` to `../grilling/CONTEXT-FORMAT.md` and `../grilling/ADR-FORMAT.md`.

- [ ] **Step 3: GREEN — pressure scenario**

Dispatch a fresh subagent, `Use superpowers:improving-architecture` on a small repo with a shallow pass-through module.
Expected: reads CONTEXT.md/ADRs if present; uses the Explore subagent; writes an HTML report to the OS temp dir (not the repo); asks which candidate; on selection invokes grilling; terminates by invoking writing-plans.

- [ ] **Step 4: Commit**

```bash
git add skills/improving-architecture
git commit -m "feat(improving-architecture): refactoring entry point; grilling loop + writing-plans terminal"
```

---

## Phase 4 — routing (depends on Phases 2 & 3)

### Task 4: Add the refactor-vs-feature routing line to `using-superpowers`

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`

- [ ] **Step 1: Add a routing rule under "Skill Priority"**

After the existing priority list, add:

```markdown
### Routing by intent

- **New feature / new behavior** → `superpowers:brainstorming`
- **Restructure existing code, behavior preserved (refactor)** → `superpowers:improving-architecture`
- **Bug / regression** → `superpowers:systematic-debugging`

`brainstorming` and `improving-architecture` are **peer front-ends** — both grill, both terminate into `writing-plans`. Pick by new-behavior vs preserve-behavior; do not route refactors through brainstorming.
```

- [ ] **Step 2: GREEN — routing pressure scenarios**

Dispatch fresh subagents with: (a) "refactor the order module", (b) "add CSV export". With the SessionStart context loaded.
Expected: (a) routes to improving-architecture, (b) to brainstorming. If (a) hits brainstorming, sharpen the routing wording and re-run.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "feat(using-superpowers): route refactor vs feature to peer front-ends"
```

---

## Phase 5 — `prototype` skill (subordinate to brainstorming)

### Task 5: Port prototype as a guarded, subagent-driven design-probe

**Files:**
- Create: `skills/prototype/SKILL.md`
- Create: `skills/prototype/LOGIC.md` (copy donor)
- Create: `skills/prototype/UI.md` (copy donor)
- Modify: `skills/brainstorming/SKILL.md` (one cross-reference)
- Reference: `../skills/skills/engineering/prototype/SKILL.md`

- [ ] **Step 1: Copy support files**

```bash
mkdir -p skills/prototype
cp ../skills/skills/engineering/prototype/{LOGIC,UI}.md skills/prototype/
```

- [ ] **Step 2: Author `skills/prototype/SKILL.md`**

Base on donor with standard adaptations. Frontmatter `name: prototype`; description should trigger on "prototype / sanity-check a data model / mock a UI / try a few designs" AND state it is a brainstorming-subordinate probe. Add a `## Guardrails` section verbatim:

```markdown
## Guardrails (non-negotiable)

1. **Question-gated.** Only prototype when a specific named design question resists discussion, scenarios, and code-reading. State the question before writing a line. If grilling can answer it, do not prototype.
2. **Throwaway / out-of-repo.** All prototype code lives in the OS temp dir, is NEVER committed, NEVER added to the repo, and is discarded once the question is answered.
3. **Scoped, then stop.** Halt the moment the question is answered. No feature creep into a partial build.
4. **Re-enter the gate.** Feed the finding back into the design/spec (and CONTEXT.md/ADR if it crystallized a term/decision). The real thing is later built from scratch via writing-plans→TDD — the prototype is never the seed of production code.
5. **Subagent-driven.** Run the prototype build in a dispatched subagent. Only the answer to the design question returns to the main session; the scratch code and verbose iteration stay in the subagent.
```

- [ ] **Step 3: Wire brainstorming → prototype (one line)**

In `skills/brainstorming/SKILL.md`, under the grilling step, add: "If a resolved design hinges on a question discussion can't settle, `superpowers:prototype` may be invoked as a throwaway, subagent-isolated probe (it does not bypass the HARD-GATE — see prototype guardrails)."

- [ ] **Step 4: GREEN — pressure scenario**

Dispatch a fresh subagent mid-brainstorm with a state-machine question; `Use superpowers:prototype`.
Expected: states the question; dispatches a subagent; writes scratch code to temp (not repo); returns only the answer; nothing committed. Verify `git status` is clean afterward.

- [ ] **Step 5: Commit**

```bash
git add skills/prototype skills/brainstorming/SKILL.md
git commit -m "feat(prototype): guarded subagent-driven design-probe subordinate to brainstorming"
```

---

## Phase 6 — `zoom-out` skill (standalone utility)

### Task 6: Port zoom-out

**Files:**
- Create: `skills/zoom-out/SKILL.md`
- Reference: `../skills/skills/engineering/zoom-out/SKILL.md`

- [ ] **Step 1: Author `skills/zoom-out/SKILL.md`**

Copy donor (single file) with standard adaptations. Keep `name: zoom-out` and `disable-model-invocation: true` (user-invoked). Ensure it instructs the map to use **CONTEXT.md glossary vocabulary if present**, falling back to code names if absent (read-if-present).

- [ ] **Step 2: GREEN — quick check**

Dispatch a subagent, `Use superpowers:zoom-out` on an unfamiliar module.
Expected: returns a map of modules/callers using glossary terms where CONTEXT.md exists; does not require CONTEXT.md.

- [ ] **Step 3: Commit**

```bash
git add skills/zoom-out
git commit -m "feat(zoom-out): glossary-aware area map utility"
```

---

## Phase 7 — `handoff` skill (standalone, build→review boundary)

### Task 7: Port handoff scoped to context-hygiene

**Files:**
- Create: `skills/handoff/SKILL.md`
- Reference: `../skills/skills/productivity/handoff/SKILL.md`

- [ ] **Step 1: Author `skills/handoff/SKILL.md`**

Copy donor with standard adaptations. Keep `name: handoff` and the `argument-hint`. Keep: save to OS temp dir (not workspace), "suggested skills" section, reference-don't-duplicate, redact secrets. Add a scope line to the description and body:

```markdown
Primary use: compact a long exploration / planning / orchestration session — especially at the **build → review/refactor/adjust boundary** — into a clean resume doc so a fresh session starts lean. Reference CONTEXT.md and docs/adr/ by path (do not duplicate them); the "suggested skills" section should point at the superpowers skill that resumes the work (e.g. improving-architecture, systematic-debugging, receiving-code-review).
```

- [ ] **Step 2: GREEN — pressure scenario**

Dispatch a subagent simulating a long post-build session where "something is off"; `Use superpowers:handoff`.
Expected: writes a temp-dir doc referencing the diff + relevant ADRs by path, redacts secrets, suggests a resume skill; nothing written to the repo.

- [ ] **Step 3: Commit**

```bash
git add skills/handoff
git commit -m "feat(handoff): context-hygiene compaction at build->review boundary"
```

---

## Phase 8 — audits (graft missing discipline into existing superpowers skills)

### Task 8: Audit `systematic-debugging` against donor `diagnose`

**Files:**
- Modify (only if gaps found): `skills/systematic-debugging/SKILL.md`
- Reference: `../skills/skills/engineering/diagnose/SKILL.md` (and its `scripts/`)

- [ ] **Step 1: Diff the disciplines**

Read both. Map diagnose's loop (reproduce → minimise → hypothesise → instrument → fix → regression-test) onto systematic-debugging's phases. List any step diagnose enforces that systematic-debugging lacks (likely candidates: explicit *minimise/reduce* step, mandatory *regression-test* before close).

- [ ] **Step 2: Graft only the gaps**

For each genuine gap, add a minimal phase/bullet to systematic-debugging in its existing voice. Do NOT import diagnose as a second skill. If there are no real gaps, record that and make no change.

- [ ] **Step 3: GREEN — pressure scenario (only if changed)**

Dispatch a subagent with a bug; `Use superpowers:systematic-debugging`.
Expected: it now performs the grafted step (e.g. minimises a repro, writes a regression test before declaring fixed).

- [ ] **Step 4: Commit (only if changed)**

```bash
git add skills/systematic-debugging/SKILL.md
git commit -m "feat(systematic-debugging): graft minimise/regression discipline from diagnose audit"
```

### Task 9: Audit `test-driven-development` against donor `tdd`

**Files:**
- Modify (only if gaps found): `skills/test-driven-development/SKILL.md`
- Reference: `../skills/skills/engineering/tdd/SKILL.md` (+ `deep-modules.md`, `interface-design.md`, `mocking.md`, `refactoring.md`, `tests.md`)

- [ ] **Step 1: Diff and decide**

Compare. Superpowers' TDD is expected to be at least as rigorous. Note any *integration-test-first* or *mocking* guidance worth a one-line graft. Default expectation: keep superpowers', graft little or nothing.

- [ ] **Step 2: Graft only if clearly additive; else record "no change"**

- [ ] **Step 3: Commit (only if changed)**

```bash
git add skills/test-driven-development/SKILL.md
git commit -m "docs(tdd): graft <specific> guidance from engineering tdd audit"
```

---

## Phase 9 — packaging & version bump

### Task 10: Bump version, update manifests and skill index

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (if it lists skills/version)
- Modify: `README.md` (skill list)

- [ ] **Step 1: Bump version 5.1.0 → 6.0.0**

In `.claude-plugin/plugin.json`, set `"version": "6.0.0"` and update `description` to mention the stateful domain substrate. Breaking bump because stateless→stateful is a behavioral shift.

- [ ] **Step 2: Verify new skills are discoverable**

Run: `ls skills | sort`
Expected to include: `grilling`, `improving-architecture`, `prototype`, `zoom-out`, `handoff` plus all originals. Confirm no donor-only skills (triage/to-issues/to-prd/setup) were copied in.

- [ ] **Step 3: Update README skill list**

Add one bullet per new skill under the existing list, matching the README's format.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin README.md
git commit -m "chore: bump to 6.0.0 (stateful superpowers); document new skills"
```

### Task 11: Full-pipeline smoke test

- [ ] **Step 1: Feature path**

Fresh subagent, request a small feature with the SessionStart context. Expected route: brainstorming → grilling (writes CONTEXT.md, maybe an ADR) → spec → writing-plans → offered execution. Confirm CONTEXT.md created lazily, ADR gate respected.

- [ ] **Step 2: Refactor path**

Fresh subagent, "refactor X". Expected route: improving-architecture → HTML report (temp dir) → grilling → writing-plans.

- [ ] **Step 3: Clean-repo equivalence**

In a repo with no CONTEXT.md/ADRs, confirm brainstorming/grilling run without error and require nothing — behavior matches stateless superpowers.

- [ ] **Step 4: Final commit / open PR (only when user asks)**

Do not push or open a PR until the user requests it.

---

## Self-Review

**1. Spec coverage (against the agreed design):**
- Spine = superpowers, donor-only `skills/` → Pre-flight + standard adaptations ✓
- grilling shared engine → Phase 1 ✓
- brainstorming absorbs grilling (one step), relentless tone → Phase 2 ✓
- Scale-gated PRD umbrella, multi-feature only → Phase 2 Step 2 ✓
- improving-architecture peer front-end, Explore+HTML kept, grilling reused, → writing-plans → Phase 3 ✓
- Routing refactor vs feature → Phase 4 ✓
- prototype: 4 guardrails + subagent-driven, brainstorming-subordinate → Phase 5 ✓
- zoom-out, glossary-aware → Phase 6 ✓
- handoff at build→review boundary, CONTEXT/ADR-aware → Phase 7 ✓
- diagnose/tdd audits (graft, no 2nd skill) → Phase 8 ✓
- Drop triage/to-issues/to-prd/setup → never copied; verified Phase 9 Step 2 ✓
- Stateful substrate: CONTEXT.md + docs/adr/ + read-if-present/write-sparingly/append-only/lazy → grilling state-discipline block + clean-repo equivalence test (Phase 11 Step 3) ✓
- Fork in place, v6.0.0 → Phase 9 ✓

**2. Placeholder scan:** Port tasks intentionally reference the donor as the copy-base rather than reproducing mature prose; all *novel* content (state-discipline block, guardrails, routing rules, cross-reference edits, frontmatter) is given verbatim. No TBD/TODO left.

**3. Consistency:** Cross-references resolve to `superpowers:grilling`, `superpowers:writing-plans`; format files live at `skills/grilling/{CONTEXT,ADR}-FORMAT.md` and are referenced by both grilling and improving-architecture; skill names are stable across phases.

**Dependency order:** 1 (grilling) → 2 & 3 (both need grilling) → 4 (needs 2 & 3) → 5,6,7 (independent) → 8 (independent) → 9 (last).
