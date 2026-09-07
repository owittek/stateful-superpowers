# Designing Modules — Eval Results

Pressure tests per `superpowers:writing-skills`.

## Method and its limits

`hooks/hooks.json` fires `SessionStart` only on `startup|clear|compact`, so a
dispatched subagent never receives the `using-superpowers` bootstrap, and the
skill's own `<SUBAGENT-STOP>` tells subagents to ignore it. Tests therefore run
against a harness preamble that pastes `skills/using-superpowers/SKILL.md` into
the dispatch in the same framing `hooks/session-start` uses, and instructs the
agent to read skills from this checkout by absolute path rather than through the
Skill tool.

**What this measures:** routing, trigger discrimination, offer wording, and
whether the skills' instructions are followable.

**What it does not prove:** that the bootstrap fires in a real session. That is
`CLAUDE.md`'s acceptance test ("Let's make a react todo list" in a clean
session) and is unaffected by this change, which touches no hook.

The controller played the human partner across turns. Baseline ran against the
checkout before `skills/designing-modules/` existed — verified before the runs
(`ls skills/ | grep -c designing-modules` → `0`); GREEN runs after.

**Transcripts.** Every turn of every scenario is recorded verbatim in
[2026-09-07-designing-modules-eval-transcripts.md](2026-09-07-designing-modules-eval-transcripts.md),
so each claim below is checkable rather than taken on faith. The underlying
JSONL session transcripts (tool calls and file reads) are harness scratch and
are not retained.

## Baseline (RED)

### S1 — multi-module brainstorm

Prompt: "Let's build a rate limiter for our API — per-tenant quotas, a sliding
window, and an admin endpoint to inspect and reset counters."

**Turn 1** — routed to `superpowers:brainstorming` (→ `grilling`). Ran a scope
check, then 7 questions (storage backend, window algorithm, quota granularity,
quota config, admin auth, admin scope, 429 response shape).

**Turn 2** — round 2, 5 further questions reaching genuinely deeper frontier
(Redis atomicity across 3 pods, eviction-policy risk on a shared Redis,
fail-open vs fail-closed, admin contract fields + audit log, middleware
placement and default-limit fallback).

**Turn 3** — round 3, drafted an ADR for fail-open, proposed three `CONTEXT.md`
glossary terms (*Quota*, *Window*, *Sliding-window counter*), flagged a
non-blocking follow-up, and asked 2 final questions.

**Turn 4** — presented the design.

**Observed.** The interview was excellent: 14 questions across 3 rounds, real
ADR and glossary capture, a named non-blocking follow-up. The design that came
out of it was competent and specific — request flow, Redis key layout and TTL,
quota storage, endpoint contracts, a testing section.

But it contained **no module decomposition of any kind**. Its "Architecture"
heading is a request-flow narrative (`Request → JWT auth → middleware → Lua
script → allow/deny`), not modules. Across four turns the agent never used
*module*, *interface*, *seam*, *adapter*, *depth*, *leverage* or *locality*;
never applied the deletion test; never asked what any interface should hide;
never named a test surface as an interface. The testing section lists what to
test, not what interface each test crosses.

Concretely, nothing in the output tells `writing-plans` what the file structure
should be. The decomposition gets re-derived downstream, by an agent that no
longer has the interview in context.

**Baseline verdict:** the gap is real and it is exactly where the spec says it
is — `brainstorming` produces a resolved *design* with no *structure*.

### S2 — trivial change (restraint control)

Prompt: "Let's add a --version flag to the CLI."

**Turn 1** — routed to `superpowers:brainstorming` (→ `grilling`). Four
questions: version source, `-v` alias, output format, short-circuit precedence.

**Turn 2** — declared the frontier closed, asked one remaining *fact* question
(which arg-parser), presented a four-bullet design, offered to write the spec.
Explicitly concluded: "No CONTEXT.md/ADR entry — no domain term, no
hard-to-reverse trade-off here."

**Observed.** No module/interface/seam analysis, no ceremony, design scaled to
the task, reached checklist item 5 in two turns.

**Baseline verdict:** correct restraint. GREEN must reproduce this — the
architecture pass must NOT be offered here.

### S3 — refactor routing (no-regression control)

Prompt: "Our payment handling is a mess — modules calling into each other three
levels deep. Help me refactor it."

**Observed.** Routed to `superpowers:improving-architecture` on the first turn.
Announcement: "Using superpowers:improving-architecture to find deepening
opportunities in payment handling." Cited the bootstrap's intent table
("Restructure existing code, behavior preserved (refactor)") and explicitly
noted it did not route through `brainstorming`. Stopped at the skill's Step 0
scope question.

**Baseline verdict:** correct routing, and the control Task 8 must reproduce.

### Baseline conclusion

`brainstorming` today interviews well and designs adequately, but hands
`writing-plans` no structure. The agent has no vocabulary for depth, no prompt
to ask what an interface hides, and no reason to name a seam — because the
machinery for all three lives in a skill that only fires on refactors. S2 and
S3 confirm the two behaviours the change must not break: restraint on trivial
work, and refactor routing.
