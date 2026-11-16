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
of their work. `grilling` (the interview and domain capture) and `designing-modules` (module and
seam design) are the two. An engine returns to its caller; the caller owns the
terminal state.
_Avoid_: sub-skill, helper skill, shared skill

**Runner skill**:
A skill that walks a fixed sequence of steps, each leaving an artifact a command
can check, and makes no decisions of its own. `executing-plans`,
and `subagent-driven-development` are runners. A runner
never interviews.
_Avoid_: orchestrator, pipeline, workflow skill

**Capture mode**:
How `brainstorming` uses `grilling`: domain-language challenges and inline
`CONTEXT.md`/ADR capture during brainstorming's own conversation, with no
interview rounds. See ADR 0003.
_Avoid_: lite grilling, passive grilling

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
Any item on the issue tracker: a spec issue, a ticket, or the Follow-ups
parent.
_Avoid_: card

**Spec issue**:
The issue that represents one committed spec on the tracker: a pointer to the
spec path at a commit, and the parent of that spec's tickets.
_Avoid_: epic, parent issue, umbrella issue

**Follow-ups parent**:
The one standing parent issue (kind `followups`) under which every deferred
follow-up's ticket hangs; created on first use, never closed, pointing at no
spec.
_Avoid_: inbox, backlog issue, follow-up epic

**Ticket**:
An issue that is one schedulable unit of work: a tracer-bullet slice of a spec,
or a deferred follow-up. Behavioral, self-contained, sized to one fresh context
window, with blocking edges and tracker state. Holds no file paths or code.
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

**Follow-up**:
Something found during a piece of work that is out of the current step but not
worth losing: drift, a small bug nearby, a missed backport, a deferred review
minor. Most are done before the branch finishes; only deferred ones become
tickets.
_Avoid_: todo, parked item, backlog item

**Follow-up list**:
The repo's open follow-ups, tagged by branch, kept in a git-ignored file in the
main checkout so they survive compaction, subagent hand-backs and worktree
removal until the follow-up sort.
_Avoid_: scratchpad, notes, inbox

**Follow-up sort**:
The step at the start of finishing where each open follow-up is done now,
deferred to a ticket, or dropped, with the human.
_Avoid_: triage, cleanup pass

**Pattern sweep**:
The review pass at the start of finishing that lists the recurring patterns a
branch's diff introduces or touches, checks each against existing helpers and
sibling instances, and adds the inconsistent ones to the follow-up list with a
canonical choice. Doing one now means shared primitive + enforcement +
migration, not a one-site fix.
_Avoid_: style review, consistency lint, audit

**Tracker port**:
The operations (register-parent, publish-ticket, frontier, fetch, claim,
resolve, comment, find, init) behind which the issue tracker's backend is hidden; executed
by `scripts/tracker`, configured by `docs/agents/issue-tracker.md`.
_Avoid_: tracker API, integration, client
