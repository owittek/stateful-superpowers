# Pattern sweep — design

**PRD:** `docs/superpowers/prds/2026-11-16-design-consistency.md` (all three
features). **Depends on:** intake (follow-up list, follow-up sort, follow-up
tickets) — done on `next`.

## Intent

The same small decisions get made differently per session (how a link renders
in a table cell, text overflow, tooltip vs popover, empty-value glyph, modal
shell, which layer maps errors). The cause: the decision is never made — it
comes up incidentally inside a bigger change, gets answered on the spot, and
improvements aren't backported. The human doesn't know the answer up front
either; they ask the agent to research precedent and best practice. Goal: that
research happens automatically once per branch, and an answered pattern is
settled in code (shared primitive + enforcement + migration) so the next agent
hits a lint failure instead of re-deciding.

## Goals

- Every finished branch with source changes gets a pattern sweep before the
  follow-up sort, with no prompt from the human.
- Findings reach the human through the existing one-reply follow-up sort,
  each with a recommended disposition and a canonical choice backed by evidence.
- "now" on a sweep finding means primitive + enforcement + migration of every
  site, on the branch. "ticket" parks it with enough to redo the sweep later.
- A dropped finding is not re-raised on the same branch.
- designing-modules reuses existing helpers when new structure repeats a pattern.

## Non-goals

- A rulebook / conventions document. Rules are niche, unbounded, and unread.
- Catching patterns during planning (plans name features, not incidental
  patterns).
- Per-task sweeps inside subagent-driven-development (cost).
- Fixing things automatically without the sort (the human picked the one-reply
  sort over auto-fix).

## Anti-goals

- A feature branch silently growing a multi-file migration nobody approved.
- Noise: a sweep that returns 20 findings gets ignored. Hard cap of 5.
- Wordings or file paths in tickets that go stale before pickup.

## Constraints

- Finishing is upstream-tracked: the sweep is a new recorded insertion point
  (item 9) in `docs/upstream-sync.md`'s finishing entry, beside #16's eight.
- Helpers run by absolute path (tests/sdd-helper-paths).
- Follow-up list line format unchanged: one line per item.
- Follow-up tickets carry their own content (ADR 0005); no paths in bodies.
- Sweep runs on the most capable model (judgement work; user preference).
- Budget target ~50–80k tokens per sweep; achieved by category scoping and the
  cap, not by a cheaper model.
- No client specifics in this public repo (fixtures are synthetic).

## Approaches

| | Approach | Trade-off | |
|---|---|---|---|
| A | Own step in finishing, before the sort | One insertion point covers SDD, inline and hand-built branches; findings land where the human decides. +1 upstream insertion point, +50–80k tokens per finish | **chosen** |
| B | Inside the final whole-branch review (SDD + executing-plans) | Rides an existing review; misses hand-built branches, two insertion points | |
| C | Extra section in code-reviewer.md | No extra agent; the spike's ~130k tokens would crowd out the correctness review and make the helper search shallow | |

Calls made after the builder check (not discussed with the human): BASE
fallback, pattern mode for pickup, the ~10-site ticket threshold, PRIOR
including open items, skipping detached HEAD / discard, no separate record for
choices without a code anchor.

Disposition flow: through the one-reply follow-up sort (chosen by the human)
vs automatic in-branch fixing (rejected: unapproved scope growth).

## Domain terms and ADRs

- New term: **Pattern sweep** (CONTEXT.md).
- Uses: Follow-up, Follow-up list, Follow-up sort, Follow-ups parent, Ticket.
- docs/upstream-sync.md (finishing insertion points), ADR 0005 (follow-up tickets carry
  content). No new ADR.

## Architecture

