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
