# Brainstorming tracks upstream's interview; grilling joins it in capture mode

From obra/superpowers v7 on, `brainstorming` is upstream's file with the fork's
differentiators inserted at a few fixed points: domain capture (`CONTEXT.md`
and `docs/adr/`), the architecture pass, the PRD umbrella, and a gate that
always needs approval. Upstream's interview (why first, one question at a
time, options only once there's a real choice) replaces `grilling`'s frontier
rounds inside brainstorming. Brainstorming invokes `grilling` in **capture
mode**: it keeps the conversation to the glossary and the recorded decisions
and writes terms and ADRs inline, but runs no rounds of its own. Frontier
rounds remain for `improving-architecture` and for standalone grilling.

## Considered Options

- **Keep frontier rounds in brainstorming.** Rejected: upstream rewrites
  brainstorming nearly every release (four times between v6.2.0 and v7.0.2),
  and an interview style that runs through the whole conversation conflicts
  with every rewrite. The fork's differentiators are the state model and the
  architecture pass, not the question style.
- **Take upstream wholesale, without the gate.** Rejected: the user wants
  approval before anything is built, including upstream's "quick, clear task"
  and the opt-out from the questions.

## Consequences

Upstream syncs of `brainstorming` mostly apply directly; only the insertion
points need checking (see `docs/upstream-sync.md`). `grilling` now has two
callers using it differently: `improving-architecture` uses its interview,
`brainstorming` uses its capture rules only. ADR 0001 still holds; what
changed is how much of the interview engine brainstorming reuses.
