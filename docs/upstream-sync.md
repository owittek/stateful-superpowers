# Upstream sync

Stateful Superpowers draws from two upstreams. [obra/superpowers](https://github.com/obra/superpowers) is tracked through git, so its sync point is the merge-base. [mattpocock/skills](https://github.com/mattpocock/skills) has an incompatible tree layout and no merge lineage — this file is its sync record, so the next drift check is a diff rather than an archaeology dig.

## obra/superpowers

- Remote: `source` (`git@github.com:obra/superpowers.git`)
- Sync point: the merge-base with `source/main` — last merged **v7.0.2** on 2026-11-16 (fork 0.9.0)
- Process: **merge** `source/main`, resolve, bump the plugin version with `scripts/bump-version.sh`. Never rebase — the merge-base is what makes the next sync diffable, and `d856566` exists purely to repair it after a squash-merge lost the lineage.

### Recurring conflicts — decide these deliberately

- **Plugin manifests** (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.kimi-plugin/`, `.antigravity-plugin/`, `.devin-plugin/`, `.hermes-plugin/`, `.muse-plugin/`, `package.json`, `gemini-extension.json`): keep the fork's name/description/author, take upstream's structural changes, then bump to the fork's own version line (0.x, not upstream's 7.x). New harness manifests arrive with upstream's identity and must be rebranded; `.muse-plugin/plugin.json` lists skills explicitly, so add the fork-only skills. The Antigravity and Devin manifest tests pin the name — keep them on `stateful-superpowers`.
- **README install sections**: every install target points at `owittek/stateful-superpowers`. Harnesses that can only resolve upstream (GitHub Copilot CLI, OpenCode's npm install) are called out or dropped rather than silently shipping upstream to fork users.
- **`brainstorming`**: since v7 this is **upstream's file plus insertion points** (ADR 0003). On sync, take upstream's version and re-apply only these: (1) the "Domain language and decisions" paragraph in *Look Before You Ask* (`grilling` capture mode); (2) "or an ADR rules out" and the *Architecture pass* paragraph in *The Conversation* (details in `references/architecture-pass.md`); (3) spikes are built in a subagent outside the repo and discarded; (4) the PRD umbrella sentence in *Size the Work*; (5) the domain-terms and Architecture lines in *The Written Design*; (6) the gate: the quick-task and opt-out paths still need approval of a short design, the gate's only exception is an approved spike, and there's one extra red-flag row; (7) the CONTEXT.md/ADR/Architecture paragraph in `builder-check-prompt.md`.
- **`finishing-a-development-branch`**: upstream's file plus insertion points (#16); `scripts/` and `references/follow-up-sort.md` are fork-only. On sync, take upstream's SKILL.md and re-apply only these: (1) "Sort follow-ups →" in the Overview's core principle; (2) the *Step 0: Sort Follow-ups* section before Step 1; (3) the `BRANCH`/`TICKET` lines and the `TRACKER` paragraph in Step 2; (4) the `tracker resolve` sentence in Option 1; (5) the "With a `TICKET`" list in Option 2; (6) "Ticket <ref> stays claimed." in Option 3; (7) the keep-or-drop sentence in the discard section; (8) the "The PR will close the ticket anyway" rationalization row.
- **`writing-plans`**: upstream's file plus insertion points (ADR 0004). Re-apply: (1) the *Ticket Intake* section between "Save plans to" and *Scope Check*; (2) the optional `**Ticket:**` line after `**Goal:**` in the *Plan Document Header* template.
- **`using-superpowers`**: upstream's file plus insertion points. Re-apply: (1) the two ticket lines at the top of *Routing by intent* (ticket work → writing-plans; "what's next" → `tracker frontier`).
- **Follow-up list writers (#22).** On sync, take upstream's version of each file and re-apply only these: (1) `subagent-driven-development/references/final-review.md` *Finish*: the paragraph after the rulings list that adds each unaddressed `minor (deferred)` ledger line with `followup add --source sdd:<plan-basename>`; (2) `executing-plans/SKILL.md` *Finish*: the same paragraph with `--source exec:<plan-basename>`; (3) `requesting-code-review/SKILL.md` *Act on feedback*: the Minor bullet calls `followup add --source review` (ledger instead inside SDD/executing-plans); (4) `receiving-code-review/SKILL.md`: the "Real but out of scope" paragraph after the YAGNI rule (same ledger-instead guard); (5) `systematic-debugging/SKILL.md` Phase 4 step 2: the adjacent-bug bullet (`--source debug`); (6) `using-superpowers/SKILL.md` *Routing by intent*: the "Note that for later" line; (7) `hooks/session-start`: the `{{SKILLS_DIR}}` substitution after the skill is read (gives injected routing lines an absolute helper path) and the compaction-reminder block after `session_context=` (builtins only, stdin read only when the list has open items); (8) `tests/hooks/test-session-start.sh`: the two helper-path cases (`followup`, `tracker`) and the compaction-reminder cases, including the clean-repo and open-stdin loops, before the EPIPE section; (9) `tests/sdd-helper-paths/test-sdd-helper-paths.sh`: `tracker` and `followup` in the helper list and in the header comment.
- **`AGENTS.md`**: the appended *Agent skills / Issue tracker* section pointing at `docs/agents/issue-tracker.md` (added when GitHub was configured as this repo's tracker, `3ec058c`). Re-append on sync.
- **`RELEASE-NOTES.md`**: fork entries (`v0.x`) sit above upstream's at the top. On sync, keep them on top and insert upstream's new entries below them.
- **`README.md`**: besides the install sections, the *Follow-ups and Tickets* section after *The Basic Workflow* and its table-of-contents line (#17). Re-apply on sync.

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
| `handoff` | `productivity/handoff` |
| `zoom-out` | `engineering/zoom-out` (since deleted upstream) |

**Tracker port: a divergence, not a port (ADR 0004).** The tracker bridge (`finishing-a-development-branch/scripts/tracker`, writing-plans' *Ticket Intake*, the follow-up sort, the "what's next" routing line) derives from the ideas in `setup-matt-pocock-skills`, `to-tickets` and `implement`, but none of them is ported: `tracker init` replaces the setup wizard, writing-plans takes a ticket ref instead of a runner wrapping it, and the finishing-time follow-up sort replaces triage. There is nothing to diff against upstream. Only the config file stays Pocock-compatible (`docs/agents/issue-tracker.md`, H1 `# Issue tracker: GitHub` / `Local Markdown`), so his skills can still read it. This supersedes step 4 of the 2026-10-04 tracker-bridge spec's rollout ("publishing ← to-tickets, setting-up-tracker ← setup, pickup ← implement").

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

- **`prototype` was removed (2026-11-16).** It duplicated brainstorming's visual companion (throwaway HTML in a browser) and upstream's spike (real code). Its one guardrail survives as the spike hook in brainstorming: built in a subagent, outside the repo, then discarded. Don't re-adopt upstream's `prototype`.
- **`zoom-out` is kept** even though upstream removed it.
- **`handoff` is narrowed (#22).** Its description lists when to hand off (new harness, directory, colleague, side task, reasoning not yet in a spec, plan or ticket) instead of upstream's context-hygiene framing, and the body adds two lines: tracker-held thinking stays in specs and tickets, and open follow-ups are pointed at (`.superpowers/followups.md`), not copied, unless the move leaves the repo or machine.
- **PRD umbrellas are kept.** Upstream renamed its PRD flow to `to-spec`; this fork's `brainstorming` still writes a PRD umbrella for multi-feature initiatives.
- **`grilling` owns domain capture.** Upstream splits `grilling` / `domain-modeling` / `grill-me` / `grill-with-docs`; the fork folds them into one skill with the CONTEXT.md + ADR discipline inline.
- **Longer skill descriptions.** Upstream trimmed its descriptions; the fork's carry routing detail (which skill invokes which) on purpose.
- **`improving-architecture` is split into discovery and design.** The design half — `LANGUAGE.md`, `DEEPENING.md`, `INTERFACE-DESIGN.md` and the CONTEXT.md/ADR capture moments — lives in `designing-modules`, a shared engine `brainstorming` also calls. Upstream keeps it all in one skill. When diffing, compare upstream's `improve-codebase-architecture` against **both** fork skills; the design content was moved, not dropped.

### Upstream skills not adopted (as of `5863806`)

`implement-spec`, `pr`, `retro`, `chief-of-staff` (in-progress), `software-factory` (in-progress), `wayfinder` (decision-ticket map on an issue tracker, for work too big for one session), `wizard`, `research`, `to-spec` / `to-tickets` (tickets: see the tracker divergence above), `code-review`, `triage` (replaced by the follow-up sort), `implement` (replaced by writing-plans' ticket intake), `wait-what`, `to-questionnaire`, `writing-for-agents`, `ask-matt` (router). Most overlap with the Superpowers spine this fork already has; `wayfinder` is the notable gap if long-horizon planning is ever wanted.
