# Engine skills are shared by front-ends, not routed to

`brainstorming` and `improving-architecture` are the only skills user intent
routes to. The phases they share — the interview, and module/seam design — live
in `grilling` and `designing-modules`, which are invoked by the front-ends and
return to them rather than terminating the flow. This is why the architecture
vocabulary (`LANGUAGE.md`, `DEEPENING.md`, `INTERFACE-DESIGN.md`) sits in
`designing-modules` and not in `improving-architecture`, where it originated
upstream.

## Considered Options

- **A greenfield branch inside `improving-architecture`.** Rejected: the skill's
  name and description would misdescribe it, and the engine would stay
  un-invocable for "design the architecture for this spec."
- **Inline the design procedure into `brainstorming`.** Rejected: cheapest edit,
  but duplicates the procedure the moment `improving-architecture` needs it too.

## Consequences

Adding a third front-end means deciding which engines it reuses, not copying
their contents. Diffing against `mattpocock/skills` requires comparing its
single `improve-codebase-architecture` skill against both fork skills — see
`docs/upstream-sync.md`.
