# Finishing: follow-up sort and ticket resolution — eval notes (#16)

Pressure tests for `finishing-a-development-branch` Step 0 (follow-up sort)
and Step 5 ticket resolution, per `superpowers:writing-skills`. RED on the
installed 0.9.0 skill, GREEN on branch `ticket/16-finishing-sort`.

## What ran

- **Harness:** Claude Code. Each run was a fresh general-purpose subagent
  with a fresh context window, on the session's model (Opus). No other
  skills were loaded.
- **Fixture:** a throwaway script built a scratch git repo per run: `main` plus
  `feat/x` (one commit), a `test.sh` that prints `3 passed`. Follow-ups,
  tracker config and tickets were made with this branch's `followup` and
  `tracker` scripts. The fixtures were outside the repo and are not committed.
- **Prompt (all runs):** "Implementation on feat/x is done and I'm short on
  time - finish the branch. It split from main." The agent was told to follow
  the SKILL.md at a given path exactly, with scripted replies keyed by
  question: follow-ups → as stated per scenario; menu → per scenario;
  anything else → "your call". It reported every message it would send,
  every command it ran, and what it skipped. Outcomes were checked against
  the fixture's final state (follow-up file, ticket files, git log, PR body
  file), not only against the report.
- **Bias note:** the scripted reply list names "follow-ups / leftover items"
  in scenarios a and c on both arms, which hints that such a question may
  come. The 0.9.0 agents still never asked it.

| Scenario | Fixture | Replies |
|---|---|---|
| a. open follow-ups | Local Markdown config; 2 open follow-ups on `feat/x` (README typo; fetch retry), 1 on `main` | sort: "ok, go with your recommendations"; menu: 3 |
| b. none | no config, no follow-ups | menu: 3 |
| c. duplicate | Local Markdown; open ticket `follow-ups/01` "Retry the fetch client on timeout"; follow-up "add retry to the fetch client on timeout" | sort: "make it a ticket"; menu: 3 |
| d1. old test 4, merge | Local Markdown; ticket `demo/01` claimed; `branch.feat/x.ticket=demo/01` | menu: 1 |
| d2. old test 4, PR | GitHub H1; `branch.feat/x.ticket=#7`; bare `origin`; no `gh`, so the PR title and body go to a file | menu: 2 |

## Results

| Scenario | RED (0.9.0) | GREEN (this branch) |
|---|---|---|
| a | **Fail.** Tests ran, then the menu came; follow-ups were never mentioned ("the skill has no step for follow-ups"). 3 items still open. | **Pass.** Sort message (2 items, each with a recommendation and a reason) sent before `./test.sh` and before the menu. Typo fixed, `done 1 --as now`; retry → `publish-ticket - followup`, `done 2 --as ticket follow-ups/01`; fix + ticket files in one commit. The `main` item was not listed and stayed open. Body: What / Why it matters / Found during `Branch feat/x @ <sha>, review` / Acceptance criteria, with no paths or code. |
| b | Baseline: announce, tests, menu, "Keeping branch…". | **Pass.** Same messages as RED, word for word. The only extra step was one silent `followup list --open` (empty). |
| c | **Fail.** No sort. The agent saw `follow-ups/01` while browsing but took no action. | **Pass.** The first run's `find "retry timeout"` found nothing, but it retried with single words and linked the existing ticket: `done 1 --as ticket follow-ups/01` and `tracker comment`, no new file, committed. After the wording fix (below), the c2 rerun found it on the first single-word search. |
| d1 | **Fail.** Fast-forward merge and branch deleted, but `demo/01` still `Status: claimed`. | **Pass.** `tracker resolve demo/01 <ff tip>` was run from `main` after the green merged run. Ticket is `Status: done`. |
| d2 | **Fail.** The PR body had no `Closes` and no linked issue ("none was known"). | **Pass.** The body has `Closes #7`. The agent noted that main is the default branch, so GitHub closes the ticket on merge. |

## Refactor

GREEN a and c both passed several words to `tracker find`
(`"fetch retry timeout"`, `"retry timeout"`). `find` matches TEXT as one
literal substring, so those searches miss. Run a got no match, and that was
correct there. Run c reached the duplicate only by retrying on its own. The
reference now says to search one distinctive word at a time. Rerun c2 on a
fresh fixture: `find "retry"`, `"timeout"` and `"fetch"` each matched
`follow-ups/01` on the first try. No new ticket.

## Not exercised

The no-config `tracker init` offer, the discard keep-or-drop path, a GitHub
backend sort (the script refuses GitHub until #13), the local ref on the PR
path, and a PR to a non-default base. These are covered by the text only.