| Module | Interface | Seam | Depth rationale | Test surface |
|---|---|---|---|---|
| **Pattern sweep prompt** — `skills/finishing-a-development-branch/references/pattern-sweep-prompt.md` | Two modes. **Branch mode** — in: `BASE_SHA`, `HEAD_SHA`, `PRIOR` (this branch's sweep follow-up lines, open and closed). **Pattern mode** (ticket pickup) — in: `PATTERN` + `CANONICAL` from the ticket; sweeps the whole repo for that pattern only. Out: ≤5 findings (branch mode) or all sites of the one pattern (pattern mode), fixed shape (below), or exactly `NO FINDINGS`. Read-only: never edits files. | the prompt template, dispatched as a fresh subagent | Deep: hides category selection, helper-exists search, sibling search (grep + reading), classification, ranking. | Paid eval: synthetic fixture repo (below) |
| **Step 0 sweep insertion** — finishing `SKILL.md` | Before `followup list`. Skipped on a detached HEAD, on the discard path, and when every changed file is docs/tests/config. BASE = merge-base with the base branch if already known (plan, ticket, conversation), else with the default branch; Step 3 still confirms the base for merging. PRIOR = `followup list` lines ending `(sweep)` or `(sweep) → …` (the glue filters; no new followup flag). For each finding `followup add "<pattern> → <canonical choice>" --source sweep`. Full findings stay in session for the sort. | finishing Step 0 | Glue; shallow on purpose | Static test: SKILL.md Step 0 references the prompt and orders sweep before list |
| **Sort rules for sweep items** — `references/follow-up-sort.md` | now / ticket / drop semantics for `(sweep)` items (below) | the existing sort | Reuses the one-reply decision point | Static doc check |
| **Helper check at design** — designing-modules step 2 | One sentence after "Scoped, not a sweep": a targeted search for an existing helper for a pattern the new structure repeats (rendering, error mapping, data access) is in scope — it's one lookup per pattern, not a survey; reuse or extract what it finds. | designing-modules step 2 | n/a | none |

Finding shape (the sweep's whole output contract):

```
### N. <pattern, one line>
Kind: helper-exists | drift | not-backported | siblings-disagree
Canonical: <the choice>, because <evidence: N existing uses / named best practice>
In diff: <file:line, ...>
Outside diff: <count> sites (<2–3 examples>)
Enforce: <lint rule / arch test / component test / none — why>
Recommend: now | ticket | drop — <one-line why>
```

Ranking: helper-exists first, then not-backported, drift, siblings-disagree;
within a kind, user-visible inconsistency before internal. Category selection:
the sweep first lists which categories the diff touches (UI rendering —
overflow, tooltips, links, empty values, modals, chips; error/response mapping;
data access & dependency direction; validation & labels; naming of shared
concepts) and sweeps only those; it may add a category it sees recurring.

Handoff seam (decided): no list-format change, no report file. The one-line
follow-up text is the durable part; the full findings live in the finishing
session, which runs the sort minutes later. After a compaction the line still
suffices for ticket/drop; "now" re-greps sites anyway.

Dependencies: all in-process (prompt + existing followup/tracker scripts). No
new ports.

## Sort semantics for sweep items

- Listed in the sort with the finding's Recommend and Canonical lines.
- Recommend **ticket** rather than now when the outside-diff sites exceed ~10
  or span more than one area of the codebase; the human can still say now.
- **now:** the finishing agent re-finds sites (from the in-session findings,
  or by grepping for the pattern after a compaction), introduces or reuses the primitive, add the enforcement where the repo
  has a mechanism (lint config, arch test, component test — follow what the
  repo already uses; none → say so, no new tooling), migrate every site found
  (diff and outside), TDD as usual, then `followup done N --as now`.
- **ticket:** follow-up ticket body per ADR 0005 with What = pattern + kind,
  plus a **Canonical choice** section (choice + evidence) and **Enforcement**
  section; no paths. Acceptance criteria: primitive exists, enforcement fails
  on a new violation, no sites left (re-run the sweep scoped to this pattern at
  pickup in pattern mode). writing-plans' ticket intake runs pattern mode when the
  ticket has a Canonical choice section, and plans from its site list.
- **drop:** `followup done N --as dropped`; the next sweep on this branch gets
  it in `PRIOR` and doesn't re-raise it.
- Where the canonical choice is recorded: the doc comment on the primitive and
  the enforcement's message. Once migrated, the code itself is the precedent
  the next sweep finds. A choice with no code anchor isn't recorded separately
  (no rulebook, and ADRs stay for hard-to-reverse decisions); the next sweep
  re-derives it from precedent.

## Left to the builder

- Exact prompt wording, category list phrasing, the docs/tests/config-only
  path heuristic.
- Fixture repo contents for the eval (synthetic: a helper bypassed in one of
  several routes; a single-value cell truncated without reveal while a
  truncation primitive exists).
- Whether the eval runs in the existing claude-code skill-test harness or as a
  standalone script.
