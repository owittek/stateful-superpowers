# The tracker holds graph and state, never content

Multi-session work is scheduled on an issue tracker (GitHub Issues or local
markdown), but the spec, the plan, the glossary and the ADRs stay as committed
repo files. A ticket carries only what to build, acceptance criteria, blocking
edges, and a pointer to the spec path at a commit. State is the tracker's
native state (assignee, dependencies, linked PR, closed), not a label state
machine.

We chose this over Matt Pocock's spec-as-issue model because agents in a
checkout read files more reliably than tracker bodies (his docs record
truncation on large spec issues with no local copy to fall back on), committed
files are diffable and reviewed with the PR, and a thin ticket survives weeks on
the queue without going stale. Native state over labels because his most-filed
gap is missing states in the label machine and agents forgetting to move them.

## Consequences

- The tracker is the index and queue, not the archive; a ticket is unreadable
  without the repo.
- The frontier is one query (open, no open blockers, unassigned) and nothing
  has to be kept in sync by hand.
- A future `wayfinder` port uses the same parent/child/edge/claim/resolve
  operations with different kinds; it must not move decision content into the
  repo's specs, since decision tickets are the map's content by design.
