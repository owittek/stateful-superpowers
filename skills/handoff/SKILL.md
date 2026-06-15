---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up. Use as a context-hygiene compaction tool when a long exploration/planning/orchestration session is bloating - especially at the build -> review/refactor/adjust boundary - to produce a clean resume doc so a fresh session starts lean.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS - not the current workspace.

Primary use: compact a long exploration / planning / orchestration session — especially at the **build → review/refactor/adjust boundary** — into a clean resume doc so a fresh session starts lean. Reference CONTEXT.md and docs/adr/ by path (do not duplicate them); the "suggested skills" section should point at the superpowers skill that resumes the work (e.g. improving-architecture, systematic-debugging, receiving-code-review).

Include a "suggested skills" section in the document, which suggests superpowers skills that the agent should invoke to resume the work (in `Use superpowers:<skill>` form), e.g. `Use superpowers:improving-architecture`, `Use superpowers:systematic-debugging`, `Use superpowers:receiving-code-review`.

Do not duplicate content already captured in other artifacts (PRDs, plans, CONTEXT.md, ADRs in `docs/adr/`, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
