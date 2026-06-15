---
name: prototype
description: A brainstorming-SUBORDINATE throwaway probe. Build a throwaway prototype to answer one specific design question that discussion can't settle. Routes between two branches — a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route. Use when the user wants to prototype, sanity-check a data model or state machine, mock up a UI, explore design options, or says "prototype this", "let me play with it", "try a few designs".
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

This skill is **subordinate to `superpowers:brainstorming`**. It is a narrow design-probe, not an implementation escape hatch — it does NOT bypass the brainstorming HARD-GATE forbidding implementation before design approval. It exists only to answer a named design question that discussion, scenarios, and code-reading cannot settle, and the answer feeds back into the design.

## Guardrails (non-negotiable)

1. **Question-gated.** Only prototype when a specific named design question resists discussion, scenarios, and code-reading. State the question before writing a line. If grilling can answer it, do not prototype.
2. **Throwaway / out-of-repo.** All prototype code lives in the OS temp dir, is NEVER committed, NEVER added to the repo, and is discarded once the question is answered.
3. **Scoped, then stop.** Halt the moment the question is answered. No feature creep into a partial build.
4. **Re-enter the gate.** Feed the finding back into the design/spec (and CONTEXT.md/ADR if it crystallized a term/decision). The real thing is later built from scratch via writing-plans→TDD — the prototype is never the seed of production code.
5. **Subagent-driven.** Run the prototype build in a dispatched subagent. Only the answer to the design question returns to the main session; the scratch code and verbose iteration stay in the subagent.

## Pick a branch

Identify which question is being answered — from the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [LOGIC.md](./LOGIC.md). Build a tiny interactive terminal app that pushes the state machine through cases that are hard to reason about on paper.
- **"What should this look like?"** → [UI.md](./UI.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

The two branches produce very different artifacts — getting this wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to both

1. **Throwaway from day one, and clearly marked as such.** The prototype lives in the OS temp dir, never in the repo (see Guardrails). Name it so a casual reader can see it's a prototype, not production. For throwaway UI routes, mirror whatever routing convention the project uses so the scratch app stays runnable; don't invent a new top-level structure.
2. **One command to run.** Whatever the project's existing task runner supports — `pnpm <name>`, `python <path>`, `bun <path>`, etc. The user must be able to start it without thinking.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE — wipe me" name.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast and then delete it.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.
6. **Discard when done.** When the prototype has answered its question, delete it — fold the validated _decision_ (not the code) back into the design/spec. Never leave it rotting, and never let it become the seed of production code.

## When done

The _answer_ is the only thing worth keeping from a prototype. Capture it somewhere durable (the design/spec, CONTEXT.md, or an ADR) along with the question it was answering, then discard the scratch code. If the user is around, that capture is a quick conversation; if not, surface the verdict so they (or you, on the next pass) can fold it into the design before the prototype is discarded. The real thing is built later, from scratch, via writing-plans→TDD.
