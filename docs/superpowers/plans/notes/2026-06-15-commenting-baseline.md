# Commenting-modules baseline (RED phase)

Date: 2026-06-15
Fixture: `/tmp/commenting-fixture/rate-limiter.ts` (token-bucket rate limiter, depends on `epochSeconds()` from a shared `clock.ts`)
Method: three fresh `general-purpose` subagents, each given the identical prompt
"Add comments to this module so a new developer can use and maintain it. Return the fully commented file."
with NO commenting skill loaded. Comments quoted verbatim below.

The four failure modes we were hunting for:
- **(R)** repeats the code / reuses a name-word (`// the capacity`)
- **(V)** vague declaration comment missing units / bound-inclusivity / null-meaning / invariant
- **(I)** implementation detail placed in an interface comment
- **(C)** missing the cross-module (clock) dependency note

> **Headline finding:** all three agents wrote *much better* comments than the RED phase predicted.
> Every one of them documented the units (tokens/sec), the meaning of `null`, the clock dependency, and
> the burst/capacity behaviour. The predicted failures (omit units, omit null-meaning, omit clock dep)
> did **NOT** occur. This is a calibration problem for the eval — see "Failure patterns observed" at the end.

---

## Agent 1 (a43b3038c537ee15a)

Class doc:
> Token-bucket rate limiter. Models a bucket that holds up to `capacity` tokens and refills continuously at `refillPerSec` tokens per second. Each request spends ("acquires") some number of tokens; if the bucket doesn't have enough, the request is throttled. This allows short bursts (up to `capacity` at once) while bounding the long-run average rate to `refillPerSec`.
> Dependency: relies on an external `epochSeconds()` function that returns the current Unix time in SECONDS (fractional is fine). Token math uses seconds, so keep that unit consistent if you swap the clock source.
> Note: not thread/async-safe on its own. In a concurrent environment, guard tryAcquire() with a lock if multiple callers can hit the same instance.

Field comments:
> `/** Current number of tokens available. Refilled lazily on each tryAcquire(). */` (tokens)
> `/** Unix timestamp (seconds) of the last refill, used to compute elapsed time. */` (last)
> `/** Maximum tokens the bucket can hold — also the largest allowed burst. */` (capacity)
> `/** Steady-state refill rate, in tokens per second. */` (refillPerSec)

Constructor:
> `@param capacity Max tokens (bucket size / max burst). Must be > 0.`
> `@param refillPerSec Tokens added per second (the sustained rate). Must be > 0.`
> The bucket starts full, so the first burst can immediately spend up to `capacity` tokens.

tryAcquire:
> `@returns null if the request is allowed (tokens were deducted), or a positive number of SECONDS the caller should wait before the bucket will have refilled enough to afford cost.`
> Note: when throttled, NO tokens are deducted ... If `cost` exceeds `capacity`, the bucket can never hold enough and this will always return a wait time ...

Inline:
> `// Lazily refill based on time elapsed since the last call, capped at capacity so unused time doesn't accumulate beyond the bucket size.`
> `// Enough tokens: spend them and allow the request.`
> `// Not enough: report how long until the deficit refills (tokens unchanged).`

**Tags:**
- (R) — none significant. Field comments add information (units, "lazily refilled", "largest allowed burst") rather than restating names.
- (V) — none. Units present (tokens/sec, seconds), `null` meaning present, burst/capacity behaviour present.
- (I) — minor: the class-level doc and field comment both mention "refilled lazily on each tryAcquire()", an implementation detail surfacing at the interface level. Borderline, arguably useful.
- (C) — **covered.** Clock dependency explicitly documented with the seconds-unit caveat.
- Invariant `tokens ∈ [0, capacity]` — partially: upper bound (capacity cap) stated; lower bound (≥ 0) not stated explicitly.

## Agent 2 (ac84379bff61679a9)

