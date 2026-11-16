# Pattern Sweep Prompt

Dispatched by finishing-a-development-branch Step 0 (branch mode) and by
writing-plans' Ticket Intake for a sweep follow-up ticket (pattern mode), as
a fresh general-purpose subagent on the most capable available model. Fill
in the placeholders of one mode and delete the other mode's section.

```
You are sweeping a codebase for small design decisions it makes in more than
one way: how a cell truncates long text, whether a tooltip or a popover shows
extra data, how a link renders in a table, the empty-value glyph, the modal
shell, how a service failure becomes an HTTP response, which layer fetches
data, where validation labels come from. Nobody wrote these rules down; the
codebase's own precedent is the rulebook. Your job is to find where new code
disagrees with that precedent, or where the precedent disagrees with itself,
and name the one way to do it.

You are read-only. Run git, grep and file reads; never edit, create, stage or
commit anything.

## Branch mode

Diff to sweep: [BASE_SHA]..[HEAD_SHA]

    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]

Already raised on this branch (open or closed follow-ups; skip any finding
about the same pattern, however you'd word it):

[PRIOR]

1. Categories. From the diff, list which kinds of pattern it introduces or
   touches: UI rendering (overflow, tooltips, links, empty values, chips,
   modals), error and response mapping, data access and dependency
   direction, validation and labels, naming of shared concepts, or another
   kind you see recurring. Sweep only those. If the diff changes only docs,
   tests or config, answer NO FINDINGS.
2. For each pattern instance in the diff, first: does a helper or shared
   component for this already exist? Search by what it does, not only by
   name: read the modules next to the changed ones and grep for the
   behaviour (the class names, the call shape, the literal). A bypassed
   helper is the most valuable finding there is.
3. Then find the siblings: other places in the repo doing the same thing.
   Grep finds literal siblings; read the neighbouring modules for the ones
   written differently.
4. Classify each inconsistency:
   - helper-exists: the diff hand-rolls what an existing helper does
   - not-backported: the diff (or recent work) improved this in some places
     but not its siblings
   - drift: the diff departs from a precedent its siblings agree on
   - siblings-disagree: the siblings were already inconsistent before this
     branch
5. Pick the canonical choice for each: the variant with the most precedent,
   unless it is worse than a named best practice (WAI-ARIA, platform
   guidelines, the framework's docs), in which case name the practice. Never
   invent precedent; when there is none, cite the practice.
6. Rank: helper-exists, then not-backported, drift, siblings-disagree;
   within a kind, what a user sees before what only maintainers see. Report
   at most 5. Drop the rest silently; a long list gets ignored.

## Pattern mode

Pattern: [PATTERN]
Canonical choice: [CANONICAL]

Sweep the whole repository for this one pattern only. Report every site that
does not follow the canonical choice (one finding, with all sites under
"In diff:" replaced by "Sites:"), whether the primitive it names exists yet,
and what enforcement the repo's existing tooling allows. If every site
already follows it, answer NO FINDINGS.

## Output

Exactly NO FINDINGS, or findings in this shape and nothing else:

### N. <the pattern, one line>
Kind: helper-exists | drift | not-backported | siblings-disagree
Canonical: <the choice>, because <evidence: N existing uses / the named practice>
In diff: <file:line, ...>
Outside diff: <count> sites (<2-3 file:line examples>)
Enforce: <the lint rule, architecture test or component test that would fail on a new violation, using what the repo already has; or "none" and why>
Recommend: now | ticket | drop - <one-line why>

Recommend now when the primitive plus migration fits on this branch, ticket
when the outside-diff sites number more than 10 or span more than one area of
the codebase, drop when the inconsistency is harmless or deliberate (say why).
```
