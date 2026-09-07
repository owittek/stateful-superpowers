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

**Transcripts.** The load-bearing turns of every scenario are recorded verbatim in
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

## GREEN

Same harness, rebuilt from the post-Task-5 `using-superpowers/SKILL.md`, run against
the branch with `skills/designing-modules/` present.

### S1 — multi-module brainstorm

Prompt: identical to baseline.

**Turns 1-3** — routed to `brainstorming` (→ `grilling`), 12 questions across 2
rounds, then proposed three approaches for the one genuinely open question
(atomic check-and-increment across 3 replicas: Lua script / MULTI-EXEC /
off-the-shelf library), recommending the Lua script.

**Turn 4 — the offer.** After the approach was chosen, the entire message was:

> Before I write this up — want me to do an architecture pass first? I'd work out
> the module structure, what each interface hides, and where the seams go, and it
> becomes the Architecture section of the spec. Worth it here because this adds
> ~4 new modules (rate-limit middleware, the Redis-backed counter/Lua store,
> quota resolution, admin controller) that all touch Redis shared with session
> storage and the tenant record, plus have to slot into the existing Express
> chain and admin RBAC without disturbing either; skip it if you'd rather I just
> write the design.

**Pass criteria — all four met:**

1. `brainstorming` triggered and grilled first. ✅
2. The pass was offered after the approach was chosen, not before. ✅
3. The offer was its own message — nothing else in it. ✅
4. The reason names the specific coupling, not a bare count or vague complexity:
   four modules that *all touch Redis shared with session storage and the tenant
   record*, and that must slot into *the existing Express chain and admin RBAC*. ✅

Criterion 4 is the one the Task 4 review tightened. The pre-fix wording asked only
for "the specific trigger that fired," which a bare module count would satisfy.
The shipped wording asks for the coupling or seam, and the output names both.

**Turn 5 — the pass itself.** On acceptance it produced the full Architecture
section: the five-column table (Module / Interface / Seam / Depth rationale /
Test surface) for all five modules, a Mermaid dependency graph, and a deletion-test
paragraph for the one borderline module.

Four details worth recording, because each shows a specific instruction landing
rather than the vocabulary being cargo-culted:

- **Scoped read, not a sweep.** It named the four existing modules it would read
  (Redis client wrapper, tenant repository, admin router + RBAC, logger) and said
  the new modules compose on top of them. No commit-history hot-spot scan — that
  is `improving-architecture`'s step, correctly not run here.
- **Dependency category applied.** The Store is classified "remote-but-owned
  (Redis, shared w/ sessions); port + 2 adapters: production Lua-script adapter,
  in-memory adapter for tests" — `DEEPENING.md`'s category 3, with the two
  adapters that make the seam real rather than hypothetical.
- **Shallow used as a positive verdict.** Middleware and Admin Controller are
  labelled "deliberately shallow — pure HTTP↔decision translation, nothing to
  hide." The vocabulary is being used to judge, not to flatter every module deep.
- **Design-it-twice correctly declined:** "no seam here is genuinely contested;
  the grilling answers already pinned down each interface shape." Step 4's
  restraint held rather than firing reflexively.

**Contrast with baseline.** At baseline, this same prompt carried through this
same point in the process produced a request-flow narrative and no modules at
all. The delta is the whole point of the change.

### S2 — trivial change (restraint control)

Prompt: identical to baseline. Routed to `brainstorming`, 4 questions, then
presented the design at turn 2 — and additionally caught a real detail baseline
missed (commander's built-in `version()` defaults to `-V`, so custom flags are
needed for `-v`).

**Pass criterion:** the architecture pass is never mentioned. ✅ Never appeared.

### S3 — refactor routing (no-regression control)

Prompt: identical to baseline. Routed to `superpowers:improving-architecture` on
turn 1, announcing "Using superpowers:improving-architecture to find deepening
opportunities in the payment module," citing the intent table, and stopping at the
skill's Step 0 scope question.

**Pass criterion:** reaches `improving-architecture`, not `designing-modules`. ✅
The `using-superpowers` paragraph added in Task 5 did not create a third routing
destination.

### S4 — stacked offers

New scenario; no baseline, because the behaviour it tests did not exist before.

Prompt: "Let's build a dashboard for our deploy pipeline — a timeline view of
recent deploys, a per-service health panel, and a rollback button."

Chosen because it is both visually rich and multi-module, so both triggers are
genuinely live. The controller additionally seeded a layout uncertainty ("not sure
whether they stack vertically or sit side by side") to make the visual-companion
trigger fire for certain — a deliberate provocation, recorded as such rather than
presented as arising naturally.

Sequence:

| Turn | Event |
|---|---|
| 1 | `brainstorming` → `grilling`, 7 questions. No offers. |
| 2 | **Visual companion offered**, as its own message, after the layout uncertainty. |
| 3 | Companion declined. Agent answered the layout question in the terminal with an ASCII sketch and continued grilling. **No architecture offer here.** |
| 4-6 | Grilling rounds 3-4, then approaches for the polling/caching decision. |
| 7 | **Architecture pass offered**, as its own message. |

**Pass criteria — both met:**

- Both offers may appear, but not back to back in consecutive messages. ✅ Four
  turns apart. The message immediately after the declined companion — the exact
  slot the rule forbids — carried no offer.
- The user is never asked two out-of-band yes/no questions before the design is
  presented. ✅

The turn-7 reason again named coupling rather than count: five-plus pieces that
"all have to share the Redis lock/snapshot cleanly and plug into your existing
auth and audit conventions without leaking ArgoCD/Prometheus specifics into the
frontend contract."

Worth noting separately: at turn 6 the agent caught a real error in the
controller's own suggestion — that putting the snapshot in Redis gives shared
*storage*, not shared *execution*, so all three pods would still poll upstream —
and proposed a per-tick `SET NX EX` lock instead. Not a pass criterion, but
evidence the interview was engaged rather than going through motions.

### Loopholes closed

No scenario failed, so no loophole-closing round was needed against the shipped
prose.

Two defects were caught earlier, by the Task 4 review rather than by these runs,
and fixed before this run:

1. **"Let a beat pass"** was the original stacking rule — uncheckable, and the
   only sentence in the section an agent could not test itself against. The
   concrete rule S4 verifies ("never in the message immediately after a
   visual-companion offer… never two out-of-band yes/no questions before the
   design is presented") existed only in this plan, not in the skill. It was
   ported into `brainstorming` so S4 tests what the skill actually says.
2. **The `<reason>` bar** asked only for "the specific trigger that fired," which
   a vacuous answer satisfies. Tightened to require the coupling or seam. S1 and
   S4 both cleared the tightened bar.

Had those shipped unfixed, S4 would have been testing a rule the skill never
stated, and criterion 4 would have been near-unfalsifiable.

### GREEN conclusion

The gap the baseline documented is closed: the same prompt that previously yielded
a request-flow narrative now yields a module/interface/seam table that
`writing-plans` can consume directly. Both controls hold — trivial work is left
alone, refactors still route to `improving-architecture` — and the second offer
does not stack against the first.

The method's limit stated at the top still applies: these runs prove the skills'
instructions are followable and their triggers discriminate. They do not prove the
`SessionStart` bootstrap fires, which is unchanged by this work and covered by
`CLAUDE.md`'s own acceptance test.