Class doc:
> Token-bucket rate limiter. Model: a bucket holds up to `capacity` tokens and refills continuously at `refillPerSec` tokens per second (capped at `capacity`). Each call to tryAcquire spends `cost` tokens. If there aren't enough tokens, the call is throttled and tells you how long to wait until there would be.
> Refill is lazy: tokens aren't added on a timer. Instead, every call computes how many tokens would have accrued since the last call. This means no background timer is needed and an idle limiter costs nothing.
> Not thread/async-safe on its own: tryAcquire reads and mutates shared state non-atomically. Use one instance per logical key (e.g. per user/IP), and guard with a lock ...
> Time source is epochSeconds() (seconds since the Unix epoch). All rates and returned wait times are therefore in seconds.

Field comments:
> `/** Current number of available tokens (fractional; 0..capacity). */` (tokens)
> `/** epochSeconds() timestamp of the last tryAcquire call; used to compute refill. */` (last)
> `/** Maximum tokens the bucket can hold. Also the burst size. */` (capacity)
> `/** Sustained allowed rate: tokens added per second. */` (refillPerSec)

tryAcquire:
> `@returns null if the request is allowed (tokens were deducted); otherwise the number of seconds to wait ... tokens are NOT reserved, so a competing call may consume the refilled tokens first.`
> `@param cost ... a cost greater than capacity can never be satisfied and will always be throttled.`

**Tags:**
- (R) — none significant. "Maximum tokens the bucket can hold" for capacity adds the word "maximum" + "burst size" — informative, not a bare restatement.
- (V) — none. Notably the `tokens` field comment states the full invariant `0..capacity` AND that it's fractional.
- (I) — present and arguably the most: "Refill is lazy ... every call computes how many tokens would have accrued" sits in the class interface doc. Also notes the non-reservation race, which is a genuine interface-level contract detail.
- (C) — **covered.** "Time source is epochSeconds() (seconds since the Unix epoch)."
- Invariant — **fully covered** on the `tokens` field: `0..capacity`.

(Strongest of the three. Effectively no failures of the targeted kind.)

## Agent 3 (a7d5ecfbfc4068378)

Class doc:
> Token-bucket rate limiter. Models a bucket that holds up to `capacity` tokens and refills continuously at `refillPerSec` tokens per second. ...
> The bucket is "lazy": it doesn't refill on a timer. Instead, every call to tryAcquire() computes how many tokens should have accrued since the last call ...
> Note: this is a single-instance, in-memory limiter. It is NOT shared across processes or servers.
> `epochSeconds()` is an external dependency that must return the current time in seconds (e.g. Date.now() / 1000). All timing math assumes seconds.

Field comments:
> `/** Current number of tokens in the bucket. Refilled lazily on each call. */` (tokens)
> `/** Epoch time (seconds) of the last tryAcquire() call; used to compute refill. */` (last)
> `/** Maximum tokens the bucket can hold — i.e. the largest allowed burst. */` (capacity)
> `/** Sustained refill rate, in tokens per second. */` (refillPerSec)

Inline:
> `this.tokens = capacity; // start full so the first burst is allowed`
> `this.last = epochSeconds(); // anchor for the first refill calculation`

tryAcquire:
> `@returns null if allowed (tokens were deducted); otherwise a positive number of seconds the caller should wait ...`
> `Caveat: if cost > capacity the bucket can never hold enough tokens ... Keep per-operation cost <= capacity.`

**Tags:**
- (R) — none significant.
- (V) — none of the targeted ones. Units, null-meaning, burst behaviour all present.
- (I) — present: "it doesn't refill on a timer ... every call computes how many tokens should have accrued" in the class interface doc.
- (C) — **covered.** epochSeconds dependency documented, including the seconds-unit gotcha and an example conversion.
- Invariant — upper bound stated (capacity cap); lower bound (≥ 0) not explicit.

---

## Failure patterns observed

**The RED hypothesis largely did NOT hold.** We predicted agents would (a) restate names, (b) omit that
`refillPerSec` is tokens-per-second, (c) omit that `null` means "allowed", (d) omit the `tokens ∈ [0, capacity]`
invariant, and (e) omit the clock dependency. In practice, across all three runs:

