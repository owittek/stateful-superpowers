# Kept Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A keep disposition so long-lived to-dos stay on the follow-up list, shown as a reminder at finishing.

**Architecture:** `followup keep N` re-tags an item `[*]`; `list --kept` reads them; finishing Step 0 and the sort doc use both; one routing-line rule.

**Tech Stack:** bash 3.2, awk, Markdown skills.

**Spec:** docs/superpowers/specs/2026-11-19-kept-follow-ups-design.md

## Global Constraints

- bash 3.2 compatible; no new dependencies.
- Kept tag is exactly `[*]`.
- Nothing new in `hooks/session-start`.

## Review Focus

- `keep` on a closed, kept or missing item → error, list unchanged.
- `--orphaned` must not list `[*]` items (else they're re-sorted forever).
- `list` (current branch) must not show kept items; `--all` does.
- A branch literally named `*` is impossible (git refuses) — no test.
- Item text containing `[*]` must not count as kept (tag position only).

---

### Task 1: `followup keep` and `list --kept`

**Files:** Modify `skills/finishing-a-development-branch/scripts/followup`; Test `tests/followup/test-followup-keep.sh`

**Interfaces:** Produces `followup keep N` (exit 0, prints nothing) and `followup list --kept` (open `[*]` lines; combinable with --open, implies open).

- [ ] Write test-followup-keep.sh: keep moves `[feat]`→`[*]`; `list` on feat no longer shows it; `list --kept` shows it from any branch; `--orphaned` after deleting feat excludes it; `done N --as dropped` closes it; keep on closed/kept/missing → non-zero, file unchanged; text "x [*] y" on a branch item isn't in `--kept`.
- [ ] Run: `bash tests/followup/run-tests.sh` → keep test FAILS.
- [ ] Implement `op_keep`, `--kept` in `op_list`, `*` excluded from orphan check, header + usage.
- [ ] Run: `bash tests/followup/run-tests.sh` → all PASS.
- [ ] Commit.

### Task 2: Sort, Step 0, routing rule, glossary

**Files:** Modify `skills/finishing-a-development-branch/SKILL.md` (Step 0, discard), `.../references/follow-up-sort.md` (§§ intro, 2, 3, 5, 6), `skills/using-superpowers/SKILL.md` (routing line), `CONTEXT.md`, `docs/upstream-sync.md`; Test `tests/followup/test-followup-keep-wiring.sh`

- [ ] Wiring test greps: Step 0 runs `list --kept`; sort doc offers keep with `FOLLOWUP keep N` and the "Still kept" reminder; discard path uses `FOLLOWUP keep`; routing line says never memory.
- [ ] Run → FAIL; edit docs; run → PASS; plus `tests/skill-size`, `tests/hooks` suites.
- [ ] Commit.
