# Follow-up Writers, SDD Harvest, Compaction Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Feed the follow-up list from every place follow-ups are found (SDD and executing-plans finish, code review, debugging, "note that for later"), remind after compaction, and narrow handoff to point at the list.

**Ticket:** #22 — `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md` @ `044ac20`, Architecture rows "Ledger harvest", "Follow-up writers", "Compaction reminder", "handoff (narrowed)". Acceptance criteria are the ticket's five checkboxes; nothing else is in scope.

**Architecture:** Skill-text insertions that each call the existing `skills/finishing-a-development-branch/scripts/followup` (from #19) by absolute path; one builtin-only block in `hooks/session-start` that counts `- [ ] ` lines and reads the hook's stdin `source` only when there is something to report; every upstream-tracked edit recorded in `docs/upstream-sync.md`.

**Tech Stack:** bash 3.2 / zsh-compatible builtins, markdown skills, shell tests.

**Spec:** `docs/superpowers/specs/2026-11-16-intake-and-tracker-design.md`

## Global Constraints

- Work only in worktree `.claude/worktrees/ticket-22-followup-writers`, branch `ticket/22-followup-writers`. Do not modify `scripts/followup` or `scripts/tracker`.
- Clean repo (no tracker config, no follow-ups) behaves exactly as 0.9.0.
- `hooks/session-start` starts no processes; additions use shell builtins only (no `$(...)`, pipes, external commands).
- Helpers are called by absolute path from the working tree (`tests/sdd-helper-paths`).
- Every edit to an upstream-tracked file is an insertion point recorded in `docs/upstream-sync.md`.
- Every SKILL.md stays under 20,000 bytes (`tests/skill-size`; executing-plans is at 18,364).
- Reminder copy verbatim: `N open follow-ups in .superpowers/followups.md (`followup list --open --all`).`
- Writers' reply copy verbatim: `Noted as follow-up N.`
- Sources: `sdd:<plan-basename>`, `exec:<plan-basename>`, `review` (requesting and receiving), `debug` (systematic-debugging; spec names none — my call).
- Conventional commits, no attribution trailers.

## Decisions beyond the spec text

1. Compact detection: Claude Code passes SessionStart JSON on stdin with `"source": "startup"|"resume"|"clear"|"compact"`. The hook reads stdin with `IFS= read -r -t 1 -d ''` (builtin, timeout guards a pipe left open) **only** when `CLAUDE_PROJECT_DIR` is set, the file is readable and the open count is > 0, and stdin is not a terminal (`[ -t 0 ]`). Whitespace is stripped (`${s//[[:space:]]/}`) and `*'"source":"compact"'*` matched. A clean repo never touches stdin, so its output and timing are unchanged.
2. The reminder line is appended after `</EXTREMELY_IMPORTANT>` as `\n\n<line>` in all output shapes (the var gate already limits it to Claude Code).
3. requesting-code-review adds a guard: inside SDD or executing-plans minors go to the ledger instead (the finish harvests them), so nothing is added twice.
4. `tests/sdd-helper-paths` widens its helper list with `followup` so the new invocations are held to the absolute-path rule.
5. handoff keeps its body apart from two added lines; its description becomes the old spec's narrowed one.

## Review Focus

1. Hook stdin left open without EOF → hook still finishes within about a second (test: open pipe for 3 s, hook returns in < 3 s).
2. `"source": "compact"` with spaces after the colon → still detected (test).
3. File with only closed items → no line (test).
4. File whose last open line has no trailing newline → counted (test).
5. A harvested minor is not also added during the per-task review (decision 3; read check).

---

### Task 1: Compaction reminder in `hooks/session-start`

**Files:**
- Modify: `hooks/session-start` (after `session_context=` is built, before output)
- Test: `tests/hooks/test-session-start.sh`

**Interfaces:**
- Consumes: env `CLAUDE_PROJECT_DIR`; file `$CLAUDE_PROJECT_DIR/.superpowers/followups.md` (line format from #19: open `- [ ] N. ...`, closed `- [x] N. ...`); stdin JSON.
- Produces: injected context unchanged, or with one appended line.

- [ ] **Step 1: Write failing tests** in `tests/hooks/test-session-start.sh`, before the EPIPE section: a helper `run_with_stdin JSON_FILE` invoking `"$bash_bin" -c 'exec "$1" "$2" < "$3"'`; fixture project dir with `.superpowers/followups.md` holding two `- [ ] ` lines and one `- [x] ` line (last open line unterminated). Cases via `assert_command_output` (nested shape):
  - compact (`{"session_id":"x","source":"compact"}`) + 2 open → contains `2 open follow-ups in .superpowers/followups.md`
  - compact with `"source": "compact"` → contains the same
  - startup + 2 open → not contains `open follow-ups`
  - compact + no file → not contains `open follow-ups`
  - compact + only closed items → not contains `open follow-ups`
  - clean project dir: for each of startup/resume/clear/compact, output byte-equal to the output with no `CLAUDE_PROJECT_DIR` and `</dev/null`
  - stdin pipe held open 3 s with the file present → hook returns in < 3 s (`SECONDS`)
- [ ] **Step 2: Run** `bash tests/hooks/test-session-start.sh` — Expected: the two "contains" cases FAIL, rest PASS.
- [ ] **Step 3: Implement** the block in `hooks/session-start` per decision 1–2, with a header comment on why stdin is read lazily.
- [ ] **Step 4: Run** `bash tests/hooks/test-session-start.sh` and `bash scripts/lint-shell.sh hooks/session-start tests/hooks/test-session-start.sh` — Expected: STATUS: PASSED, lint clean.
- [ ] **Step 5: Commit** `feat(hooks): open follow-up count after compaction`

### Task 2: Ledger harvest in SDD and executing-plans finish

**Files:**
- Modify: `skills/subagent-driven-development/references/final-review.md` ("Finish", between the rulings paragraph and the delete paragraph)
- Modify: `skills/executing-plans/SKILL.md` ("Finish", same position)
- Modify: `tests/sdd-helper-paths/test-sdd-helper-paths.sh` (helper list gains `followup`)

**Interfaces:**
- Consumes: `followup add TEXT [--source S]` → prints N.

- [ ] **Step 1:** Add `followup` to the `invocation` regex alternation and the header comment. Note the current `checked` count.
- [ ] **Step 2:** Insert one paragraph in each Finish: each ledger `minor (deferred)` line the final fix wave did not address → `../finishing-a-development-branch/scripts/followup add "<one-liner>" --source sdd:<plan-basename>` (executing-plans: `exec:<plan-basename>`; there every minor is unaddressed), by its absolute path, from the working tree you're executing in, before deleting the workspace. `parked` lines are rulings and stay in "Rulings I made" only.
- [ ] **Step 3: Run** `bash tests/sdd-helper-paths/test-sdd-helper-paths.sh; bash tests/skill-size/test-skill-size.sh` — Expected: both PASS, checked count +2.
- [ ] **Step 4: Commit** `feat(sdd): harvest unaddressed deferred minors to the follow-up list`

### Task 3: Follow-up writers and routing

**Files:** `skills/requesting-code-review/SKILL.md` ("Act on feedback" Minor bullet), `skills/receiving-code-review/SKILL.md` (after the YAGNI rule), `skills/systematic-debugging/SKILL.md` (Phase 4 step 2), `skills/using-superpowers/SKILL.md` (Routing by intent)

- [ ] **Step 1:** One line each calling `../finishing-a-development-branch/scripts/followup add "<item>" --source <review|debug>` by its absolute path, from the working tree you're executing in, and saying `Noted as follow-up N.`; requesting-code-review carries decision 3. using-superpowers: "note that for later" / "follow up on X" → same call without `--source`.
- [ ] **Step 2: Run** sdd-helper-paths, skill-size, skill-layout — Expected: PASS.
- [ ] **Step 3: Commit** `feat(skills): note out-of-scope findings as follow-ups`

### Task 4: handoff narrowed, upstream-sync entries

**Files:** `skills/handoff/SKILL.md`, `docs/upstream-sync.md`

- [ ] **Step 1:** handoff description → "Compact the current conversation into a handoff document for another agent to pick up. Use when moving to a new harness, a new directory, a colleague, forking a side task mid-phase, or carrying reasoning not yet captured in a spec, plan or ticket." Body gains: tracker line from the old spec; open follow-ups are not copied, point at `.superpowers/followups.md`, list them only when the move leaves the repo or machine.
- [ ] **Step 2:** `docs/upstream-sync.md`: new subsection under obra listing each insertion point from Tasks 1–3 (file, location, one-line content); mattpocock divergences gain the handoff narrowing.
- [ ] **Step 3: Run** full verification: tests/hooks, tests/followup/run-tests.sh, lint on changed shell files, skill-layout, skill-size, sdd-helper-paths — Expected: all PASS.
- [ ] **Step 4: Commit** `docs: handoff points at the follow-up list; record insertion points`
