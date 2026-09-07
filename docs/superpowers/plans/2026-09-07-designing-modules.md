# Designing Modules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract `improving-architecture`'s design engine into a shared `designing-modules` skill so `brainstorming` can run an architecture pass on the normal spec/plan flow.

**Architecture:** `designing-modules` becomes the second *engine skill* (after `grilling`) — invoked by both front-ends, returning to its caller rather than terminating. It owns `LANGUAGE.md`, `DEEPENING.md` and `INTERFACE-DESIGN.md`, which move out of `improving-architecture`; `HTML-REPORT.md` stays behind because it is discovery output. `brainstorming` gains an optional just-in-time architecture pass between "propose approaches" and "present design"; `writing-plans` consumes the resulting Architecture section.

**Tech Stack:** Markdown skill documents. No code, no dependencies. Bash for file moves, `sed` for link retargeting, `scripts/bump-version.sh` for the version bump. Verification is `superpowers:writing-skills` pressure testing (subagent scenarios) plus a mechanical link check.

**Spec:** `docs/superpowers/specs/2026-09-07-designing-modules-design.md`

## Global Constraints

- Repo root is `/Users/oli/code/super-claude/superpowers`. All paths below are relative to it.
- Work happens on branch `feat/designing-modules`, already created off `main`. The spec and `CONTEXT.md` are already committed there (`dbc417f`).
- **Skill edits in this checkout do not affect running agents until the plugin is reinstalled.** The installed copy lives at `~/.claude/plugins/cache/stateful-superpowers-dev/stateful-superpowers/<version>/`. Task 1's baseline runs against the currently installed **0.7.0**; Task 8's GREEN run must happen **after** Task 7 bumps to 0.8.0 and the plugin is updated from this checkout.
- Skill content shapes agent behaviour. Do not reword the parts this plan leaves alone — especially `improving-architecture` steps 0–2, its inline glossary, and `brainstorming`'s Visual Companion section.
- Every markdown link between skill files must resolve. The check appears in Task 2 Step 5 (scoped to the new skill) and Task 3 Step 5 (scoped to all five touched skills); both were verified to return no output against this branch before the plan was written. **Do not widen it to all of `skills/`** — `writing-skills/anthropic-best-practices.md` and `grilling/CONTEXT-FORMAT.md` contain illustrative links inside example blocks that intentionally point at nothing, and they are not this plan's business.
- Terminology is fixed by `CONTEXT.md`: **front-end skill**, **engine skill**, **architecture pass**, **capture moment**. Do not substitute "sub-skill", "helper", "design phase".
- Commit after every task. Commit messages use Conventional Commits (`feat(skills):`, `docs:`, `chore:`), matching the existing log.

---

## File Structure

