# Comment Types

Reuses the architecture glossary (`../improving-architecture/LANGUAGE.md`): **Interface** = everything a caller must know; **Implementation** = what's inside. Ousterhout's interface-vs-implementation comment split maps directly onto those.

**Guiding principle:** comments describe what is *not obvious from the code next to them*. "Obvious" is judged from a first-time reader, not the author.

## The four categories

### 1. Interface comment (most important)
Precedes a module/class or method. Defines the abstraction a caller perceives — NOT how it works inside.
- Class: the overall abstraction, what an instance represents, key limitations.
- Method: behavior as callers see it, each argument + return value, side effects, exceptions, preconditions/ordering.
- The caller must be able to use it **without reading the body**, and **without learning anything about the body**.

### 2. Field / variable comment (most important)
Next to instance/static vars and non-obvious locals. Carries *precision*:
- units, inclusive/exclusive bounds, what `null`/sentinel values mean, who owns/frees a resource, invariants.
- **Think nouns, not verbs** — what the variable *represents*, not how it is manipulated.

### 3. Implementation comment (often unnecessary)
Inside a method. *What & why, not how.* Block headers ("Phase 1: …"), loop-intent headers, "how we get here". Only where non-obvious.

### 4. Cross-module comment (rare)
A decision spanning module seams. Place it at the **natural focal point** every dependent path routes through; thin pointer comments elsewhere. No central notes file (it goes stale).

## Two directions

- **Lower-level → precision.** Clarifies exact meaning. Best for declarations.
- **Higher-level → intuition.** Omits detail, gives intent. Best for interface comments and block headers.
- A comment at the *same* level as the code just repeats it.

## The two things agents reliably get wrong

Fact-recovery (units, what a sentinel means, reading call sites) is something capable agents already do well. These two are where they fail even with full information — treat them as the point of this skill:

### A. Implementation leaks into the interface comment
The dominant failure. The caller-facing comment describes the *strategy* (how the value is computed, the data structure, the loop, the lazy/eager choice) instead of the *contract*.

**Leak (fix):** `// Recomputes the running peak with Math.max over recorded marks, then walks tiers…` on a public method.
**Contract (keep):** `// Returns the amount owed for usage above the committed tier, in micro-cents.`

If you *can't* state the contract without describing the implementation, the module is shallow — raise the **shallowness flag**; don't paper over it.

### B. Precision asserted but not verified
Agents state a boundary as "inclusive", a sentinel as an "error", or omit an ordering precondition — confidently, and wrong. A confident wrong precision comment is worse than none.

Before you write any of these, **verify it against the code and the call sites**:
- inclusive vs exclusive bounds (read the comparison: `<` vs `<=`),
- what a `null`/`-1`/empty return actually *means* (trace how callers branch on it),
- ordering/preconditions ("X must be called before Y" — read the caller's sequence),
- invariants (what is always true of a field across its lifetime).

If the code doesn't let you verify it, say so plainly rather than guessing.

## Worked examples

**Repeats the code (delete):** `// the capacity` above `private readonly capacity: number;`

**Precision (keep):** `// Max tokens the bucket holds; tryAcquire never lets tokens exceed this. Invariant: tokens ∈ [0, capacity].`

**Vague → precise (field):** `// current offset` → `// Position in this buffer of the first byte not yet returned to the caller.`

**Intuition (block header):** `// Refill the bucket for elapsed time, then spend `cost` if affordable.`
