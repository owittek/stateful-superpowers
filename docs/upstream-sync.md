# Upstream sync

Stateful Superpowers draws from two upstreams. [obra/superpowers](https://github.com/obra/superpowers) is tracked through git, so its sync point is the merge-base. [mattpocock/skills](https://github.com/mattpocock/skills) has an incompatible tree layout and no merge lineage — this file is its sync record, so the next drift check is a diff rather than an archaeology dig.

## obra/superpowers

- Remote: `source` (`git@github.com:obra/superpowers.git`)
- Sync point: the merge-base with `source/main` — last merged **v6.1.0** in `eec3658`
- Process: merge `source/main`, resolve, bump the plugin version.

## mattpocock/skills

- No remote — clone it alongside this repo to diff against.
- **Last reviewed: 2026-08-10, against `84fdeff` (2026-08-06).**
- Absorbed originally from `ffb2fa6` (2026-06-12) via PRs #1, #2, #4.
- Process: for each absorbed skill, `git log <last-reviewed-ref>..main -- skills/<dir>` in a mattpocock/skills clone, then port what fits this fork's guardrails. Update the "last reviewed" ref above afterwards.

### Provenance

| Fork skill | mattpocock origin |
|---|---|
| `grilling` | `productivity/grilling` + `engineering/grill-with-docs` + `engineering/domain-modeling` (merged into one skill here) |
| `improving-architecture` | `engineering/improve-codebase-architecture` + `engineering/codebase-design` |
| `commenting-modules` | `engineering/codebase-design` (deep-module vocabulary) |
| `syncing-context` | `engineering/domain-modeling` (glossary half) |
| `prototype` | `engineering/prototype` |
| `handoff` | `productivity/handoff` |
| `zoom-out` | `engineering/zoom-out` (since deleted upstream) |

### Ported in the 2026-08-10 review

- `grilling`: round-by-round **frontier** interview replacing one-at-a-time; pinned `❓ Q<n>` / `➡️` question format; "finding facts is your job, never the user's" (dispatch a subagent, don't block the rest of the frontier). Followed through into `brainstorming` and `improving-architecture`.
- `improving-architecture`: "Scope before you scan — YAGNI" (user's direction, else `git log` hot spots).
- Harness-neutral subagent dispatch (dropped hardcoded `Agent tool` / `subagent_type=Explore`) in `improving-architecture`, `commenting-modules`, `INTERFACE-DESIGN.md`.
- `prototype`: logic branch is now a single-file clickable HTML demo instead of a terminal TUI.
- Terminology: "design tree" → "decision tree" across skills.

### Deliberate divergences — do not "sync" these back

- **`prototype` stays out of the repo.** Upstream now captures prototypes as a *primary source* on a throwaway branch; this fork keeps the temp-dir / never-committed / discard-when-answered guardrails, because here the prototype is a brainstorming-subordinate probe and the real thing is built from scratch via writing-plans → TDD.
- **`zoom-out` is kept** even though upstream removed it.
- **PRD umbrellas are kept.** Upstream renamed its PRD flow to `to-spec`; this fork's `brainstorming` still writes a PRD umbrella for multi-feature initiatives.
- **`grilling` owns domain capture.** Upstream splits `grilling` / `domain-modeling` / `grill-me` / `grill-with-docs`; the fork folds them into one skill with the CONTEXT.md + ADR discipline inline.
- **Longer skill descriptions.** Upstream trimmed its descriptions; the fork's carry routing detail (which skill invokes which) on purpose.

### Upstream skills not adopted (as of `84fdeff`)

`wayfinder` (decision-ticket map on an issue tracker, for work too big for one session), `wizard`, `research`, `to-spec` / `to-tickets`, `code-review`, `triage`, `implement`, `resolving-merge-conflicts`, `wait-what`, `to-questionnaire`, `writing-for-agents`, `ask-matt` (router). Most overlap with the Superpowers spine this fork already has; `wayfinder` is the notable gap if long-horizon planning is ever wanted.
