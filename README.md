# Superpowers

Superpowers is a complete software development methodology for your coding agents, built on top of a set of composable skills and some initial instructions that make sure your agent uses them.

## Quickstart

Give your agent Superpowers — see [Installation](#installation).

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do. 

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. 

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY. 

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for Claude to be able to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.


## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my opensource work](https://github.com/sponsors/obra).

Thanks! 

- Jesse


## Installation

This is a fork. Install it from this repository — it is not published to the upstream
Superpowers marketplaces (official Claude/Codex/Cursor/Copilot marketplaces).

### Claude Code

- Register the fork marketplace and install the plugin:

  ```bash
  /plugin marketplace add owittek/stateful-superpowers
  /plugin install stateful-superpowers@stateful-superpowers-dev
  ```

### Gemini CLI

- Install the extension from the repo:

  ```bash
  gemini extensions install https://github.com/owittek/stateful-superpowers
  ```

### OpenCode

- Tell OpenCode:

  ```
  Fetch and follow instructions from https://raw.githubusercontent.com/owittek/stateful-superpowers/refs/heads/main/.opencode/INSTALL.md
  ```

- Detailed docs: [docs/README.opencode.md](docs/README.opencode.md)

### Other harnesses (Codex, Cursor, Factory Droid, GitHub Copilot)

The repo ships plugin manifests for these (`.codex-plugin/`, `.cursor-plugin/`, hook
configs), so it runs on the same harnesses as upstream — but the fork is not on their
published marketplaces. Install from source by pointing the harness at this repository
(`https://github.com/owittek/stateful-superpowers`) using that harness's "install a
plugin from a Git repo" flow.

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves design document.

2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.

3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps.

4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes in batches with human checkpoints.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration** 
- **brainstorming** - Socratic design refinement
- **grilling** - Relentless one-question-at-a-time design interview, capturing terms into CONTEXT.md and decisions into docs/adr/
- **prototype** - Build a throwaway probe to answer one design question discussion can't settle
- **improving-architecture** - Find deepening and refactoring opportunities, informed by CONTEXT.md and docs/adr/
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Batch execution with checkpoints
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system
- **zoom-out** - Step back for broader context and a higher-level perspective on a section of code
- **handoff** - Compact a long session into a clean resume document for a fresh agent to pick up
- **syncing-context** - Bootstrap or re-sync a repo's CONTEXT.md glossary from its code and docs

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read [the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/).

## Credits

Stateful Superpowers stands on the shoulders of giants:

- **[Superpowers](https://github.com/obra/superpowers)** by [Jesse Vincent](https://blog.fsck.com) and [Prime Radiant](https://primeradiant.com) — the framework spine this fork extends: the composable skill system, the brainstorm → plan → subagent-driven-development workflow, and the bootstrap that makes skills trigger automatically.
- **[Skills for Real Engineers](https://github.com/mattpocock/skills)** by [Matt Pocock](https://www.aihero.dev) — the engineering skills whose mechanics we absorbed: the grill-with-docs interview discipline (`grilling`), `improving-architecture`, `prototype`, `zoom-out`, `handoff`, and the `CONTEXT.md` glossary + `docs/adr/` domain substrate.

This fork's own contribution is the synthesis — folding that stateful domain-model discipline into the Superpowers spine without disturbing its workflow — with more of our own ideas layered on as the project grows.

## Contributing

The general contribution process for Superpowers is below. Keep in mind that we don't generally accept contributions of new skills and that any updates to skills must work across all of the coding agents we support.

1. Fork the repository
2. Switch to the 'dev' branch
3. Create a branch for your work
4. Follow the `writing-skills` skill for creating and testing new and modified skills
5. Submit a PR, being sure to fill in the pull request template.

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Superpowers updates are somewhat coding-agent dependent, but are often automatic.

## License

MIT License - see LICENSE file for details

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

- **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
- **Issues**: https://github.com/obra/superpowers/issues
- **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions
