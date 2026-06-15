# Comment Review

Run by a FRESH subagent with no memory of writing the comments (same reason code review uses fresh eyes). Verdict per comment: **keep / fix / delete**; apply fixes and re-check. Criteria are Ousterhout's (APOSD ch. 13).

## The two highest-yield checks (where agents actually fail)

Run these first — baseline testing showed capable agents pass most other checks but fail these even with full information:

1. **No implementation in interface comments.** Does any class/method comment describe *how it works* (data structures, loops, lazy/eager strategy, internal call sequence) rather than the caller-facing contract? → fix (move inside) or, if the contract can't be stated without the implementation, raise the **shallowness flag**.
2. **Cross-module ordering not omitted, and precision verified not assumed.** Check the call sites:
   - a required call sequence that spans modules ("refresh X before calling Y", "call once per cycle then reset") is stated, not silently dropped → if missing, add it or route to the cross-module pass,
   - inclusive vs exclusive matches the comparison operator,
   - the documented meaning of a `null`/`-1`/empty return matches how callers branch on it,
   - invariants actually hold.
   A confident *wrong* precision comment is worse than none → fix or delete.

## Per comment
- **Not obvious from adjacent code** — reader test: could someone write this comment just by reading the code next to it? Yes → delete. Judge "obvious" from a first-time reader, not the author.
- **Doesn't repeat the code, doesn't reuse the entity's name-words** (Red Flag: Comment Repeats Code).
- **Right level** — adds *precision* (lower) or *intuition* (higher). A same-level mirror of the code is the failure.

## Per declaration (field / arg / return)
- Carries precision where it applies: **units, inclusive/exclusive bounds, sentinel/null meaning, resource ownership/lifetime, invariants** — and each is *verified* (see check 2).
- **Nouns not verbs** — what it represents, not how it is manipulated.

## Per interface comment
- Usable without reading the body: behavior as callers see it, each **arg + return, side effects, exceptions, preconditions/ordering**.
- **No implementation detail** (see check 1).

## Per module (coverage)
- Every class, method, and class variable has an interface comment — except the genuinely obvious (a plain getter/setter).
