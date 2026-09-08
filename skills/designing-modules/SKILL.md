---
name: designing-modules
description: Design the module structure, interfaces and seams for work about to be built. The shared design engine behind brainstorming's architecture pass and improving-architecture's deepening candidates — invoked by those front-ends after their interview, and usable standalone to design the architecture for an existing spec.
---

# Designing Modules

Turn a resolved design into a **module structure**: what the modules are, what
each interface hides, where the seams go, and how each is tested. The aim is
depth — a lot of behaviour behind a small interface — for testability and
AI-navigability.

This skill is an **engine**, not a front-end. It returns to its caller; the
caller owns what happens next. Invoked standalone, fall through to
`superpowers:writing-plans` once the structure is settled.

## Glossary

Use these terms exactly. Don't drift into "component," "service," "API," or
"boundary." Full definitions in [LANGUAGE.md](LANGUAGE.md).

- **Module** — anything with an interface and an implementation (function, class, package, slice).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature.
- **Depth** — leverage at the interface. **Deep** = a lot of behaviour behind a small interface. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can be altered without editing in place. (Use this, not "boundary.")
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth. **Locality** — what maintainers get from it.

Key principles (full list in [LANGUAGE.md](LANGUAGE.md)):

- **Deletion test**: imagine the module gone. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it earns its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

## Process

### 1. Resolve the module set

Take the design from your caller — `superpowers:brainstorming`'s chosen
approach, or `superpowers:improving-architecture`'s chosen candidate.

**Do not run an interview.** Both front-ends grill before they call you;
re-asking what the frontier already settled is exactly the friction
`superpowers:grilling` was extracted to kill. If you were invoked standalone
against an idea nobody has grilled, stop, invoke `superpowers:grilling`, and
come back with the resolved design.

### 2. Read the abutting code

Read `CONTEXT.md` and any ADRs covering the area first. Then read the modules
the work touches or sits next to — enough to place new seams against existing
ones and to name things the way the codebase already names them.

**Scoped, not a sweep.** Do not walk the commit history looking for hot spots.
That is `superpowers:improving-architecture`'s discovery step; running it here
blurs the two skills together and buys a survey nobody asked for. Greenfield
with nothing abutting: skip this step.

### 3. Propose the structure

Present the **Architecture section**:

| Module | Interface | Seam | Depth rationale | Test surface |
|---|---|---|---|---|
| name from `CONTEXT.md` vocabulary | what a caller must know — types, invariants, ordering, error modes | where the interface lives | why this shape is deep, or why shallow is right here | what tests exercise, through which interface |

Then, as needed:

- A **deletion test** paragraph for anything borderline — would deleting this module concentrate complexity, or just move it?
- A **Mermaid diagram** when the relationships are graph-shaped (call graph, dependency, sequence). Skip it when the table already says everything.
- For each dependency, its category from [DEEPENING.md](DEEPENING.md) — that decides whether the seam needs a port and adapters at all, and how the module gets tested across it.

**Use `CONTEXT.md` vocabulary for the domain, and [LANGUAGE.md](LANGUAGE.md)
vocabulary for the architecture.** If `CONTEXT.md` defines "Order," it is "the
Order intake module" — not "the FooBarHandler," and not "the Order service."

**YAGNI.** One adapter is a hypothetical seam. Don't put a port at a seam that
will have exactly one thing behind it forever.

### 4. Design it twice — one seam, on request

Your first idea is unlikely to be the best (Ousterhout). But running parallel
interface designs for every module costs more than the rest of the design
session put together.

Nominate the **one** module whose seam placement is genuinely contested — where
you can see two defensible answers — and offer it:

> "The <name> seam could go either way. Want me to design it twice — a few
> radically different interfaces explored in parallel, then compared?"

On yes, follow [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md). On no, or when no
seam is genuinely contested, skip this step. Don't manufacture a contest to
justify the offer. This offer sits inside an architecture pass the caller
already accepted, so it is not one of the out-of-band offers
`superpowers:brainstorming` limits — but it is still a question, so skip it
unless the seam is genuinely contested.

### 5. Hand back

Return the resolved structure to your caller. Do **not** invoke
`superpowers:writing-plans` yourself unless you were invoked standalone — the
front-ends have their own approval gates to run first.

## Capture as you go

These fire during steps 3 and 4. Handle them inline, as decisions crystallize —
don't batch them up for the end.

- **Naming a module after a concept not in `CONTEXT.md`?** Add the term, per [CONTEXT-FORMAT.md](../grilling/CONTEXT-FORMAT.md). Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term mid-conversation?** Update `CONTEXT.md` right there.
- **User rejects a structure with a load-bearing reason?** Offer an ADR, framed as: _"Want me to record this so a future architecture pass doesn't re-propose it?"_ Only when the reason is something a future explorer would actually need — skip ephemeral reasons ("not worth it right now") and self-evident ones. See [ADR-FORMAT.md](../grilling/ADR-FORMAT.md).
