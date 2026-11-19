# Kept follow-ups (short design)

## Intent

Agents record project-wide to-dos in auto-memory (MEMORY.md), where they
resurface only when something related comes up; the owner loses track until a
manual prune. Give every open to-do one home — the follow-up list — and a way
for items that outlive their branch to stay there without being re-sorted.

## Goals / non-goals / anti-goals

- Goal: one place for open to-dos; the owner is reminded of them at a moment
  they already think about what's left (finishing a branch).
- Non-goal: changing the harness's memory system; tracker changes.
- Anti-goal: context pollution — nothing new is injected at session start.
  Anti-goal: an extra decision at capture time (no scope flag on `add`).

## Approaches

- Two places (`add --project`): agent decides scope at capture; misfiles.
- Tickets for project items: needs a tracker in every repo; falls back to memory.
- **Chosen: one list + a "keep" disposition.** The owner decides scope at the
  sort; kept items leave their branch and are shown as a reminder at every
  finishing. Startup display was rejected as context pollution.

## Design

1. `followup keep N` re-tags open item N `[*]` (`*` is not a valid branch
   name, so no branch can claim it). `list --kept` prints open kept items;
   `list --orphaned` never includes them; `done N` closes them as usual.
2. Follow-up sort: fourth disposition **keep** (`FOLLOWUP keep N`); the
   discard path's keep uses it too.
3. Reminder: the sort message ends with "Still kept (no action needed):" and
   the kept items' text; the reply may act on them ("7 drop"). With no branch
   items, finishing shows the reminder in one line and continues without
   waiting.
4. Rule: the using-superpowers routing line for "note that for later" adds
   that open to-dos never go into memory files.

## Terms

CONTEXT.md: **Kept follow-up** (new); Follow-up sort gains keep.

## Left to the builder

Test layout; wording of the reminder.
