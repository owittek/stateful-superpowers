# Stateful Superpowers

A skills library for coding agents: a brainstorm → plan → TDD → review workflow
that remembers a project's language and decisions across sessions. This glossary
covers the library's own skill taxonomy and the vocabulary of work scheduled on
an issue tracker.

## Skill taxonomy

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

**Runner skill**:
A skill that walks a fixed sequence of steps, each leaving an artifact a command
can check, and makes no decisions of its own. `executing-plans`,
`subagent-driven-development` and `picking-up-ticket` are runners. A runner
never interviews.
_Avoid_: orchestrator, pipeline, workflow skill

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

## Work on the tracker

**Issue tracker**:
The tool that hosts a repo's issues: GitHub Issues or the local markdown files
under `docs/superpowers/tickets/`. Named by `docs/agents/issue-tracker.md`.
_Avoid_: backlog, board, backend

**Issue**:
Any item on the issue tracker: a spec issue, a ticket, an inbox idea or bug.
_Avoid_: card

**Spec issue**:
The issue that represents one committed spec on the tracker: a pointer to the
spec path at a commit, and the parent of that spec's tickets.
_Avoid_: epic, parent issue, umbrella issue

**Ticket**:
An issue that is one tracer-bullet slice of a spec: behavioral, self-contained,
sized to one fresh context window, with blocking edges and tracker state. Holds
no file paths or code.
_Avoid_: story, sub-task, work item

**Task**:
One unit inside a plan: a test cycle worth a reviewer's gate, with exact files
and code. Several tasks implement one ticket.
_Avoid_: step, ticket

**Frontier**:
The open tickets whose blockers are all closed and that nobody has claimed; what
can be picked up now.
_Avoid_: ready queue, backlog, todo

**Claim**:
Taking a ticket by becoming its assignee (or setting `Status: claimed` locally),
before any work on it.
_Avoid_: lock, checkout, assign

**Tracker port**:
The seven operations (register-parent, publish-ticket, frontier, fetch, claim,
resolve, comment) behind which the issue tracker's backend is hidden; executed
by `scripts/tracker`, configured by `docs/agents/issue-tracker.md`.
_Avoid_: tracker API, integration, client
