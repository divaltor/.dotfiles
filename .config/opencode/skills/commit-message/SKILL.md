---
name: commit-message
description: "Write, review, or improve Git commit messages and descriptions for Jira issues, pull requests, changelogs, release notes, and similar change records. Use when the user asks for one of these artifacts."
---

# Change Descriptions

Write change descriptions so a reader learns **why** a change happened, not just
what changed. A diff shows *what*; the description must supply the *why*.
Apply the commit-message rules only to Git commit messages.

Sources: cbea.ms/git-commit and tbaggery.com/2008/04/19/a-note-about-git-commit-messages.

## Match the repo first

Before writing, read the local history and follow its conventions:

```bash
git log -20 --format='%s%n%b---'
```

Match the subject dialect (plain imperative vs `type:` prefixes), trailer and
ticket-reference style, wrapping habits, and language. Fall back to the
defaults below only when history gives no signal.

## Template

The template encodes the mechanical rules; the annotations carry the judgment.

```text
Capitalize the subject, ~50 chars, imperative, no final period

How it worked before, what was wrong with that, and why this fix
is the right one. Wrap every line at 72 characters. Leave out how —
the code shows that.

- Bullets are okay: hyphen, single space
- Blank lines between multi-line bullets

Resolves: #123
See also: #456, #789
```

- Imperative test: the subject must complete "If applied, this commit will
  ___." Good: `Fix race in cache eviction`. Wrong: `Fixed race...`,
  `Fixing race...`. Body mood is free.
- Skip the body only when the change is trivially self-explanatory
  (`Fix typo in installation guide`).
- If the subject won't fit in ~50 characters, the commit probably does too
  much — prefer splitting into atomic commits.
- Never append generated attribution footers or `Co-Authored-By` trailers
  unless the user asks.

## Verify

Review an existing or drafted message against, in order:

```text
imperative → ≤72-char subject → capitalized → no period → blank line
→ 72-wrapped body → explains why, not how → references at bottom
```

Report only the broken rules, with a corrected version. When reviewing
history, the cheap mechanical pass is:

```bash
git log --format=%s | awk 'length > 72'
```

Empty output means every subject fits the hard cap.

## Other change records (PRs, Jira, changelogs)

Apply the same what/why priority without Git formatting:

1. One-line summary in plain, imperative-style language.
2. The problem and the reason the change was needed.
3. The approach plus any non-obvious tradeoffs or side effects.
4. Links to issues, prior discussion, or follow-ups.

For PR descriptions, use one or two short plain-text paragraphs by default. Do
not add Markdown headings, checklists, or generic sections such as `Summary`,
`Why`, `Validation`, or `Test plan`. Do not include routine validation details.
Use a structured PR format only when the user explicitly requests one.

## Diagrams (only when shape helps)

The default stays prose-only. Add a diagram only when the *why* has visual
shape — a before/after flow, state change, request lifecycle, or performance
comparison — and the picture says it better than the paragraph. One diagram
maximum, placed after the why-paragraph. Pick the shape with the
`ascii-diagrams` skill, and skip the diagram when prose covers it in two
lines.

Surface decides the format:

- **Commit bodies and git notes** (terminal, no Markdown): ASCII in a fenced
  `text` block. Keep every line ≤72 columns and never re-wrap it — wrapping
  destroys alignment. Never in the subject.
- **PR descriptions** (GitHub): Mermaid renders natively, but prefer ASCII in
  a `text` block whenever it fits the explanation better — it survives
  copy-paste, diff review, and plain-text renderers. Use Mermaid only for
  shapes that need rendering, such as branching graphs or gantt charts.
