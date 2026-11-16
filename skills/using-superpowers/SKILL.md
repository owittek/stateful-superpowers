---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.

### Routing by intent

- **Ticket work ("work on #12", a ticket URL or ref) with `docs/agents/issue-tracker.md` present** → `superpowers:writing-plans` (its Ticket Intake); no config → route by intent below
- **"What's next" / "what's open"** → run `{{SKILLS_DIR}}/finishing-a-development-branch/scripts/tracker frontier ticket` and `... frontier followup` (if that path is not absolute, the helper is in the `finishing-a-development-branch` skill's `scripts/` directory), from the working tree (backend not supported by it → the same query by hand per the config); show both lists by title, your human partner picks, then `superpowers:writing-plans` with that ref. No `docs/agents/issue-tracker.md` → say no tracker is configured.
- **New feature / new behavior** → `superpowers:brainstorming`
- **Restructure existing code, behavior preserved (refactor)** → `superpowers:improving-architecture`
- **Bug / regression** → `superpowers:systematic-debugging`
- **Document or comment a module (interfaces, fields, non-obvious internals)** → `superpowers:commenting-modules`
- **"Note that for later" / "follow up on X"** → no skill: run `{{SKILLS_DIR}}/finishing-a-development-branch/scripts/followup add "<X>"` (if that path is not absolute, the helper is in the `finishing-a-development-branch` skill's `scripts/` directory), from the working tree you're executing in, and reply "Noted as follow-up N."

`brainstorming` and `improving-architecture` are **peer front-ends** — both interview the user, both terminate into `writing-plans`. Pick by new-behavior vs preserve-behavior; do not route refactors through brainstorming.

Both front-ends share the same engines: `grilling` (the interview and domain capture; brainstorming uses capture mode only) and `designing-modules` (module and seam design). Engines are invoked by front-ends, not routed to — don't send a task to one directly unless the user names it.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Claude Code: `references/claude-code-tools.md`
- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`
- Hermes Agent: `references/hermes-tools.md`
- Muse: `references/muse-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
