# Integration (README, provenance, equivalence, trial verdict, -next entry) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close out the intake and tracker work on `next`: document it, record its insertion points and provenance, version it 0.10.0-dev, prove the clean path is unchanged, record the trial verdict, and add a `-next` marketplace entry on `main`.

**Ticket:** #17 — `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` @ `044ac20`, section "Rollout"; old spec `2026-10-04-tracker-bridge-design.md` "Rollout and the trial" steps 2–3. Acceptance criteria are the ticket's five checkboxes.

**Architecture:** Docs and manifests only; no skill or script behaviour changes. The `main` change lives on its own branch and PR.

**Tech Stack:** markdown, JSON, bash test suites, `gh`.

**Spec:** `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md`

## Global Constraints

- Work in worktree `.claude/worktrees/ticket-17-integration`, branch `ticket/17-integration`; the `main` change in `.claude/worktrees/chore-marketplace-next`, branch `chore/marketplace-next` off `origin/main`.
- No new skills. No edits to skills, scripts or hooks.
- Install nothing system-wide. `yq` is missing: bump `.hermes-plugin/plugin.yaml` by hand, every JSON manifest via the script's own `jq` path, and say so.
- Do not run suites that call `claude`, `opencode run` or other paid models; list them unrun.
- Conventional commits, no attribution lines; PR bodies without attribution.
- Neither PR is merged.

## Review Focus

1. A second `plugins[]` entry in `.claude-plugin/marketplace.json` must not break `bump-version.sh` (it reads `plugins.0.version` only) — verify `--check` after adding it on main.
2. Every insertion point in `docs/upstream-sync.md` must exist where described — checked by grep per point in Task 2.
3. README additions must not imply new skills or a tracker requirement; a clean repo needs nothing.
4. Version audit must show no undeclared `0.9.0` outside history/notes.

---

### Task 1: README

**Files:** Modify `README.md` (new section "Follow-ups and tickets" after *The Basic Workflow*, plus TOC line)

- [ ] Write the section: follow-up list ("note that for later"; fed by code review minors, SDD/executing-plans deferred minors, debugging's adjacent bugs; lives in git-ignored `.superpowers/followups.md`); sort at finishing (now / ticket / drop, one reply); working from a tracker (`tracker init github|local`, "work on #N" → writing-plans claims, branches, plans the ticket; "what's next" → frontier). One line: no new skills; clean repo unchanged.
- [ ] Verify: `grep -n "Follow-ups and tickets" README.md` shows TOC and heading.
- [ ] Commit `docs(readme): describe follow-up list, sort and working from a tracker`.

### Task 2: upstream-sync

**Files:** Modify `docs/upstream-sync.md`

- [ ] Grep every listed insertion point against the files (done in planning: all present). Fix stale: item (9) of #22 names only `followup`, the test lists `tracker` and `followup` and its header comment. Add missing: `AGENTS.md` "Agent skills / Issue tracker" block (from the trial's Pocock setup run); `README.md` follow-ups section (Task 1).
- [ ] Add provenance: tracker port derives from Pocock's `to-tickets`, `implement`, `setup-matt-pocock-skills` ideas but is a divergence (ADR 0004), not a port; config stays Pocock-compatible. Update "Upstream skills not adopted" to point at it.
- [ ] Commit `docs(upstream-sync): record remaining insertion points and tracker provenance`.

### Task 3: Version and release notes

**Files:** `.version-bump.json`-declared manifests; `RELEASE-NOTES.md`

- [ ] Bump to `0.10.0-dev` (script path for JSON, hand edit for the YAML). Verify `jq` reads on all JSON and `grep version .hermes-plugin/plugin.yaml`; `--check` cannot read YAML without yq — note it.
- [ ] `RELEASE-NOTES.md`: `## v0.10.0-dev (2026-11-16)` at top in the existing voice (intro paragraph, `###` sections, bold lead sentences).
- [ ] Run `tests/version-bump/test-bump-version.sh` (skips/fails without yq: record).
- [ ] Commit `chore: bump to 0.10.0-dev, release notes`.

### Task 4: Clean-repo equivalence run

- [ ] Run every free suite (followup, tracker incl. GitHub scratch-repo test via `gh`, hooks, sdd-helper-paths, skill-size, skill-layout, shell-lint, version-bump, antigravity, kimi, devin, codex, codex-plugin-sync, diagnosing-superpowers, systematic-debugging find-polluter, writing-skills, claude-code script tests that don't call `claude`, opencode without `--integration`, pi, hermes pytest, brainstorm-server). Record pass/fail/skip.
- [ ] List unrun: `tests/claude-code` skill/integration tests, `tests/explicit-skill-requests`, opencode `--integration`, with cost.

### Task 5: Trial verdict

**Files:** Modify `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` (append "Eval notes / trial verdict")

- [ ] Write the facts given by the human partner plainly, the equivalence result from Task 4, and the verdict: continue with the ticket model; branch dependents off `next` after blockers merge rather than stacking.
- [ ] Commit `docs(spec): record trial verdict and equivalence run`.

### Task 6: PR for #17

- [ ] Push; `gh pr create --base next`, body starting `Closes #17`.

### Task 7: `-next` marketplace entry on main

**Files:** `.claude-plugin/marketplace.json` in a new worktree on `chore/marketplace-next` off `origin/main`

- [ ] Append plugin entry `{"name": "stateful-superpowers-next", "source": {"source": "github", "repo": "owittek/stateful-superpowers", "ref": "next"}, ...}` (description says pre-release; enable per project with the stable plugin disabled).
- [ ] `claude plugin validate . --strict`; `scripts/bump-version.sh --check` JSON entries unaffected.
- [ ] Commit `chore(marketplace): add stateful-superpowers-next pinned to next`; push; PR to `main`.
