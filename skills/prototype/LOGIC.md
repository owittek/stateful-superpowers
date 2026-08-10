# Logic Prototype

A single, self-contained HTML file — a **shareable demo** — that lets anyone drive a state model by clicking buttons. Use this when the question is about **business logic, state transitions, or data shape** — the kind of thing that looks reasonable on paper but only feels wrong once you push it through real cases.

Because it's one file with nothing to install, you can hand it to a non-developer — a designer, a PM, a domain expert — and let them feel the model for themselves. So it speaks their language, not the code's.

## When this is the right shape

- "I'm not sure if this state machine handles the edge case where X then Y."
- "Does this data model actually let me represent the case where..."
- "I want to feel out what the API should look like before writing it."
- Anything where someone wants to **press buttons and watch state change**.

If the question is "what should this look like" — wrong branch. Use [UI.md](./UI.md).

## Process

### 1. State the question

Before writing code, write down what state model and what question you're prototyping. One paragraph, at the top of the demo (in a visible intro, not just a comment). A logic prototype that answers the wrong question is pure waste — make the question explicit so it can be checked later, whether the user is watching now or returning to it AFK.

### 2. Isolate the logic in a portable module

Put the actual logic — the bit that's answering the question — in a single `<script>` block written as a small, pure module. The right shape depends on the question:

- **A pure reducer** — `(state, action) => state`. Good when actions are discrete events and state is a single value.
- **A state machine** — explicit states and transitions. Good when "which actions are even legal right now" is part of the question.
- **A small set of pure functions** over a plain data type. Good when there's no implicit current state — just transformations.
- **A class or module with a clear method surface** when the logic genuinely owns ongoing internal state.

Pick whichever shape best fits the question being asked, *not* whichever is easiest to wire to a page. Keep it pure: no DOM, no `document`, no button handlers reaching inside it. The page calls into it; nothing flows the other direction.

Purity is what makes the answer trustworthy, not what makes the code reusable. **The validated _shape_ — this reducer, these states, that method surface — is what goes back into the design; the code itself is discarded** (see the Guardrails in [SKILL.md](./SKILL.md)). Logic tangled into the page can't be judged on its own, so the demo would answer a question about the demo instead of about the model.

### 3. Build the shareable HTML file

One file, plain HTML/CSS/JS — no framework, no bundler, no server, everything inline so it opens by double-click. Write it to the OS temp directory, never into the repo: resolve the temp dir from `$TMPDIR`, falling back to `/tmp` (or `%TEMP%` on Windows), and write to `<tmpdir>/prototype-<topic>-<timestamp>.html` so each run gets a fresh file.

Write it for a non-developer. Every label is in **domain language**, not code — buttons and state read like the business, not the reducer. Explain in plain words what's happening.

Lay it out with a clean hierarchy, top to bottom:

1. **Title and one-line explanation** of what this demo lets you explore (the question from step 1).
2. **Current state** — the full relevant state, rendered as a readable panel (labelled fields, not a raw JSON dump), re-rendered after every click so the change is visible. Where it helps a non-developer follow, call out what just changed.
3. **Free-play buttons** — one button per action, always available, so anyone can poke at the model in any order. Each click dispatches its action and re-renders the state.
4. **Guided walkthroughs** — a set of **scenarios**, one per tab. Each tab holds a short plain-language description of the scenario — the situation it sets up and what to watch for — and underneath it, the ordered **buttons to press** for that scenario. Each step is a real button: clicking it performs that action and moves to the next step. Starting a walkthrough resets to a known initial state so the scenario runs the same way every time.

Choose scenarios that demonstrate the awkward cases — the happy path, a tricky edge case, an attempt at something that should be illegal — the ones hard to reason about on paper.

Keep it beautiful but restrained: clean typography, generous spacing, one accent colour. No animations, no gimmicks — nothing that competes with the state and the buttons.

### 4. Hand it over

Open it for the user — `xdg-open <path>` on Linux, `open <path>` on macOS, `start <path>` on Windows — and tell them the absolute path. Running as a dispatched subagent (Guardrail 5)? The absolute path rides back with the answer: the scratch code stays behind, but the main session can't point the user at a file it never saw. They'll click through the walkthroughs and free-play whenever they get to it; the interesting moments are when they say "wait, that shouldn't be possible" or "huh, I assumed X would be different" — those are the bugs in the _idea_, which is the whole point. If they want new actions or a new scenario, add them. Prototypes evolve.

### 5. Capture the answer, discard the demo

The _answer_ is the only thing worth keeping. Capture the verdict and the question it settled where the design lives — the spec, `CONTEXT.md`, or an ADR — then discard the file. The logic-specific mapping: the validated reducer / machine / function set is described in the design as the shape to build; the HTML shell is deleted, unread by anyone again.

## Anti-patterns

- **Don't add tests.** A prototype that needs tests is no longer a prototype.
- **Don't wire it to the real database.** Use in-memory state unless the question is specifically about persistence.
- **Don't generalise.** No "what if we wanted to support X later." The prototype answers one question.
- **Don't blur the logic and the page together.** If the pure module references the DOM, `document`, or button handlers, the model can't be judged on its own.
- **Don't reach for a framework, bundler, or server.** One file the user double-clicks; a React app or a dev server defeats "shareable".
- **Don't write it into the repo, and don't commit it.** It lives in the temp dir and dies there — the design carries the answer forward.
