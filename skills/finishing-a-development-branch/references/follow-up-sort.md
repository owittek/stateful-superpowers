# Follow-up sort

Step 0 of finishing-a-development-branch, read only when
`followup list --open` printed items for this branch. Every item gets one
disposition — **now**, **ticket** or **drop** — chosen by your human
partner in one reply, before the test run (doing items changes code).

`FOLLOWUP` and `TRACKER` below are this skill's `scripts/followup` and
`scripts/tracker`: run each by its absolute path, from the working tree
you're executing in.

## 1. Is "ticket" on offer?

Read the H1 of `docs/agents/issue-tracker.md`:

| Config | Ticket offered? |
|---|---|
| `# Issue tracker: Local Markdown` | yes |
| `# Issue tracker: GitHub` | only if `TRACKER find followup "<key words of an item>"` exits 0. If it says "not implemented", the script can't file GitHub tickets yet: offer now / drop only and say so in the message. |
| any other H1 | no — the script refuses other trackers; say so |
| no file | yes, through `TRACKER init` (section 4) |

On the discard path "ticket" is never offered (section 6).

## 2. The one message

List every open item for this branch — all of them, in one message — each
with your recommended disposition and a one-line why. Recommend **now**
for anything small enough to fix on this branch, **ticket** for real work
that outlives this branch, **drop** for items the branch made moot.

```
Before I run the tests: <K> open follow-ups on <branch>.

1. <text> — now: <why>
2. <text> — ticket: <why>
3. <text> — drop: <why>

Reply "ok" to take these, or change any (e.g. "2 drop").
```

Wait for the reply. One reply settles every item; don't re-ask per item.

## 3. Carry out each disposition

- **now:** fix it on the branch (TDD as usual), then
  `FOLLOWUP done N --as now`.
- **drop:** `FOLLOWUP done N --as dropped`.
- **ticket:** look for an open duplicate first:
  `TRACKER find followup "<word>"`. TEXT is one literal, case-insensitive
  substring, not a set of keywords: search each distinctive word of the
  item separately ("retry", then "timeout") and read the matches.
  - A match that covers the item: `FOLLOWUP done N --as ticket <ref>`, and
    write a short note (what was found again, branch @ sha) to a temp file
    for `TRACKER comment <ref> <file>`. No new ticket.
  - No match: write BODY_FILE (template below) to a temp file, then
    `TRACKER publish-ticket - followup "<title>" BODY_FILE`; it prints the
    ref. `FOLLOWUP done N --as ticket <ref>`.

Follow-up ticket body — the ticket's whole content (ADR 0005); no file
paths or code, the sha lets the picker re-find the sites:

```markdown
## What

What was found and the behaviour wanted, from the user's or maintainer's view.

## Why it matters

Cost of leaving it.

## Found during

Branch <name> @ <short sha>, <source> (review / sdd:<plan> / debugging / session).

## Acceptance criteria

- [ ] ...
```

**Local Markdown adapter:** publish and comment leave the ticket files in
the work tree. Commit them on this branch together with the sort's fixes
(one commit), so they reach the base on merge. Then continue to Step 1.

## 4. No tracker config and an item marked ticket

Offer `TRACKER init` once, for all such items together:

- no `github.com` remote → "No issue tracker is set up. Create a local
  one (`docs/superpowers/tickets/`) for these?" → `TRACKER init local`,
  commit the config with the ticket files.
- a `github.com` remote → offer `TRACKER init github`. If it answers "not
  implemented", say the script can't file GitHub tickets yet.

Declined, or init refused: those items stay open on the list. Say so in
your report — "Follow-ups <N, M> stay open on the list." — and continue.

## 5. Report

After the sort, one line per disposition before Step 1, e.g.
"Fixed 1; 2 → ticket follow-ups/03; 3 dropped."

## 6. Discard path

When your human partner asked to discard the work, the sort is reduced to
**keep** (item stays open on the list, it outlives the branch) or **drop**
(`FOLLOWUP done N --as dropped`), for this branch's items only. Ask it in
the same message as the discard confirmation.
