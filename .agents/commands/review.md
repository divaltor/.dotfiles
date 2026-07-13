---
description: Strict structural review of a diff vs an optional base ref (e.g. /review main, /review origin/dev). Defaults to working tree vs HEAD. Flags abstraction, spaghetti, and size regressions with a standardized verdict.
model: openai/gpt-5.6-terra
subtask: true
variant: high
---

# Target

Review base: `$ARGUMENTS` (empty → uncommitted + staged changes vs `HEAD`).

Resolve the diff yourself with `git`:

- If a base ref is provided above, review `git diff <base>...HEAD` (changed files via `git diff --name-only <base>...HEAD`).
- Otherwise review `git diff HEAD` (changed files via `git diff --name-only HEAD`).

# Mission

Perform a deep code-quality audit of the diff above.
Behavior must be preserved. Push hard for *code-judo*: restructurings that delete whole branches, helpers, modes, or layers — not refactors that merely shuffle complexity around. Prefer the version that, in hindsight, feels inevitable.

Before reviewing, read `AGENTS.md` (and any nested `AGENTS.md`) and `README.md` for project-specific conventions, allowed/forbidden imports, naming, and architectural rules. Treat anything stated there as binding. Project-specific standards belong in those files, not in this command.

# Standards (each is a presumptive blocker)

1. **Ambition** — call out any place where a reframing would *delete* complexity, not polish it.
2. **File size** — a file crossing 1000 lines because of this PR is a blocker unless justified.
3. **Spaghetti** — new ad-hoc `if`s, flags, or special cases bolted into unrelated flows are a design problem, not a nit.
4. **Direct over magical** — no thin wrappers, identity abstractions, or pass-through helpers that add indirection without clarity.
5. **Type / boundary cleanliness** — no gratuitous optionality, `any`/`unknown`/casts, or silent fallbacks papering over an unclear invariant.
6. **Right layer** — feature logic stays out of shared paths; reuse canonical helpers instead of bespoke duplicates.
7. **Atomicity & parallelism** — independent work should run in parallel; related updates should not leave half-applied state.
8. **Project conventions** — anything documented in `AGENTS.md` or `README.md` is a hard rule. Violations are blockers.

# Output Contract (REQUIRED — exact format)

Produce one markdown document with these sections in this order. **Be terse**. No preamble, no recap of the diff.

```markdown
## Verdict: <READY | NEEDS_ATTENTION | NEEDS_WORK>
<one sentence — what the author must do next>

## Blockers (N)
1. **[CATEGORY]** `path/to/file:LINE` — <≤2-sentence problem statement>
   - **Fix:** <concrete, smallest correct change>
   - **Why it matters:** <one sentence>

## Suggestions (N)
1. **[CATEGORY]** `path/to/file:LINE` — <≤1-sentence problem>
   - **Fix:** <one line>

## Nits (N)
- `path:LINE` — <one line>

## Clean
- <bullet list of areas explicitly checked and found clean: file-size, types, layering, tests, conventions>
```

**Rules for the output:**

- `CATEGORY` ∈ `STRUCTURE | SPAGHETTI | SIZE | BOUNDARY | TYPES | LAYER | ATOMICITY | CONVENTION`.
- A **Blocker** matches Standards 1–8. A **Suggestion** is a real improvement that isn't blocking. A **Nit** is cosmetic.
- Max 5 Blockers, max 7 Suggestions, max 10 Nits. If you'd exceed the cap, keep only the highest-impact items — the human cannot triage a wall of text.
- Every finding MUST cite `file:line`. No finding may quote more than 8 lines of code.
- No emojis, no congratulations, no restating the diff. Don't say "Overall the PR looks good" — the Verdict line says that.
- If a Blocker has a plausible code-judo fix, the **Fix** field must describe the *structural* alternative, not a localized patch.

# Verdict rule

- **READY** — zero Blockers, no Standards 1–8 violation visible.
- **NEEDS_ATTENTION** — Suggestions worth addressing, but no Blocker.
- **NEEDS_WORK** — ≥1 Blocker, or any Standards 1–8 violation, or failing project conventions.

Default to NEEDS_WORK when in doubt. "It works" is not approval.
