# Tracker Port: GitHub Adapter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement every tracker-port op for `# Issue tracker: GitHub` through `gh`, so skills drive GitHub Issues exactly as they drive the Local Markdown adapter.

**Ticket:** #13 — acceptance criteria are its six checkboxes; nothing else is in scope.

**Architecture:** Same single script, `skills/finishing-a-development-branch/scripts/tracker`: a `github_<op>` function per op beside `local_<op>`, a small `gh` helper layer (preflight, one-line failure wrapper, label ensure, issue JSON reads), and the dispatcher routing the GitHub H1 to `adapter=github` after a preflight. Sub-issues and dependencies go through `gh api` REST endpoints; everything else through `gh issue` / `gh label`. The repo is gh's default (GH_REPO when set, else the checkout's remote); `gh api` paths use gh's `{owner}/{repo}` placeholders so both sources work. `gh repo view` ignores GH_REPO, so it is not used.

**Tech Stack:** bash 3.2-compatible shell, gh ≥ 2.x (built-in `--jq`, no separate jq), git.

**Spec:** `docs/superpowers/specs/2026-10-04-tracker-bridge-design.md` @ 5d79504, "Tracker port" (GitHub column), "Error handling"; `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` @ 044ac20, Architecture row "Tracker port"; ADR 0005.

## Global Constraints