| File | Responsibility |
|---|---|
| `skills/designing-modules/SKILL.md` | **New.** The engine: resolve module set → read abutting code → propose Architecture section → optional design-it-twice → hand back. Owns the capture moments. |
| `skills/designing-modules/LANGUAGE.md` | **Moved,** unchanged. Architecture vocabulary. |
| `skills/designing-modules/DEEPENING.md` | **Moved,** unchanged. Dependency categories, seam discipline. |
| `skills/designing-modules/INTERFACE-DESIGN.md` | **Moved,** unchanged. Design-it-twice via parallel subagents. |
| `skills/improving-architecture/SKILL.md` | **Modified.** Three link retargets; step 3's tail becomes a delegation call. |
| `skills/improving-architecture/HTML-REPORT.md` | **Modified.** Three link retargets. Content unchanged. |
| `skills/brainstorming/SKILL.md` | **Modified.** New checklist item 5 (items renumber to 10); new node in the flow graph; new "Architecture Pass" section. |
| `skills/writing-plans/SKILL.md` | **Modified.** One bullet in *File Structure*. |
| `skills/using-superpowers/SKILL.md` | **Modified.** One line under "Routing by intent". No new routing row. |
| `README.md` | **Modified.** One skill-list entry. |
| `docs/upstream-sync.md` | **Modified.** Provenance row + deliberate-divergence bullet. |
| `docs/superpowers/specs/2026-09-07-designing-modules-eval-results.md` | **New.** Baseline (Task 1) and GREEN (Task 8) transcript evidence. |
| `docs/adr/0001-engine-skills-shared-by-front-ends.md` | **New** (Task 9 — drop the task if the ADR isn't wanted). |

The moved files need no internal edits: they link only to `LANGUAGE.md` and each other, and travel together.

---

## Task 1: Baseline pressure test (RED)

`superpowers:writing-skills` is TDD for prose: if you did not watch an agent fail without the skill, you do not know the skill teaches the right thing. This task establishes what agents do **today**, before anything changes.

**Files:**
- Create: `docs/superpowers/specs/2026-09-07-designing-modules-eval-results.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the baseline half of the eval-results document. Task 8 appends the GREEN half to the same file, under a `## GREEN` heading.

- [ ] **Step 1: Confirm the installed plugin is 0.7.0 (pre-change)**

```bash
ls ~/.claude/plugins/cache/stateful-superpowers-dev/stateful-superpowers/
```

Expected: `0.7.0`. If a different version is listed, the baseline is not measuring pre-change behaviour — stop and reinstall from the `main` branch first.

- [ ] **Step 2: Run scenario S1 — multi-module brainstorm**

Dispatch a fresh subagent with this exact prompt, and no other context:

```
Let's build a rate limiter for our API — per-tenant quotas, a sliding
window, and an admin endpoint to inspect and reset counters.
```

Record in the eval file: whether `brainstorming` triggered, and whether the agent produced any module/interface/seam analysis unprompted. Save the transcript verbatim.

- [ ] **Step 3: Run scenario S2 — trivial change**

Fresh subagent, exact prompt:

```
Let's add a --version flag to the CLI.
```

Record whether the agent applied any architecture ceremony to a one-function change.

- [ ] **Step 4: Run scenario S3 — refactor routing**

Fresh subagent, exact prompt:

```
Our payment handling is a mess — modules calling into each other three
levels deep. Help me refactor it.
```

Record which skill it routed to. Expected today: `superpowers:improving-architecture`. This is the no-regression control for Task 8.

- [ ] **Step 5: Write the baseline document**

Create `docs/superpowers/specs/2026-09-07-designing-modules-eval-results.md`:

```markdown
# Designing Modules — Eval Results

Pressure tests per `superpowers:writing-skills`. Baseline runs against the
installed plugin at 0.7.0 (pre-change); GREEN runs against 0.8.0 after the
plugin is reinstalled from this checkout.

## Baseline (RED) — plugin 0.7.0

### S1 — multi-module brainstorm

Prompt: "Let's build a rate limiter for our API — per-tenant quotas, a sliding
window, and an admin endpoint to inspect and reset counters."

Observed: <what happened — did brainstorming trigger, was there any
module/seam analysis, what vocabulary did it reach for>

Transcript: <verbatim>

### S2 — trivial change

Prompt: "Let's add a --version flag to the CLI."

Observed: <what happened>

Transcript: <verbatim>

### S3 — refactor routing (no-regression control)

Prompt: "Our payment handling is a mess — modules calling into each other three
levels deep. Help me refactor it."

Observed: <which skill it routed to>

Transcript: <verbatim>

### Baseline conclusion

<one paragraph: what the gap actually is, in the agent's own observed
behaviour — not in theory>
```

Replace every `<...>` with real observations. An eval file with angle brackets left in it is worthless.

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/specs/2026-09-07-designing-modules-eval-results.md
git commit -m "test(skills): baseline pressure results before designing-modules"
```

---

## Task 2: Create the `designing-modules` skill

**Files:**
- Create: `skills/designing-modules/SKILL.md`
- Move: `skills/improving-architecture/LANGUAGE.md` → `skills/designing-modules/LANGUAGE.md`
- Move: `skills/improving-architecture/DEEPENING.md` → `skills/designing-modules/DEEPENING.md`
- Move: `skills/improving-architecture/INTERFACE-DESIGN.md` → `skills/designing-modules/INTERFACE-DESIGN.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the skill `superpowers:designing-modules`, invoked as `superpowers:designing-modules` by Tasks 3 and 4. Its reference files are addressed from `improving-architecture` as `../designing-modules/LANGUAGE.md` (Task 3). It reads `../grilling/CONTEXT-FORMAT.md` and `../grilling/ADR-FORMAT.md`, which already exist.

- [ ] **Step 1: Move the three reference files**

```bash
cd /Users/oli/code/super-claude/superpowers
mkdir -p skills/designing-modules
git mv skills/improving-architecture/LANGUAGE.md skills/designing-modules/LANGUAGE.md
git mv skills/improving-architecture/DEEPENING.md skills/designing-modules/DEEPENING.md
git mv skills/improving-architecture/INTERFACE-DESIGN.md skills/designing-modules/INTERFACE-DESIGN.md
```

Do not edit their contents. `DEEPENING.md` links to `LANGUAGE.md` and `INTERFACE-DESIGN.md` links to both — all siblings, all still resolve.

- [ ] **Step 2: Verify only `HTML-REPORT.md` and `SKILL.md` remain behind**

```bash
ls skills/improving-architecture/
```

Expected exactly: `HTML-REPORT.md`, `SKILL.md`.

- [ ] **Step 3: Write `skills/designing-modules/SKILL.md`**

````markdown
---
name: designing-modules
description: Design the module structure, interfaces and seams for work about to be built. The shared design engine behind brainstorming's architecture pass and improving-architecture's deepening candidates — invoked by those front-ends after their interview, and usable standalone to design the architecture for an existing spec.
---

# Designing Modules

Turn a resolved design into a **module structure**: what the modules are, what
each interface hides, where the seams go, and how each is tested. The aim is
depth — a lot of behaviour behind a small interface — for testability and
AI-navigability.

This skill is an **engine**, not a front-end. It returns to its caller; the
caller owns what happens next. Invoked standalone, fall through to
`superpowers:writing-plans` once the structure is settled.

## Glossary

Use these terms exactly. Don't drift into "component," "service," "API," or
"boundary." Full definitions in [LANGUAGE.md](LANGUAGE.md).

- **Module** — anything with an interface and an implementation (function, class, package, slice).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature.
- **Depth** — leverage at the interface. **Deep** = a lot of behaviour behind a small interface. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can be altered without editing in place. (Use this, not "boundary.")
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth. **Locality** — what maintainers get from it.

Key principles (full list in [LANGUAGE.md](LANGUAGE.md)):

- **Deletion test**: imagine the module gone. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it earns its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

## Process

### 1. Resolve the module set

Take the design from your caller — `superpowers:brainstorming`'s chosen
approach, or `superpowers:improving-architecture`'s chosen candidate.

**Do not run an interview.** Both front-ends grill before they call you;
re-asking what the frontier already settled is exactly the friction
`superpowers:grilling` was extracted to kill. If you were invoked standalone
against an idea nobody has grilled, stop, invoke `superpowers:grilling`, and
come back with the resolved design.

### 2. Read the abutting code

Read `CONTEXT.md` and any ADRs covering the area first. Then read the modules
the work touches or sits next to — enough to place new seams against existing
ones and to name things the way the codebase already names them.

**Scoped, not a sweep.** Do not walk the commit history looking for hot spots.
That is `superpowers:improving-architecture`'s discovery step; running it here
blurs the two skills together and buys a survey nobody asked for. Greenfield
with nothing abutting: skip this step.

### 3. Propose the structure

Present the **Architecture section**:

| Module | Interface | Seam | Depth rationale | Test surface |
|---|---|---|---|---|
| name from `CONTEXT.md` vocabulary | what a caller must know — types, invariants, ordering, error modes | where the interface lives | why this shape is deep, or why shallow is right here | what tests exercise, through which interface |

Then, as needed:

- A **deletion test** paragraph for anything borderline — would deleting this module concentrate complexity, or just move it?
- A **Mermaid diagram** when the relationships are graph-shaped (call graph, dependency, sequence). Skip it when the table already says everything.
- For each dependency, its category from [DEEPENING.md](DEEPENING.md) — that decides whether the seam needs a port and adapters at all, and how the module gets tested across it.

**Use `CONTEXT.md` vocabulary for the domain, and [LANGUAGE.md](LANGUAGE.md)
vocabulary for the architecture.** If `CONTEXT.md` defines "Order," it is "the
Order intake module" — not "the FooBarHandler," and not "the Order service."

**YAGNI.** One adapter is a hypothetical seam. Don't put a port at a seam that
will have exactly one thing behind it forever.

### 4. Design it twice — one seam, on request

Your first idea is unlikely to be the best (Ousterhout). But running parallel
interface designs for every module costs more than the rest of the design
session put together.

Nominate the **one** module whose seam placement is genuinely contested — where
you can see two defensible answers — and offer it:

> "The <name> seam could go either way. Want me to design it twice — a few
> radically different interfaces explored in parallel, then compared?"

On yes, follow [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md). On no, or when no
seam is genuinely contested, skip this step. Don't manufacture a contest to
justify the offer.

### 5. Hand back

Return the resolved structure to your caller. Do **not** invoke
`superpowers:writing-plans` yourself unless you were invoked standalone — the
front-ends have their own approval gates to run first.

## Capture as you go

These fire during steps 3 and 4. Handle them inline, as decisions crystallize —
don't batch them up for the end.

- **Naming a module after a concept not in `CONTEXT.md`?** Add the term, per [CONTEXT-FORMAT.md](../grilling/CONTEXT-FORMAT.md). Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term mid-conversation?** Update `CONTEXT.md` right there.
- **User rejects a structure with a load-bearing reason?** Offer an ADR, framed as: _"Want me to record this so a future architecture pass doesn't re-propose it?"_ Only when the reason is something a future explorer would actually need — skip ephemeral reasons ("not worth it right now") and self-evident ones. See [ADR-FORMAT.md](../grilling/ADR-FORMAT.md).
````

- [ ] **Step 4: Verify the frontmatter parses and the name matches the directory**

```bash
head -4 skills/designing-modules/SKILL.md
basename $(dirname skills/designing-modules/SKILL.md)
```

Expected: `name: designing-modules` in the frontmatter, matching the directory name `designing-modules`. A mismatch means the skill will not be invocable as `superpowers:designing-modules`.

- [ ] **Step 5: Verify every link in the new skill resolves**

```bash
cd /Users/oli/code/super-claude/superpowers
find skills/designing-modules -name '*.md' -print0 | while IFS= read -r -d '' f; do
  grep -o '](\([^)#]*\.md\)[^)]*)' "$f" | sed 's/^](//; s/[)#].*$//' | while read -r t; do
    case "$t" in http*) continue;; esac
    [ -e "$(dirname "$f")/$t" ] || echo "BROKEN: $f -> $t"
  done
done
```

Expected: no output. Any `BROKEN:` line must be fixed before committing.

- [ ] **Step 6: Commit**

```bash
git add skills/designing-modules skills/improving-architecture
git commit -m "feat(skills): extract designing-modules as a shared design engine"
```

---

## Task 3: Delegate the design phase from `improving-architecture`

**Files:**
- Modify: `skills/improving-architecture/SKILL.md` (lines 12, 23, 79 — link retargets; lines 89–98 — step 3 tail)
- Modify: `skills/improving-architecture/HTML-REPORT.md` (lines 42, 108, 123 — link retargets)

**Interfaces:**
- Consumes: `superpowers:designing-modules` and its `../designing-modules/LANGUAGE.md`, both from Task 2.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Retarget the six `LANGUAGE.md` links**

```bash
cd /Users/oli/code/super-claude/superpowers/skills/improving-architecture
sed -i '' 's|\](LANGUAGE\.md)|](../designing-modules/LANGUAGE.md)|g' SKILL.md HTML-REPORT.md
```

(On GNU `sed`, drop the `''` after `-i`.)

- [ ] **Step 2: Verify exactly six links changed and nothing else did**

```bash
cd /Users/oli/code/super-claude/superpowers
git diff --stat skills/improving-architecture/
grep -c 'designing-modules/LANGUAGE.md' skills/improving-architecture/SKILL.md skills/improving-architecture/HTML-REPORT.md
```

Expected: `SKILL.md:3` and `HTML-REPORT.md:3`. The diff should show link-only changes — no prose rewording.

- [ ] **Step 3: Replace step 3's tail with the delegation call**

In `skills/improving-architecture/SKILL.md`, find the section beginning `### 3. Grilling loop` and replace **everything from** `Once the user picks a candidate, invoke` **to the end of the file** with:

```markdown
Once the user picks a candidate, invoke `superpowers:grilling` to walk the
decision tree — it owns the interview and the CONTEXT.md/ADR capture *during*
that decision-tree conversation.

Then invoke `superpowers:designing-modules` to design the deepened module's
interface and seams. It owns the capture moments this front-end can't see —
naming a module after a concept not yet in `CONTEXT.md`, sharpening a fuzzy
term, and offering an ADR when a candidate is rejected for a load-bearing
reason — and it owns the design-it-twice option for alternative interfaces.

Once the deepened-module design is resolved, invoke
`superpowers:writing-plans` to sequence the refactor — it runs the standard
execute/TDD spine.
```

Everything above `### 3. Grilling loop` — the frontmatter, the intro, the inline glossary, step 0, step 1 and step 2 — stays byte-for-byte identical apart from the Step 1 link retargets.

- [ ] **Step 4: Verify no dangling references to the moved files remain**

```bash
cd /Users/oli/code/super-claude/superpowers
grep -rn '](LANGUAGE\.md)\|](DEEPENING\.md)\|](INTERFACE-DESIGN\.md)' skills/improving-architecture/
```

Expected: no output.

- [ ] **Step 5: Run the link check across every touched skill**

```bash
cd /Users/oli/code/super-claude/superpowers
find skills/designing-modules skills/improving-architecture skills/brainstorming \
     skills/writing-plans skills/using-superpowers -name '*.md' -print0 | while IFS= read -r -d '' f; do
  grep -o '](\([^)#]*\.md\)[^)]*)' "$f" | sed 's/^](//; s/[)#].*$//' | while read -r t; do
    case "$t" in http*) continue;; esac
    [ -e "$(dirname "$f")/$t" ] || echo "BROKEN: $f -> $t"
  done
done
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add skills/improving-architecture
git commit -m "feat(improving-architecture): delegate design phase to designing-modules"
```

---

## Task 4: Add the architecture pass to `brainstorming`

The highest-risk task: `brainstorming` now carries two just-in-time offers competing for the same "don't be annoying" budget.

**Files:**
- Modify: `skills/brainstorming/SKILL.md` (checklist lines 24–33; the `dot` flow graph; a new section before `## Visual Companion`)

**Interfaces:**
- Consumes: `superpowers:designing-modules` from Task 2.
- Produces: a spec **Architecture section**, which Task 5's `writing-plans` edit consumes by that exact name.

- [ ] **Step 1: Insert the new checklist item and renumber**

In the `## Checklist` block, insert after item 4 (`**Propose 2-3 approaches**`) and renumber the rest so the list runs 1–10:

```markdown
5. **Architecture pass (optional)** — once the approach is chosen, if it introduces 2+ new modules or lands in an existing codebase with seams it has to fit, offer `superpowers:designing-modules` in its own message. It returns a module/interface/seam structure that becomes the design's Architecture section. See the Architecture Pass section below.
```

Items 5–9 become 6–10. Their text does not change:

```markdown
6. **Present design** — in sections scaled to their complexity, get user approval after each section
7. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
8. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
9. **User reviews written spec** — ask user to review the spec file before proceeding
10. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```

- [ ] **Step 2: Add the node to the flow graph**

In the `dot` block, add the node declaration alongside the others:

```dot
    "Architecture pass?\n(superpowers:designing-modules)" [shape=diamond];
```

and replace the edge `"Propose 2-3 approaches" -> "Present design sections";` with:

```dot
    "Propose 2-3 approaches" -> "Architecture pass?\n(superpowers:designing-modules)";
    "Architecture pass?\n(superpowers:designing-modules)" -> "Present design sections" [label="offered & declined, or trigger never fired"];
    "Architecture pass?\n(superpowers:designing-modules)" -> "Present design sections" [label="accepted → Architecture section"];
```

- [ ] **Step 3: Add the Architecture Pass section**

Insert immediately **before** the `## Visual Companion` heading:

````markdown
## Architecture Pass

`superpowers:designing-modules` works out module structure, interfaces and
seams. Like the visual companion, it is a tool, not a mode — offering it does
not commit the rest of the design to architecture-speak.

**When to offer.** After the approach is chosen (checklist item 4), when either
is true:

- the design introduces **2+ new modules**, or
- it lands in an **existing codebase with seams it has to fit**.

If neither holds, never mention it. A single-function utility does not need a
seam analysis.

**The offer is its own message.** Only the offer — no clarifying question, no
summary alongside it:

> "Before I write this up — want me to do an architecture pass first? I'd work
> out the module structure, what each interface hides, and where the seams go,
> and it becomes the Architecture section of the spec. Worth it here because
> \<reason\>; skip it if you'd rather I just write the design."

**Fill in `<reason>` with the specific trigger that fired** — "this adds four
new modules that all touch the session store," not "it seems complex." Naming
the trigger is what stops the offer degrading into a reflex on every
brainstorm. If you cannot name one, the trigger did not fire: don't offer.

If they decline, continue and don't offer again unless they raise it.

**Don't stack offers.** If you have just offered the visual companion, or the
user declined it a moment ago, let a beat pass first. Two out-of-band offers
back to back read as nagging, and the second one gets a reflex "no" that has
nothing to do with its merits.

**Why after the approach, not before.** Approaches are usually product-level —
"SSE vs polling." Designing modules for three still-live approaches costs three
times as much and discards two thirds of it.

**What comes back.** A module/interface/seam table for the chosen approach. It
becomes the Architecture section of the design you present at item 6 and of the
spec you write at item 7. If the visual companion is already running, its
structure diagram belongs in the browser tab; otherwise Mermaid in the spec.
````

- [ ] **Step 4: Verify the checklist numbering and section order**

```bash
cd /Users/oli/code/super-claude/superpowers
grep -n '^[0-9]\+\. \*\*' skills/brainstorming/SKILL.md | head -12
grep -n '^## ' skills/brainstorming/SKILL.md
```

Expected: the checklist runs 1–10 with no repeats or gaps, and `## Architecture Pass` appears immediately before `## Visual Companion`.

- [ ] **Step 5: Verify cross-references to the renumbered items are still correct**

```bash
grep -n 'item [0-9]\|Checklist item [0-9]' skills/brainstorming/SKILL.md
```

Every numeric reference must point at the item it meant before the renumber. The Visual Companion section refers to itself as item 2 (unchanged); the new section refers to items 4, 6 and 7.

- [ ] **Step 6: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat(brainstorming): optional architecture pass via designing-modules"
```

---

## Task 5: Wire `writing-plans` and `using-superpowers`

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (the `## File Structure` bullet list)
- Modify: `skills/using-superpowers/SKILL.md` (after the `### Routing by intent` bullets)

**Interfaces:**
- Consumes: the spec **Architecture section** produced by Task 4.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Add the `writing-plans` bullet**

In `## File Structure`, add as the **first** bullet, above "Design units with clear boundaries…":

```markdown
- If the spec has an **Architecture section** (produced by `superpowers:designing-modules`), adopt its modules and seams as the file structure: name files after those modules and don't re-derive a different decomposition. If you think it's wrong, say so — don't silently route around it.
```

- [ ] **Step 2: Add the `using-superpowers` line**

In `### Routing by intent`, after the paragraph beginning "`brainstorming` and `improving-architecture` are **peer front-ends**", add:

```markdown
Both front-ends share the same engines: `grilling` (the interview) and `designing-modules` (module and seam design). Engines are invoked by front-ends, not routed to — don't send a task to one directly unless the user names it.
```

Do **not** add a row to the routing bullet list. A third destination would compete with the new-behavior/preserve-behavior split the list exists to enforce.

- [ ] **Step 3: Verify the routing list is unchanged**

```bash
cd /Users/oli/code/super-claude/superpowers
git diff skills/using-superpowers/SKILL.md
```

Expected: one added paragraph. The four `- **...** →` routing bullets must be untouched — this file is injected verbatim into every session by `hooks/session-start`, so churn here is the highest-blast-radius edit in the plan.

- [ ] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md skills/using-superpowers/SKILL.md
git commit -m "feat(skills): consume Architecture section and name the shared engines"
```

---

## Task 6: Documentation

**Files:**
- Modify: `README.md` (Collaboration skill list)
- Modify: `docs/upstream-sync.md` (provenance table; deliberate divergences)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing.

- [ ] **Step 1: Add the README entry**

In the `**Collaboration**` list, immediately after the `improving-architecture` line:

```markdown
- **designing-modules** - Design module structure, interfaces and seams; the shared engine behind brainstorming's architecture pass and improving-architecture's deepening
```

- [ ] **Step 2: Add the provenance row**

In `docs/upstream-sync.md`, in the `### Provenance` table, after the `improving-architecture` row:

```markdown
| `designing-modules` | `engineering/improve-codebase-architecture` + `engineering/codebase-design` (the design half, split out of `improving-architecture` — see divergences) |
```

- [ ] **Step 3: Add the deliberate-divergence bullet**

In `### Deliberate divergences — do not "sync" these back`:

```markdown
- **`improving-architecture` is split into discovery and design.** The design half — `LANGUAGE.md`, `DEEPENING.md`, `INTERFACE-DESIGN.md` and the CONTEXT.md/ADR capture moments — lives in `designing-modules`, a shared engine `brainstorming` also calls. Upstream keeps it all in one skill. When diffing, compare upstream's `improve-codebase-architecture` against **both** fork skills; the design content was moved, not dropped.
```

- [ ] **Step 4: Verify both files**

```bash
cd /Users/oli/code/super-claude/superpowers
grep -n 'designing-modules' README.md docs/upstream-sync.md
```

Expected: one hit in `README.md`, two in `docs/upstream-sync.md`.

- [ ] **Step 5: Commit**

```bash
git add README.md docs/upstream-sync.md
git commit -m "docs: record designing-modules in the skill list and sync notes"
```

---

## Task 7: Version bump

**Files:**
- Modify: `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.cursor-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.kimi-plugin/plugin.json`, `gemini-extension.json` — all via `scripts/bump-version.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: version `0.8.0`, which Task 8 verifies is the installed version before running GREEN.

- [ ] **Step 1: Check for pre-existing version drift**

```bash
cd /Users/oli/code/super-claude/superpowers
./scripts/bump-version.sh --check
```

Expected: every declared file reports `0.7.0`. If they disagree, fix the drift before bumping.

- [ ] **Step 2: Bump to 0.8.0**

```bash
./scripts/bump-version.sh 0.8.0
```

A new skill is a feature on the fork's 0.x line — minor, not patch.

- [ ] **Step 3: Audit for missed version strings**

```bash
./scripts/bump-version.sh --audit
```

Expected: no unexpected `0.7.0` strings outside the excluded files (`CHANGELOG.md`, `RELEASE-NOTES.md`, `.version-bump.json`, `scripts/bump-version.sh`).

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: bump to 0.8.0"
```

---

## Task 8: GREEN pressure test

**Files:**
- Modify: `docs/superpowers/specs/2026-09-07-designing-modules-eval-results.md`

**Interfaces:**
- Consumes: the baseline document from Task 1 and every skill edit from Tasks 2–5.
- Produces: the GREEN evidence. If any scenario fails, fix the skill prose and re-run — do not record a failure and move on.

- [ ] **Step 1: Reinstall the plugin from this checkout**

Update the `stateful-superpowers-dev` plugin so the installed copy reflects this branch, then confirm:

```bash
ls ~/.claude/plugins/cache/stateful-superpowers-dev/stateful-superpowers/
```

Expected: `0.8.0`. If it still says `0.7.0`, the subagents below will test the old skills and the results are meaningless.

- [ ] **Step 2: Re-run S1 — the offer must fire, with a named reason**

Fresh subagent, the same prompt as Task 1 Step 2:

```
Let's build a rate limiter for our API — per-tenant quotas, a sliding
window, and an admin endpoint to inspect and reset counters.
```

Pass criteria, all four:
1. `brainstorming` triggers and grills before anything else.
2. After the approach is chosen, the architecture pass is offered.
3. The offer is **its own message** — no other content in it.
4. The `<reason>` slot names a specific trigger (module count, or the existing seams it must fit) — not "it seems complex."

- [ ] **Step 3: Re-run S2 — the offer must stay silent**

Fresh subagent:

```
Let's add a --version flag to the CLI.
```

Pass criterion: the architecture pass is **never mentioned**. An offer here is a failure — fix the trigger wording in `brainstorming`'s Architecture Pass section and re-run both S1 and S2.

- [ ] **Step 4: Re-run S3 — no routing regression**

Fresh subagent:

```
Our payment handling is a mess — modules calling into each other three
levels deep. Help me refactor it.
```

Pass criterion: routes to `superpowers:improving-architecture`, **not** `designing-modules`. If it routes to `designing-modules`, the `using-superpowers` paragraph from Task 5 is reading as a routing row — tighten "invoked by front-ends, not routed to" and re-run.

- [ ] **Step 5: Add scenario S4 — the stacked-offer case**

This is the risk Task 4 introduced, and the baseline could not test it. Fresh subagent:

```
Let's build a dashboard for our deploy pipeline — a timeline view of
recent deploys, a per-service health panel, and a rollback button.
```

Pass criteria: both offers may appear, but not back to back in consecutive messages, and the user is never asked two out-of-band yes/no questions before the design is presented.

- [ ] **Step 6: Append the GREEN section to the eval file**

```markdown
## GREEN — plugin 0.8.0

### S1 — multi-module brainstorm

Result: PASS / FAIL against the four criteria (trigger, offer fires, own
message, named reason). <observations>

Transcript: <verbatim>

### S2 — trivial change

Result: PASS / FAIL — offer must never appear. <observations>

Transcript: <verbatim>

### S3 — refactor routing (no-regression control)

Result: PASS / FAIL — must reach improving-architecture. <observations>

Transcript: <verbatim>

### S4 — stacked offers

Result: PASS / FAIL — offers must not land back to back. <observations>

Transcript: <verbatim>

### Loopholes closed

<For each failure: the rationalization the agent used, the prose change that
closed it, and the re-run result. If nothing failed, say so plainly.>
```

Replace every `<...>` with real content.

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/specs/2026-09-07-designing-modules-eval-results.md skills/
git commit -m "test(skills): GREEN pressure results for designing-modules"
```

---

## Task 9: ADR — engine skills shared by front-ends

**Drop this task if the ADR isn't wanted.** It is documentation only; nothing else in the plan depends on it.

**Files:**
- Create: `docs/adr/0001-engine-skills-shared-by-front-ends.md`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing.

- [ ] **Step 1: Confirm the numbering**

```bash
cd /Users/oli/code/super-claude/superpowers
ls docs/adr/ 2>/dev/null
```

Expected: the directory does not exist yet, so this is `0001`. If it exists, use the highest number plus one and rename accordingly.

- [ ] **Step 2: Write the ADR**

```markdown
# Engine skills are shared by front-ends, not routed to

`brainstorming` and `improving-architecture` are the only skills user intent
routes to. The phases they share — the interview, and module/seam design — live
in `grilling` and `designing-modules`, which are invoked by the front-ends and
return to them rather than terminating the flow. This is why the architecture
vocabulary (`LANGUAGE.md`, `DEEPENING.md`, `INTERFACE-DESIGN.md`) sits in
`designing-modules` and not in `improving-architecture`, where it originated
upstream.

## Considered Options

- **A greenfield branch inside `improving-architecture`.** Rejected: the skill's
  name and description would misdescribe it, and the engine would stay
  un-invocable for "design the architecture for this spec."
- **Inline the design procedure into `brainstorming`.** Rejected: cheapest edit,
  but duplicates the procedure the moment `improving-architecture` needs it too.

## Consequences

Adding a third front-end means deciding which engines it reuses, not copying
their contents. Diffing against `mattpocock/skills` requires comparing its
single `improve-codebase-architecture` skill against both fork skills — see
`docs/upstream-sync.md`.
```

- [ ] **Step 3: Commit**

```bash
git add docs/adr/0001-engine-skills-shared-by-front-ends.md
git commit -m "docs(adr): record the engine/front-end skill split"
```

---

## Self-Review

**Spec coverage:** every spec section maps to a task — skill graph and skill contents → Task 2; `improving-architecture` delegation → Task 3; `brainstorming` pass → Task 4; `writing-plans` and `using-superpowers` → Task 5; upstream sync and README → Task 6; rollout/version → Task 7; verification → Tasks 1 and 8. `handoff` is explicitly unchanged, per the spec. Task 9 (ADR) is beyond the spec and marked droppable.

**Placeholder scan:** the `<...>` markers in Tasks 1 and 8 are template slots inside eval documents, each with an explicit instruction to replace them with real observations — not deferred work.

**Naming consistency:** the skill is `designing-modules` everywhere (directory, frontmatter `name:`, `superpowers:designing-modules` invocations in Tasks 3–5, README, upstream-sync, ADR). The spec artifact it produces is the **Architecture section** in Tasks 4, 5 and 8. The link check command is byte-identical in Task 2 Step 5 and Task 3 Step 5.
