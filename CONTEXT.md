# Stateful Superpowers

A skills library for coding agents: a brainstorm → plan → TDD → review workflow
that remembers a project's language and decisions across sessions. This glossary
covers the library's own skill taxonomy — the vocabulary used when designing how
skills invoke each other.

## Language

**Front-end skill**:
A skill that user intent routes to directly, owning a phase of the workflow end
to end. `brainstorming` and `improving-architecture` are the two, split by
new-behavior vs preserve-behavior.
_Avoid_: entry point, router, top-level skill

**Engine skill**:
A skill invoked by front-ends rather than routed to, owning one reusable phase
of their work. `grilling` (the interview) and `designing-modules` (module and
seam design) are the two. An engine returns to its caller; the caller owns the
terminal state.
_Avoid_: sub-skill, helper skill, shared skill

**Architecture pass**:
The optional `designing-modules` step inside `brainstorming`, offered
just-in-time once an approach is chosen, producing the spec's Architecture
section.
_Avoid_: design phase, architecture review

**Capture moment**:
A point in a skill where a resolved term is written to `CONTEXT.md` or a
hard-to-reverse decision is offered as an ADR, inline as it happens rather than
batched at the end.
_Avoid_: documentation step, persistence hook
