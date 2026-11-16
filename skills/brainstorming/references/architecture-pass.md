# Architecture Pass

`superpowers:designing-modules` works out module structure, interfaces and
seams. Like the visual companion, it is a tool, not a mode — offering it does
not commit the rest of the design to architecture-speak.

**When to offer.** After the approach is chosen (checklist item 4), when either
is true:

- the design introduces **2+ new modules**, or
- it lands in an **existing codebase with seams it has to fit**.

If neither holds, never mention it. A single-function utility does not need a
seam analysis.

**The offer is its own message.** Only the offer — no clarifying question, no
summary alongside it:

> "Before I write this up — want me to do an architecture pass first? I'd work
> out the module structure, what each interface hides, and where the seams go,
> and it becomes the Architecture section of the spec. Worth it here because
> \<reason\>; skip it if you'd rather I just write the design."

**Fill in `\<reason\>` with the specific coupling or seam that fired the trigger** — "this adds four new modules that all touch the session store," not "it seems complex," and not a bare module count. Naming what actually couples is what stops the offer degrading into a reflex on every brainstorm. If you cannot name one, the trigger did not fire: don't offer.

If they decline, continue and don't offer again unless they raise it.

**Don't stack offers.** Never offer this in the message immediately after a visual-companion offer — wait until the user has replied to something else first. And never put two out-of-band yes/no questions to the user before the design is presented. Two offers back to back read as nagging, and the second gets a reflex "no" that has nothing to do with its merits.

**Why after the approach, not before.** Approaches are usually product-level —
"SSE vs polling." Designing modules for three still-live approaches costs three
times as much and discards two thirds of it.

**What comes back.** A module/interface/seam table for the chosen approach. It
becomes the Architecture section of the design you play back and of the spec
you write. If the visual companion is already running, its structure diagram
belongs in the browser tab; otherwise Mermaid in the spec.
