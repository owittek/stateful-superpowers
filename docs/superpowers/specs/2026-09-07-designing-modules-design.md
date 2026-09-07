# Designing Modules — Design

## Problem

The architecture vocabulary and design machinery in this repo — `LANGUAGE.md`'s
module/interface/depth/seam terms, `DEEPENING.md`'s dependency categories and
seam discipline, `INTERFACE-DESIGN.md`'s design-it-twice pattern — live inside
`improving-architecture`, a skill scoped to *existing* code. `using-superpowers`
routes to it only for refactors: "restructure existing code, behavior preserved."

But roughly half that machinery is greenfield-usable, and the normal flow needs
it. `brainstorming` step 5 instructs the agent to "cover: architecture,
components, data flow" and hands it nothing to do that with — no vocabulary, no
seam discipline, no interface-comparison pattern, and none of the CONTEXT.md/ADR
capture that fires when modules get named and seams get placed.

The observed workaround is a human manually invoking `improving-architecture`
mid-brainstorm, against its own routing rules, to borrow the design half. That
works, but only because a person knows to do it — the agent never will, and the
discovery front-end (hot-spot sweep, HTML before/after report) is dead weight
when there is no code to review yet.

## Scope of the change

Extract the design engine as a shared skill, exactly as `grilling` was extracted
as the shared interview engine.

1. A new skill, `designing-modules`, owning the architecture vocabulary and the
   module/seam design procedure.
2. `improving-architecture` keeps its discovery front-end and delegates the
   design phase.
3. `brainstorming` gains an optional, just-in-time architecture pass.
4. `writing-plans` consumes the resulting Architecture section instead of
   re-deriving decomposition.
5. `using-superpowers` names the second shared engine without adding a third
   routing destination.

This is a skill-authoring change. Skill content shapes agent behavior, so it is
developed with `writing-skills` and pressure-tested, not written once.

## Skill graph

Today the design engine is trapped inside the refactor front-end:

```
brainstorming ──▶ grilling ──▶ approaches ──▶ design ──▶ spec ──▶ writing-plans
                                              (no architecture machinery)

improving-architecture ──▶ explore ──▶ HTML report ──▶ grilling ──▶ [LANGUAGE
                                                       + DEEPENING
                                                       + INTERFACE-DESIGN] ──▶ writing-plans
```

After: two shared engines behind two peer front-ends.

```
                 ┌─────────────┐     ┌────────────────────┐
brainstorming ───┤             ├─────┤                    ├──▶ spec ──▶ writing-plans
                 │  grilling   │     │ designing-modules  │
improving-arch ──┤ (interview) ├─────┤ (module + seam     ├──▶ writing-plans
     ▲           └─────────────┘     │  design)           │
     │                               └────────────────────┘
  explore + HTML report
  (stays here — existing code only)
```

`designing-modules` **returns to its caller**; the caller owns the terminal
state. A standalone invocation falls through to `writing-plans`.

### Why not the alternatives

- **A greenfield branch inside `improving-architecture`.** Makes the skill's own
  name and description lie — there is nothing to improve in code that does not
  exist — and leaves the engine un-invocable when the user just wants "design
  the architecture for this spec."
- **Inline the pass into `brainstorming`, reading `improving-architecture`'s
  reference files in place.** Cheapest edit, but hides the engine from direct
  invocation and duplicates the procedure the moment `improving-architecture`
  needs it too.

## The `designing-modules` skill

### Files

Moved in from `improving-architecture/`:

- `LANGUAGE.md` — module, interface, implementation, depth, seam, adapter,
  leverage, locality; the deletion test and seam principles.
- `DEEPENING.md` — the four dependency categories and how each is tested across
  its seam.
- `INTERFACE-DESIGN.md` — design-it-twice via parallel subagents.

Stays behind in `improving-architecture/`: `HTML-REPORT.md`. It is the discovery
front-end's output format, built around before/after visualisations of existing
shallowness — meaningless for code that does not exist yet.

The moved files need no internal edits: `DEEPENING.md` and `INTERFACE-DESIGN.md`
link only to `LANGUAGE.md` and each other, and travel together. Only the two
files that stay behind have links to retarget — six in total.

### Procedure

1. **Resolve the module set** from the caller's design. If the design is not
   resolved, bounce to `superpowers:grilling` first. The skill never runs an
   interview of its own — both front-ends grill before they call it, and a
   second module-level interview would re-ask what the frontier already settled.
2. **Scoped read of abutting code.** Read only the modules the work touches or
   sits next to, to place new seams against existing ones. Explicitly *not*
   `improving-architecture`'s `git log` hot-spot sweep; that belongs to the
   discovery front-end and re-running it here would blur the two skills back
   together.
3. **Propose the structure** as the Architecture section (template below).
4. **Optional design-it-twice** on one contested seam. The agent nominates the
   module whose seam placement is genuinely open; the user confirms. Running
   `INTERFACE-DESIGN.md`'s 3+ parallel subagents per module would cost more than
   the rest of brainstorming combined.
5. **Hand back** to the caller.

### Architecture section template

Inline in `SKILL.md` — roughly fifteen lines, not worth a fourth reference file.

| Module | Interface (what a caller must know) | Seam | Depth rationale | Test surface |

Plus a deletion-test paragraph for anything borderline, and a Mermaid diagram
when the relationships are graph-shaped.

Uses `CONTEXT.md` vocabulary for the domain and `LANGUAGE.md` vocabulary for the
architecture — the same discipline `improving-architecture` applies to its
report.

### Inline capture

Moved out of `improving-architecture` step 3, because both are triggered by
module naming and seam decisions:

