---
name: jira-issue
description: "Write, review, or improve Jira issues in plain simple English. Use when the user asks for a Jira ticket, Jira issue, or Jira description."
---

# Jira Issues in Plain English

There is no diff attached. Describe the problem and the wanted outcome so any
reader (dev, support, non-native speaker) understands fast. Never describe the
implementation — that comes later, in the commit/PR.

## Default shape: freeform paragraphs

Default: two to four short paragraphs, freeform. What was found, the problem,
why it should be fixed, what you want instead. Like the user writes it, not a
product template.

- No headers by default. Applies to text you write, not to this file. Never
  use `#` or `##`. Use `####` only when a long issue cannot stay readable
  without a split, max 1–2 per issue.
- No PM boilerplate: no `As a… I want… So that…`, no `Summary / Goals /
  Acceptance Criteria / Test Plan` sections, no checklists, no Gherkin
  (`Given/When/Then`) unless the user explicitly asks.
- No implementation orders ("Add X…", "Configure Y…", "We should use Z…").
  State the problem and the wanted outcome; the fix belongs in the code.
- End with 1–3 plain check sentences only when they add clarity
  ("The page shows X. The old error is gone."). Plain sentences, not a
  checklist.
- Title: plain wanted outcome, not a user-story sentence. Good: "Login page
  rejects correct passwords after the upgrade". Wrong: "As a user I want to
  log in so that…".

## STE-mini

Same subset as the `commit-pr` skill, without its subject exception (Jira has
no imperative-fragment subject — every line is a full simple sentence):

- Active voice, simple present or simple past. No complex tenses.
- Short sentences: max 25 words for descriptions, max 20 for steps. Shorter
  is better. Split long sentences.
- One idea per sentence. One instruction per sentence.
- One term per thing. No synonyms, no jargon, no idioms. Reuse the same word.
- No `-ing` clauses to carry order or cause. Write two plain sentences instead.
- Short paragraphs, one topic each, max ~6 sentences.

Good: "The export fails after the upgrade. The server returns error 500
because the date format changed. I want the old file format back."

Wrong: "Leveraging the new infra, facilitating a seamless export experience
by configuring the pipeline…" — jargon, `-ing` chain, no clear problem.

## Verify

In order:

```text
plain title → problem stated → why it matters → wanted outcome, no fix
→ STE-mini sentences → no headers (#{1,2} absent, #### only if needed)
→ no PM template → no literal \n escapes
```

Report only the broken rules, with a corrected version. Readability test:
cover the title, read the body alone — a stranger must grasp the problem and
the wanted outcome without asking what to build.

## Posting mechanics

Jira text is pasted or posted as-is. Use real newlines, never `\n` escapes —
`"para1\n\npara2"` renders as visible `\n\n`. Keep Markdown minimal: plain
text survives Jira renderers best; code names in backticks are fine.
