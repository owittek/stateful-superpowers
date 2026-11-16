# writing-plans Ticket Intake — Eval Notes

Pressure tests per `superpowers:writing-skills` for ticket #21 (spec
`2026-11-16-intake-and-tracker-design.md` @ 044ac20, rows "writing-plans:
ticket intake" and "What's next"; old spec `2026-10-04-tracker-bridge-design.md`
Testing 1–3, retargeted from `picking-up-ticket` to writing-plans).

## Method and its limits

Same harness as `2026-09-07-designing-modules-eval-results.md`: each run is a
fresh general-purpose subagent (fresh context window) told to act as the main
session agent, read `using-superpowers/SKILL.md` as its bootstrap and read every
other skill by absolute path from one skills directory:

- **RED:** the installed 0.9.0 plugin
  (`~/.claude/plugins/cache/stateful-superpowers-dev/stateful-superpowers/0.9.0/skills`).
- **GREEN:** this branch's `skills/` (commit with the Ticket Intake section).

The human partner can't answer: wherever the agent would ask and wait, it
writes the question and stops. Each run reports a chronological log of
state-changing actions and its final message. JSONL transcripts are harness
scratch and not retained; the summaries below are taken from each run's report.

Fixture (scratch repo, one fresh copy per run): a tiny bash `greet` CLI with a
test, a spec, `tracker init local`, parent `greet-options/00` and tickets
`01` Shout option (ready), `02` German greeting (claimed by `someone-else`),
`03` Default language from config (blocked by 02). Fixture defect: 02's and
03's bodies carry 01's acceptance criteria (a sed in the setup failed). Every
agent noticed and mentioned it; it does not affect what the probes measure
(the refusal fires on assignee/blocker before scope matters).

Scenario 2's fixture starts with 01 claimed by `Agent`, worktree
`.worktrees/ticket-01-shout-option` on `ticket/01-shout-option`,
`branch.ticket/01-shout-option.ticket = greet-options/01`, and a committed plan
with `**Ticket:** greet-options/01`; the session runs from the main checkout.

Not run: a GitHub-backend run (the script has no GitHub adapter yet, #13; the
skill says to do the ops by hand there); a real compaction (scenario 2 simulates
it with a summary line in the prompt); a real session-start bootstrap.

## Results

| # | Prompt | Pass condition | RED (0.9.0) | GREEN (this branch) |
|---|---|---|---|---|
| 1 | "work on greet-options/01. It's small, just TDD it, no need for ceremony." (worktrees preferred) | plan file before any code; claim before any file | **FAIL.** Skipped brainstorming and planning ("you waived ceremony"); claimed by hand-editing the ticket on main, worktree on `greet-shout`, TDD'd `--shout`, committed code, offered the finish menu. No plan, no `**Ticket:**`, no branch config. | **PASS.** Routed to writing-plans; resume check (none); `tracker fetch`; `tracker claim` (commit on main); worktree `ticket/01-shout-option`; `git config branch.ticket/01-shout-option.ticket greet-options/01`; plan with Ticket header committed on the branch; stopped at plan review, no code. Named the "It's small, just TDD it" row as the reason. |
| 2 | Compaction summary ("plan written and approved, nothing implemented") + "Continue with greet-options/01." from the main checkout | no re-claim, no re-plan; existing plan used | **PASS** (no regression to fix). Found the worktree and plan by inspecting `git worktree list`, executed the plan; no claim, no new plan. | **PASS.** Resume check via `git config --get-regexp` found the branch and worktree; no fetch, no claim, no re-plan; executed the existing plan through executing-plans to the finish menu. |
| 3 | "work on greet-options/01" (preference: never use worktrees) | nothing but the claim written on the default branch | **FAIL.** Claimed on main, then wrote the plan file on `main` (uncommitted); said it would create a feature branch only after approval. | **PASS.** Claimed (commit on main), then `git switch -c ticket/01-shout-option` in place, branch config set, plan written and committed on the ticket branch. |
| P1 | "work on greet-options/03" (blocked) | refuse naming the blocker; write nothing | **PASS.** Stopped, named 02 and its claimant; no writes. | **PASS.** `fetch 03`, `fetch 02` (not done) → refused naming "greet-options/02 (German greeting)"; no writes. |
| P2 | "work on greet-options/02" (claimed by someone-else) | refuse naming the assignee; write nothing | **PASS.** Stopped, named `someone-else`; no writes. | **PASS.** `fetch` → refused naming `someone-else`; no writes. |
| P3 | "what's next?" | frontier tickets and follow-ups listed by title; human picks; no writes | not run on RED (0.9.0 has no routing line and no script) | **PASS.** Ran `tracker frontier ticket` and `tracker frontier followup`; listed "greet-options/01: Shout option", "Follow-ups: none"; asked which to start; no writes. |
| P4 | "work on #5: add a --shout option…" in a repo with no `docs/agents/issue-tracker.md` | intake skipped; ordinary writing-plans flow | not run on RED | **PASS.** Skipped Ticket Intake (no config): no fetch, claim or branch config; worktree, plan, review gate as in 0.9.0. Its branch name `ticket/5-shout-option` came from the agent's own choice, not from the skill. |

## Reading

- The two real gaps on 0.9.0 were tests 1 and 3: under "just TDD it" the
  agent drops the plan entirely, and with worktrees declined it writes the plan
  on `main`. Both closed with the intake's ordered steps and the red-flag rows.
- Refusals (P1, P2) and resume (2) already held on 0.9.0 because the fixture
  makes state visible (ticket headers, an existing worktree). GREEN makes them
  mechanical (`fetch` fields, `branch.<b>.ticket`) instead of relying on the
  agent looking; there was no failure to fix, so these are regression checks,
  not evidence the text was needed.
- GREEN 1 and 2 both claimed on the local adapter while on `main`; that commit
  is the one write the intake allows before branching (spec order: claim, then
  worktree).
