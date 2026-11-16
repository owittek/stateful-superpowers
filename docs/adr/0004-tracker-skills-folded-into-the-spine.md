# Pocock's tracker skills are folded into the spine, not ported

The tracker bridge first adapted Matt Pocock's standalone skills one-for-one: a
setup wizard (`setup-matt-pocock-skills`), a pickup runner (`implement`), and
later his triage. In his repo each skill stands alone, so each re-does setup,
planning and review. Inside superpowers those already exist: writing-plans owns
the plan and the human's review of it, SDD and executing-plans resume
themselves, finishing integrates. So the tracker port's `init` op replaces the
wizard, writing-plans accepts a ticket reference instead of a runner wrapping
it, and the finishing-time follow-up sort replaces triage for a solo
maintainer.

## Consequences

- No `setting-up-tracker` or `picking-up-ticket` skill, no
  `.superpowers/pickup/` workspace; the tracker script lives under
  `finishing-a-development-branch/scripts/`.
- The config file stays Pocock-compatible (`docs/agents/issue-tracker.md`), so
  his skills can still read it; interop costs nothing.
- Upstream-sync provenance records the divergence, not a port.