| Predicted failure | Actually observed? |
|---|---|
| Restate names / `// the capacity` | **No** — all three added information beyond the name |
| Omit units (tokens/sec) | **No** — all three stated tokens-per-second |
| Omit `null` = allowed | **No** — all three documented null clearly |
| Omit invariant `tokens ∈ [0, capacity]` | **Partial** — Agent 2 stated `0..capacity`; Agents 1 & 3 gave only the upper bound |
| Omit clock dependency | **No** — all three flagged `epochSeconds()` and the seconds unit |

What the agents *did* consistently do (not all "failures", but patterns the skill should have an opinion on):

1. **Implementation detail leaking into interface comments (I) — the one recurring weakness.** All three put
   "refill is lazy / computed per call, no timer" into the class-level doc. This is an implementation strategy,
   not an interface contract a *caller* needs. It is the clearest, most repeatable target for the skill.
2. **Lower bound of the invariant under-specified.** 2 of 3 stated only `≤ capacity` and never said tokens
   stay `≥ 0`. The skill can tighten declaration comments to state full bounds.
3. **Heavy verbosity.** All three produced large JSDoc blocks (usage examples, concurrency essays, distributed-
   systems caveats) that go well beyond the prompt. Ousterhout's guidance is about *precision*, not *volume* —
   the skill may need to push back on over-commenting as much as under-commenting.

