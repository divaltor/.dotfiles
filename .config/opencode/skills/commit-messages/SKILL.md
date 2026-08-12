---
name: commit-messages
description: Writes clear Git commit messages and change explanations using the seven-rule convention (imperative subject, 50/72 wrapping, why-not-how body). Use when the user asks to write, review, or improve a commit message, or to explain what and why a change was made.
---

# Commit Messages

Write commit messages and change explanations so a reader learns **why** a change
happened, not just what changed. A diff shows *what*; the message must supply the
*why* and the context that would otherwise be lost.

Sources: cbea.ms/git-commit and tbaggery.com/2008/04/19/a-note-about-git-commit-messages.

## The seven rules

1. Separate subject from body with a blank line.
2. Limit the subject line to ~50 characters (72 is the hard cap).
3. Capitalize the subject line.
4. Do not end the subject line with a period.
5. Use the imperative mood in the subject line.
6. Wrap the body at 72 characters.
7. Use the body to explain *what* and *why*, not *how*.

## Template

```
Summarize the change in ~50 characters, imperative mood

Explain the problem this commit solves and why this change is the right
fix. Describe how things worked before and what was wrong. Wrap the body
at 72 characters. Leave out how (the code shows that).

- Bullet points are okay, preceded by a hyphen and a single space
- Keep blank lines between multi-line bullets

Resolves: #123
See also: #456, #789
```

## Subject rules in practice

- Imperative test: the subject must complete "If applied, this commit will ___."
  - Good: `Fix race in cache eviction`, `Add retry to upload client`
  - Wrong: `Fixed race...`, `Fixes race...`, `Fixing race...`, `More cache fixes`
- Imperative matches Git's own messages (`merge`, `revert`, pull requests).
- If the subject is hard to keep short, the commit may be doing too much. Prefer
  atomic commits.

## Body rules in practice

- Skip the body only when the change is trivial and self-explanatory
  (e.g. `Fix typo in installation guide`).
- Focus on: how it worked before, what was wrong, why this solution.
- Do not narrate the diff line by line. Code and source comments cover *how*.
- Imperative mood is required only in the subject; relax it in the body.
- Put issue/PR references and trailers at the bottom.

## Writing explanations (not just commits)

When the user asks you to explain a change (PR description, changelog entry,
review summary), apply the same what/why priority:

1. One-line summary in plain, imperative-style language.
2. The problem and the reason the change was needed.
3. The approach and any non-obvious tradeoffs or side effects.
4. Links to issues, prior discussion, or follow-ups.

Keep it concise. The goal is to save the future maintainer (often the user) from
re-establishing lost context.

## Reviewing an existing message

Check, in order: imperative subject, ~50-char subject, capitalized, no trailing
period, blank line after subject, body wrapped at 72, body explains why not how,
references at the bottom. Report only the rules that are broken, with a corrected
version.