- Worktree `.claude/worktrees/ticket-13-github-adapter`, branch `ticket/13-github-adapter`. No SKILL.md edits (#16, #21 run in siblings).
- Bash 3.2, BSD+GNU userland, no `local x=$(...)` (masks status), lint via `bash scripts/lint-shell.sh <files>`.
- Refs are `#N`; input accepts `#N` or `N`. Output `#N`.
- Kinds are labels of the same name. Parent kinds: `spec`, `map`, `followups`. Child kinds: `ticket`, `decision`, `followup`. Missing labels are created on demand.
- Standing Follow-ups parent: kind label `followups`, title `Follow-ups`, found among open issues by label+title, created once, body `Standing parent for deferred follow-up tickets; never closed, points at no spec.`
- Resolve comment text verbatim: `Resolved by <what>`.
- Every failure: exit 1 (2 for usage), exactly one line on stderr. gh missing: `gh is not installed; the GitHub tracker needs it`. Unauthenticated: `gh is not authenticated: run gh auth login`.
- Live tests: `tests/tracker/test-tracker-github.sh`, repo `owittek/tracker-scratch` via `GH_REPO` (override with `TRACKER_TEST_REPO`), a temp git repo with no remote holds the config; skipped with exit 0 when `gh auth status` fails. Unique run tag in every title; EXIT trap closes every issue the run created.
- Commits conventional, no attribution trailer.

## Review Focus

- Dependency summary lag: right after an edge is added or a blocker closed, `issue_dependencies_summary.blocked_by` is stale for seconds (observed on the scratch repo). frontier therefore checks each candidate's `dependencies/blocked_by` list for open blockers instead of trusting the summary. Live test asserts frontier immediately after publish and after resolve.
- Bad ref (`#999999`, `abc`): one-line `no such ref: <ref>`, not gh's multi-line HTTP error. Test in Task 2.
- Publish with a missing blocker: refused before the issue is created (nothing left behind). Test in Task 2.
- Publish under a child-kind issue (a ticket): refused `<ref> is not a parent`; claim on a parent-kind issue refused `<ref> is a parent, not a ticket`. Tests in Tasks 2 and 3.
- Issues disabled: init github prints a one-line hint on stderr and does not change settings (stub gh test, Task 5).

---

### Task 1: gh preflight and dispatch

**Files:**
- Modify: `skills/finishing-a-development-branch/scripts/tracker` (dispatcher; new helpers section `# --- GitHub adapter ---`)
- Modify: `tests/tracker/test-tracker-errors.sh` (GitHub backend block)
- Modify: `tests/tracker/helpers.sh` (`gh_unauth_env`, `path_without_gh`)

**Interfaces:**
- Produces: `gh_preflight` (dies with the two Global-Constraints messages), `ghx ARGS...` (runs gh, on failure dies with gh's last non-empty stderr line prefixed `gh: `), `gh_num REF` (→ `N` or dies `no such ref: REF`).

- [ ] **Step 1: failing tests** in test-tracker-errors.sh: replace the "not implemented yet" GitHub block with `assert_every_op_fails` run (a) with `GH_CONFIG_DIR=<empty dir>` and `GH_TOKEN`/`GITHUB_TOKEN` unset → needle `gh is not authenticated`; (b) with PATH stripped of every dir holding `gh` (plus a dir symlinking bash and git) → needle `gh is not installed`. These run offline, always.
- [ ] **Step 2:** run `bash tests/tracker/test-tracker-errors.sh` → FAIL on the new block.
- [ ] **Step 3:** implement `gh_preflight`, `ghx`, `gh_num`; dispatcher: `GitHub) adapter=github; gh_preflight ;;`.
- [ ] **Step 4:** errors test passes.
- [ ] **Step 5:** commit `feat(tracker): gh preflight for the GitHub backend`.

### Task 2: register-parent, publish-ticket, fetch

**Files:**
- Modify: tracker script
- Create: `tests/tracker/test-tracker-github.sh`

**Interfaces:**
- Produces: `gh_ensure_label KIND` (create, ignore "already exists"), `gh_issue_json N JQ` (REST `repos/{owner}/{repo}/issues/N`, 404 → `no such ref: #N`), `gh_db_id N`, `gh_kind_of N` (first label that is a known kind, else first label).
- `github_register_parent KIND TITLE SPEC_PATH SHA [SUMMARY_FILE]` → `#N`; body `Spec: PATH @ SHA` + blank + summary.
- `github_publish_ticket PARENT|- KIND TITLE BODY_FILE [BLOCKER...]` → `#N`. Order: validate body file, parent (exists; not child kind), every blocker (db id); then label, create, `POST issues/P/sub_issues -F sub_issue_id=<id>`, per blocker `POST issues/N/dependencies/blocked_by -F issue_id=<id>`.
- `github_fetch REF` → same nine-line shape as local: `ref/kind/title/state/assignee/parent/blockers`, blank, body. state: closed → `done`; parent kinds → `open`; assigned → `claimed`; else `ready`. parent from `GET issues/N/parent` (404 → none); blockers from `GET issues/N/dependencies/blocked_by`, space-separated `#N`.

- [ ] **Step 1: failing live test** (skip guard, `RUN_TAG=trk-<epoch>-<pid>`, created-issue list + EXIT trap closing them): register-parent spec + three publish-ticket (2nd and 3rd blocked by 1st) → refs `#N`; parent's `sub_issues` lists the three; `dependencies/blocked_by` of 2 and 3 is the first; fetch fields; refusals: missing blocker (`no such ref: #999999`, and no new issue with that title), unknown parent, ticket-as-parent (`is not a parent`), missing body file.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement.
- [ ] **Step 4:** pass.
- [ ] **Step 5:** commit `feat(tracker): GitHub register-parent, publish-ticket, fetch`.

### Task 3: frontier, claim, resolve, comment

**Interfaces:**
- `github_frontier KIND [PARENT]` → `#N<TAB>title`, ascending number. Candidates: open, not a PR, labelled KIND, no assignees; from `issues/P/sub_issues` (paginated) when PARENT given, else `issues?labels=KIND&state=open`. Keep when `dependencies/blocked_by` has no open entry.
- `github_claim REF` → ok. Closed → `#N is done`; parent kind → `#N is a parent, not a ticket`; assignees include `gh api user` login → ok without writing; other assignees → `#N is claimed by <logins, comma-separated>`; else `gh issue edit N --add-assignee @me`.
- `github_resolve REF WHAT` → `gh issue comment N --body "Resolved by WHAT"`, then close if open → ok.
- `github_comment REF TEXT_FILE` → `gh issue comment N --body-file FILE` → ok.

- [ ] **Step 1: failing live tests:** frontier on parent → only first; claim → ok; claim again → ok; frontier → empty; resolve first → closed with comment `Resolved by <what>`, frontier → second and third; other-user claim via a `gh` wrapper on PATH whose `api user` answers `someone-else` → exit 1 naming `owittek` (the real login); claim on parent refused; comment posts the file text.
- [ ] **Steps 2–4:** run → FAIL; implement; pass.
- [ ] **Step 5:** commit `feat(tracker): GitHub frontier, claim, resolve, comment`.

### Task 4: find and the Follow-ups parent

**Interfaces:**
- `github_followups_parent` → `N` of the open issue labelled `followups` titled `Follow-ups`, creating it on first use (after validation, as local).
- `github_find KIND TEXT` → `#N<TAB>title` of open issues labelled KIND whose title or body contains TEXT, case-insensitive and literal (jq `ascii_downcase | contains(<TEXT as JSON string>)`; `json_string` helper escapes `\` `"` and control chars).

- [ ] **Step 1: failing live tests:** two `publish-ticket - followup` calls → one open Follow-ups parent, both its sub-issues, kind followup; `- ticket` refused; find by title (upper-case), by body, kind filter, `flaky.claim` literal no match, no-match exit 0, resolved issue skipped. Follow-ups parent created by this run is closed in the trap.
- [ ] **Steps 2–4:** run → FAIL; implement; pass.
- [ ] **Step 5:** commit `feat(tracker): GitHub find and Follow-ups parent`.

### Task 5: init github, header, runner

**Interfaces:**
- `init_config github`: gh_preflight; existing config: GitHub → leave file, still ensure labels; other/none H1 → refuse as local does. Else write the GitHub template: H1, intro, `## Ticket operations` (same op list, GitHub wording), then Pocock's Conventions, PR triage, "publish"/"fetch" sections from `docs/agents/issue-tracker.md`. Ensure labels `spec ticket followup followups`. `has_issues` false → stderr `issues are disabled on <owner/repo>; enable them with: gh repo edit --enable-issues`. Print ok.

- [ ] **Step 1: failing tests:** live: fresh temp repo `init github` → ok, H1 `# Issue tracker: GitHub`, `## Ticket operations` line, config uncommitted, all four labels exist, rerun byte-identical; init github over Local config refused. Offline (test-tracker-init.sh): stub `gh` (auth ok, `has_issues` false, label create ok) → ok plus hint line on stderr; replace "not implemented" assertion.
- [ ] **Steps 2–4:** FAIL; implement; pass.
- [ ] **Step 5:** update script header comment (GitHub layout, repo selection, lag note), add `test-tracker-github.sh` to run-tests.sh; full suite, lint, `tests/sdd-helper-paths`, `tests/skill-layout`.
- [ ] **Step 6:** commit `feat(tracker): init github`.
