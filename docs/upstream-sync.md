# Upstream sync

Stateful Superpowers draws from two upstreams. [obra/superpowers](https://github.com/obra/superpowers) is tracked through git, so its sync point is the merge-base. [mattpocock/skills](https://github.com/mattpocock/skills) has an incompatible tree layout and no merge lineage — this file is its sync record, so the next drift check is a diff rather than an archaeology dig.

## obra/superpowers

- Remote: `source` (`git@github.com:obra/superpowers.git`)
- Sync point: the merge-base with `source/main` — last merged **v7.0.2** on 2026-11-16 (fork 0.9.0)
- Process: **merge** `source/main`, resolve, bump the plugin version with `scripts/bump-version.sh`. Never rebase — the merge-base is what makes the next sync diffable, and `d856566` exists purely to repair it after a squash-merge lost the lineage.

### Recurring conflicts — decide these deliberately

- **Plugin manifests** (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.kimi-plugin/`, `.antigravity-plugin/`, `.devin-plugin/`, `.hermes-plugin/`, `.muse-plugin/`, `package.json`, `gemini-extension.json`): keep the fork's name/description/author, take upstream's structural changes, then bump to the fork's own version line (0.x, not upstream's 7.x). New harness manifests arrive with upstream's identity and must be rebranded; `.muse-plugin/plugin.json` lists skills explicitly, so add the fork-only skills. The Antigravity and Devin manifest tests pin the name — keep them on `stateful-superpowers`.
- **README install sections**: every install target points at `owittek/stateful-superpowers`. Harnesses that can only resolve upstream (GitHub Copilot CLI, OpenCode's npm install) are called out or dropped rather than silently shipping upstream to fork users.
- **`brainstorming`**: since v7 this is **upstream's file plus insertion points** (ADR 0003). On sync, take upstream's version and re-apply only these: (1) the "Domain language and decisions" paragraph in *Look Before You Ask* (`grilling` capture mode); (2) "or an ADR rules out" and the *Architecture pass* paragraph in *The Conversation* (details in `references/architecture-pass.md`); (3) spikes go through `superpowers:prototype`; (4) the PRD umbrella sentence in *Size the Work*; (5) the domain-terms and Architecture lines in *The Written Design*; (6) the gate: the quick-task and opt-out paths still need approval of a short design, the gate's only exception is a prototype, and there's one extra red-flag row; (7) the CONTEXT.md/ADR/Architecture paragraph in `builder-check-prompt.md`.

## mattpocock/skills

- No remote — clone it alongside this repo to diff against.
- **Last reviewed: 2026-11-16, against `5863806` (2026-11-12).** Previous: 2026-08-10, `84fdeff`.
- Absorbed originally from `ffb2fa6` (2026-06-12) via PRs #1, #2, #4.
- Process: for each absorbed skill, `git log <last-reviewed-ref>..main -- skills/<dir>` in a mattpocock/skills clone, then port what fits this fork's guardrails. Update the "last reviewed" ref above afterwards.

### Provenance

| Fork skill | mattpocock origin |
|---|---|
| `grilling` | `productivity/grilling` + `engineering/grill-with-docs` + `engineering/domain-modeling` (merged into one skill here) |
| `improving-architecture` | `engineering/improve-codebase-architecture` + `engineering/codebase-design` |
| `designing-modules` | `engineering/improve-codebase-architecture` + `engineering/codebase-design` (the design half, split out of `improving-architecture` — see divergences) |
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

### Ported in the 2026-11-16 review

- `grilling`: "word each question so 'yes' accepts your recommendation" (`95249b0`); the two-question format example (`85f83d3`); subagents get a fresh context window (`7739eae`, also in `improving-architecture` and `designing-modules`).
- `handoff`: explicit temp dir (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) (`4f4e943`).
- Fork-only: `grilling` round 0 (open why-question, no recommendation), from obra v7 brainstorming; `syncing-context` drops its hardcoded `Explore` subagent.

### Deliberate divergences — do not "sync" these back

- **`CONTEXT.md` stays `CONTEXT.md`.** Upstream renamed it to `GLOSSARY.md` / `GLOSSARY-MAP.md` (`d80fa0f`); the fork's state model uses CONTEXT.md everywhere.

- **`prototype` stays out of the repo.** Upstream now captures prototypes as a *primary source* on a throwaway branch; this fork keeps the temp-dir / never-committed / discard-when-answered guardrails, because here the prototype is a brainstorming-subordinate probe and the real thing is built from scratch via writing-plans → TDD.
- **`zoom-out` is kept** even though upstream removed it.
- **PRD umbrellas are kept.** Upstream renamed its PRD flow to `to-spec`; this fork's `brainstorming` still writes a PRD umbrella for multi-feature initiatives.
- **`grilling` owns domain capture.** Upstream splits `grilling` / `domain-modeling` / `grill-me` / `grill-with-docs`; the fork folds them into one skill with the CONTEXT.md + ADR discipline inline.
- **Longer skill descriptions.** Upstream trimmed its descriptions; the fork's carry routing detail (which skill invokes which) on purpose.
- **`improving-architecture` is split into discovery and design.** The design half — `LANGUAGE.md`, `DEEPENING.md`, `INTERFACE-DESIGN.md` and the CONTEXT.md/ADR capture moments — lives in `designing-modules`, a shared engine `brainstorming` also calls. Upstream keeps it all in one skill. When diffing, compare upstream's `improve-codebase-architecture` against **both** fork skills; the design content was moved, not dropped.

### Upstream skills not adopted (as of `5863806`)

`implement-spec`, `pr`, `retro`, `chief-of-staff` (in-progress), `software-factory` (in-progress), `wayfinder` (decision-ticket map on an issue tracker, for work too big for one session), `wizard`, `research`, `to-spec` / `to-tickets`, `code-review`, `triage`, `implement`, `wait-what`, `to-questionnaire`, `writing-for-agents`, `ask-matt` (router). Most overlap with the Superpowers spine this fork already has; `wayfinder` is the notable gap if long-horizon planning is ever wanted.
