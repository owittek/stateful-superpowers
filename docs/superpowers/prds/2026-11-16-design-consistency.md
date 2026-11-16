# Design consistency — PRD

## Problem

In the user's projects the same small decisions get made differently every
session: links in table cells (a primary-colour "Link" label vs plain
unclickable text vs the full blue URL), text overflow (ellipsis, `title=`,
tooltip, "+N" with hover), tooltip types, modal shells, empty-value dashes, and
structural ones — which layer owns fetching, dependency direction, local vs
shared helpers.

The cause is mostly not agents ignoring rules. **The decision was never made:**
each session meets the choice incidentally, inside a bigger change ("add a
column" that happens to contain a link), answers it on the spot, and moves on.
Improvements made in one place aren't backported. The user only notices by
chance, and even then usually asks the agent to research precedent and best
practice — so a gate that asks the user adds visibility, not answers.

Why not a `CONTEXT.md`-style document: the rules are niche and unbounded, can't
be written ahead of time, and a long rulebook isn't read. `CONTEXT.md` holds
what things *are*; this is how things are *done*.

## Approach chosen

**Code first, triggered at review.** When a recurring pattern is found, the fix
is a shared primitive (component, helper) plus an enforcement check (lint rule,
architecture test) plus migrating the existing instances. Prose only for what
code can't encode. This is what the user already aims for in architecture
passes; the goal is to make it automatic and enforced.

- Planning and design passes won't catch it — plans name features, not the
  incidental patterns inside them.
- The diff can't hide it: a review-time **pattern sweep** enumerates recurring
  patterns in the diff (not features) and searches for siblings outside it.
- Each pattern needs catching only once: after the primitive + lint rule land,
  the next occurrence fails lint during implementation.

## Spike evidence (2026-11-16)

A throwaway sweep over a real ~150-file, +8k-line feature branch in a client
app, with no hint of what to look for:

- Caught the target unprompted (an overflow "+N on hover" summary that left a
  single long value truncated without a tooltip; three pre-existing overflow
  variants elsewhere) plus related drift (five "+N more" wordings, three chip
  styles).
- The highest-value findings came from **"does a helper for this already
  exist?"** — hand-rolled error mapping bypassing an existing helper (and
  leaking internal error text), an improvement applied in four routes but not
  the fifth, a first-ever dependency-direction violation.
- The repo already had lint-based arch bans; most findings were lintable.
- Problems: 19 findings (noise), ~120–150k tokens. ~40% of the visual
  categories didn't apply — the sweep should first pick categories the diff
  touches. Grep finds literal siblings; semantic ones need reading.
  DRIFT vs PRE-EXISTING-INCONSISTENCY is a judgement call.

## Features

1. **Pattern sweep at review** — scoped to the categories the diff touches,
   helper-reuse question first, ranked, capped.
2. **Fix top findings in-branch** as primitive + enforcement + migration;
   park the rest via intake (`docs/superpowers/prds/2026-11-16-intake.md`).
   Parked tickets name the pattern and canonical choice; pickup re-runs the
   sweep for fresh sites (no stale paths in ticket bodies, per the tracker
   bridge's ticket template).
3. **designing-modules hook** — sibling sweep in "read the abutting code" so
   new structure reuses or extracts primitives up front.

Depends on intake feature 2 for parking. Feature 1 + the in-branch half of 2
can be trialled earlier without parking.

## Open

- Cost budget per review and how the sweep is scoped.
- Where the canonical choice is recorded when it can't be encoded in code.
- How the sweep finds semantic siblings beyond grep.