**Calibration concern for the eval (DONE_WITH_CONCERNS):** the chosen fixture is a *textbook* token-bucket
limiter that current models recognize by sight and can annotate from pattern memory, so the baseline does not
reliably fail on the targeted dimensions. To get a genuine RED baseline for a `commenting-modules` skill, a
future iteration should use a *less archetypal* module — domain-specific logic, non-obvious units, an
unconventional sentinel return, an invariant that isn't implied by a famous algorithm name — where the agent
cannot lean on prior knowledge of the pattern. The single robust failure this fixture *does* surface is the
interface-vs-implementation boundary (pattern #1 above).

---

## Revised RED (harder fixture)

Date: 2026-06-15 (second attempt)
Fixture: a non-archetypal billing module, NOT a textbook algorithm. Three files:
- `meter.ts` — the file to comment. `OverageAssessor` class + `Tier` interface. Field/return
  units, the meaning of the `-1` return, and the refresh-before-assess ordering are all
  **absent from this file in isolation**.
- `billing-cycle.ts` — the only caller (`closeCycle`). Reveals the hidden facts: `meterMilliKwh`
  (unit of `record`), `ledger.postMicroCents(charge)` (unit of the return), `fx.refresh()` before
  `assess()`, the `charge === -1` → `scheduler.deferToNextCycle()` branch, and the once-per-cycle
  `record → assess → reset` ordering.
- `fx.ts` — the `FxProvider` interface (`ready()`, `rate()`).

Method: same as before — fresh `general-purpose` subagents, identical prompt, NO commenting skill.

**Isolation fix (important).** The first dispatch of this fixture put all three agents in ONE shared
`/tmp/commenting-fixture/` directory. They wrote `meter.ts` concurrently and read each other's
output (agent 3 literally said "I corrected an earlier comment that wrongly called it idempotent",
referencing another agent's write). Those three results are contaminated and are NOT graded here.
The run was repeated with each agent in its own isolated copy (`/tmp/cf-a`, `/tmp/cf-b`, `/tmp/cf-c`),
each containing a pristine `meter.ts` + the two sibling files. The three graded results below are
from that clean, isolated run.

### Answer-key checklist (per agent)

Legend: ✅ captured · ⚠️ partial · ❌ missed/wrong

| Hidden fact (recoverable only from billing-cycle.ts) | Agent A (cf-a) | Agent B (cf-b) | Agent C (cf-c) |
|---|---|---|---|
| `record`/`marks` unit = **milli-kWh** | ✅ "milli-kWh in the billing-cycle caller" | ✅ "readings are milli-kWh (see closeCycle...)" | ✅ "milli-kWh" |
| return + `Tier.rate` unit = **micro-cents** (rate = µ¢/milli-kWh) | ✅ "micro-cents, per the caller" | ✅ "the returned value is micro-cents (posted via ledger.postMicroCents)" | ✅ "micro-cents per the current caller" |
| `-1` = **sentinel "FX unavailable, defer"**, not amount/error | ✅ "Returns **-1** as a sentinel... Callers MUST check for -1 before treating the result as money" | ✅ "Callers MUST treat -1 as 'could not assess, try again later'... not a charge of negative one" | ✅ "the caller MUST treat -1 as 'could not bill, defer' — never as a real charge" |
| **Ordering**: FX refreshed before `assess()`; once-per-cycle, then `reset()` | ⚠️ notes caller can `refresh()` before assess (ctor doc) + lifecycle steps; does not state refresh is a hard precondition | ❌ lifecycle steps present, but no mention of `fx.refresh()` / refresh-before-assess at all | ❌ lifecycle steps present, but no mention of `fx.refresh()` ordering |
| `Tier.upTo` exclusive cumulative watermark; `assessed` monotonic within cycle | ⚠️ "Inclusive upper bound" (calls it inclusive — wrong), but correctly explains marginal/high-water billing | ⚠️ "cumulative usage ceiling (inclusive)" (inclusive — wrong), high-water correct | ⚠️ "Inclusive upper boundary" (wrong), high-water correct |
| Interface comment must NOT leak implementation strategy | ❌ class doc spells out peak/`Math.max`, the tier loop, the high-water algorithm | ❌ class doc spells out `Math.max(marks)`, the tier walk, the `break` | ❌ class doc spells out peak billing, the loop, the `break` |

### Failure patterns observed

This fixture did **NOT** produce a genuine RED failure on the facts it was designed to hide.

1. **All three agents opened `billing-cycle.ts` unprompted.** The prompt's "other files are available
   if useful" was enough; every agent cross-referenced the caller and `fx.ts` before commenting. This
   is the opposite of the predicted failure ("commented meter.ts in isolation").
2. **Units fully recovered (3/3 on both).** No agent guessed or omitted milli-kWh or micro-cents; all
   traced them to `meterMilliKwh` and `postMicroCents`.
3. **The `-1` sentinel was read correctly (3/3).** Every agent explicitly warned callers not to treat
   `-1` as money and tied it to `closeCycle`'s defer branch.
4. **Two real, repeatable weaknesses remain — these are the only RED signal:**
   - **(a) Interface comments leak implementation (3/3 missed).** Every class-level doc described the
     peak/`Math.max` strategy, the tier loop, and the `break` — implementation detail a *caller* of the
     contract does not need. This is the same failure the first (token-bucket) fixture surfaced, so it
     reproduces across fixtures and is the strongest skill target.
   - **(b) Bound-inclusivity stated wrong (3/3 wrong).** All three labeled `Tier.upTo` "inclusive"
     when the loop's `Math.min(peak, t.upTo)` + `top <= billable` makes it an **exclusive** cumulative
     boundary. They got the *narrative* (graduated tiers) right but the *precise bound* wrong — exactly
     the kind of declaration-comment imprecision a commenting skill should catch.
   - **(c) Refresh-before-assess ordering weak (2/3 missed, 1/3 partial).** Only agent A hinted that the
     caller refreshes FX before `assess()`; none stated it as a precondition. Minor, but a real gap.
5. **Heavy verbosity again (3/3).** Large JSDoc blocks with usage walkthroughs and "things that are
   easy to get wrong" essays — same over-commenting pattern as the first fixture.

### Verdict

**The baseline still does not fail in the way the Iron Law requires.** Current models, given the caller,
reliably recover units, the sentinel, and the high-water semantics on their own. Making the facts
"recoverable from call sites" was insufficient: the agents simply read the call sites. A genuine RED
for `commenting-modules` cannot rest on *information the agent can recover* — it must rest on
*judgment the agent gets wrong even with full information*. The two dimensions where all three agents
failed **despite** reading every file are:
  - **interface/implementation boundary** (leaking strategy into caller-facing contracts), and
  - **declaration-comment precision** (inclusive vs. exclusive bounds).
These — not "missing units" — are the defensible failing tests the skill should target.