- Naming a module after a concept not in `CONTEXT.md` → add the term, per
  `../grilling/CONTEXT-FORMAT.md`. Create the file lazily.
- Sharpening a fuzzy term mid-conversation → update `CONTEXT.md` there.
- A structure rejected for a load-bearing reason → offer an ADR, per
  `../grilling/ADR-FORMAT.md`. Only when a future explorer would otherwise
  re-propose the same thing.

This is what gives the brainstorming path stateful capture, which it has none of
today.

## Wiring

| File | Change |
|---|---|
| `skills/designing-modules/` | New: `SKILL.md` plus the three moved reference files |
| `skills/improving-architecture/SKILL.md` | Retarget 3 `LANGUAGE.md` links (lines 12, 23, 79) to `../designing-modules/`; collapse step 3's four capture bullets into a delegation call. Steps 0, 1 and 2 and the inline glossary are untouched |
| `skills/improving-architecture/HTML-REPORT.md` | Retarget 3 `LANGUAGE.md` links (lines 42, 108, 123) |
| `skills/brainstorming/SKILL.md` | New checklist item between 4 and 5; items 5–9 renumber. Just-in-time offer |
| `skills/writing-plans/SKILL.md` | One line in *File Structure* |
| `skills/using-superpowers/SKILL.md` | One line under the routing section; no new routing row |
| `README.md` | Skill-list entry under Engineering |
| `docs/upstream-sync.md` | Provenance row and deliberate-divergence note |

### `improving-architecture`

The inline glossary block stays. The skill needs that vocabulary during Explore
and while writing the report, before it ever delegates, and it points at
`../designing-modules/LANGUAGE.md` for the full definitions — the same
cross-skill relative reference it already uses for
`../grilling/CONTEXT-FORMAT.md`.

Step 3's tail becomes:

```markdown
Once the user picks a candidate, invoke `superpowers:grilling` to walk the
decision tree, then `superpowers:designing-modules` to design the deepened
module's interface and seams — it owns the CONTEXT.md/ADR capture around
naming and seam decisions.

Once the deepened-module design is resolved, invoke `superpowers:writing-plans`
to sequence the refactor — it runs the standard execute/TDD spine.
```

### `brainstorming`

New checklist item, placed after "propose 2-3 approaches" and before "present
design". Architecture is worked out for the *chosen* approach: approaches are
usually product-level ("SSE vs polling"), and running design-it-twice across
three still-live approaches triples the cost for options that get discarded.

The offer follows the visual companion's tested pattern — own message, single
offer, no re-offer if declined:

> Trigger: after the approach is chosen, when the design introduces **2+ new
> modules** *or* lands in an **existing codebase with seams it must fit**.
> Otherwise never mentioned.
>
> *"Before I write this up — want me to do an architecture pass first? I'd work
> out the module structure, what each interface hides, and where the seams go,
> and it becomes the Architecture section of the spec. Worth it here because
> \<reason\>; skip it if you'd rather I just write the design."*

The `because <reason>` slot is load-bearing: it forces the agent to name the
specific trigger that fired, which stops the offer degrading into a reflex on
every brainstorm.

The scope question `improving-architecture` asks up front (architecture only /
commenting only / both) is **not** inherited. New modules get their comments as
part of TDD in the plan; the "both" scope exists because refactors leave stale
comments behind.

### `writing-plans`

One line in the *File Structure* section: if the spec has an Architecture
section, adopt its modules and seams and name files after them rather than
re-deriving the decomposition. Without this the pass's output is silently
discarded at the plan boundary, which is the failure mode that makes the whole
feature pointless.

### `using-superpowers`

No new row in the intent-routing table — a third front-end would compete with
the new-behavior/preserve-behavior split the table exists to enforce. Instead,
one line under the routing section:

> Both front-ends share `grilling` (the interview) and `designing-modules`
> (module and seam design).

`designing-modules`' own `description:` says invoked-by-both plus
standalone-usable, exactly like `grilling`'s.

### `handoff`

No change. It names skills that *resume* work — `improving-architecture`,
`systematic-debugging`, `receiving-code-review` — and `designing-modules` never
resumes work on its own.

## Upstream sync

`improving-architecture` came from `mattpocock/skills`, which has no git lineage
here; syncing is a manual diff-and-port recorded in `docs/upstream-sync.md`. So
moving the three reference files costs no merge conflicts, only future port
friction, and the fix is to record the split — the same treatment `grilling`
already gets for folding three upstream skills into one.

Add to the provenance table:

| `designing-modules` | `engineering/improve-codebase-architecture` + `engineering/codebase-design` (design half, split out of `improving-architecture`) |

Add to deliberate divergences: the discovery/design split, so the next reviewer
diffs `improving-architecture` against both fork skills rather than concluding
the design content was dropped.

## Verification

Manual adversarial pressure-testing per `writing-skills`, across fresh sessions.
`evals/` is not cloned in this working copy, and a drill suite is
disproportionate for a fork-local extraction that will never go upstream — but
two behaviours genuinely need proving:

1. **The offer fires when it should, and stays quiet when it shouldn't.** A
   multi-module brainstorm offers the pass; a single-function utility never
   mentions it.
2. **No routing regression.** "Refactor this" still reaches
   `improving-architecture`, not `designing-modules`.

The second offer in `brainstorming` is the real risk in this change: it now
competes with the visual companion for the same "don't be annoying" budget. Test
a session where both triggers could plausibly fire.

## Rollout

Branch `feat/designing-modules` off `main`. Bump 0.7.0 → 0.8.0 via
`scripts/bump-version.sh` — a new skill is a minor bump on the fork's 0.x line.
