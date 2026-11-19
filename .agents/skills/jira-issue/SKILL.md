---
name: jira-issue
description: "Write, review, or improve Jira issues in plain simple English, free of AI-writing tells and first-person voice. Use when the user asks for a Jira ticket, Jira issue, or Jira description."
metadata:
  scope: local
---

# Jira Issues in Plain English

There is no diff attached. Describe the problem and the wanted outcome so any
reader (dev, support, non-native speaker) understands fast. Never describe the
implementation. That comes later, in the commit or PR.

## Default shape: short, freeform paragraphs

Default: two short paragraphs, about 80–120 words total, excluding the title and links. A simple issue can use one paragraph. Expand only when the user asks for detail or a shorter version would omit a requirement.

Use a soft BLUF: open with what needs attention and its practical impact, in a calm, factual sentence. Follow with the verified cause, if known, and the wanted outcome. Avoid urgency, blame, and formal executive-summary wording.

Keep only the main details. Link investigation history, logs, supporting measurements, and implementation plans instead of copying them into the issue. Keep a date or number only when it explains the scope, cause, or impact.

Split the body into more paragraphs when it grows past about 120 words or a
paragraph covers more than one topic. Give each paragraph one job, in this
order, and skip the ones that have nothing to say:

1. Problem and impact: what happens and who is affected.
2. Cause: why it happens, if verified.
3. Evidence: measurements, test results, cost of the change.
4. Wanted outcome: the state the system should reach.

A paragraph with one sentence is fine. A wall of text is not.

- No headers by default. Applies to text you write, not to this file. Never
  use `#` or `##`. Use `####` only when a long issue cannot stay readable
  without a split, max 1–2 per issue.
- No PM boilerplate: no `As a… I want… So that…`, no `Summary / Goals /
  Acceptance Criteria / Test Plan` sections, no checklists, no Gherkin
  (`Given/When/Then`) unless the user explicitly asks.
- No implementation orders in the body ("Add X…", "Configure Y…", "Use Z…").
  State the problem and the wanted outcome. The fix belongs in the code. The
  title is the one place for an imperative verb, and only for the outcome.
- Add at most one plain check sentence if the wanted outcome is not already clear. Do not repeat the outcome as acceptance criteria.
- Title: name the open work, never a finished state. A present-tense
  statement of the wanted state reads as already done in a backlog. Use one
  of two forms:
  - Bug: the current wrong behavior. Good: "Login page rejects correct
    passwords after the upgrade".
  - Change: an imperative outcome verb (Show, Remove, Move, Reduce) plus the
    result, with no implementation detail. Good: "Show task start latency on
    the Airflow dashboards".
  - Wrong: "Airflow dashboards show task start latency" (reads as done).
    Wrong: "As a user I want to log in so that…".

## Formatting

Use formatting only when it helps a reader scan. Plain paragraphs stay the
default.

- Backticks for code names, paths, config keys, commands, image tags, and
  error codes: `workflow/lib`, `KubernetesPodOperator`, `error 500`.
- Bold for at most one or two load-bearing facts per issue, usually the key
  number or the wanted outcome. Never bold whole sentences.
- A short flat bullet list for three or more parallel facts, such as
  measurements or affected DAGs. Each bullet is a full simple sentence or a
  `label: value` pair. No nested lists.
- A small table for before/after numbers with two or more metrics.
- A code block for a short log line or error message. Link full logs.

Do not format: two facts (write a sentence), the cause chain (it reads as
prose), or anything the reader only needs once.

## Voice: third person, no author

A ticket outlives its author and moves between people. It speaks about the
system, the people it affects, and the benefit, never about the writer.

- No `I`, `we`, `our`, `us`, `my`. Not in the title, not in the body.
- The subject of each sentence is the system, a component, a measurement, or
  the affected group: "Task pods compile…", "The image build…", "DAG owners
  wait…".
- Make three things visible: who or what is affected, why it matters (cost,
  delay, risk, failure), and what the wanted state gives.
- State the wanted outcome as a property of the system with "should", so it
  reads as a target, not a fact: "Task pods should start without compiling
  packages." Not "Task pods start…" (reads as done), "I want…", "We need…",
  "We should…". Never open the outcome with "After this ticket…".
- Turn first-person estimates and tests into facts with their source: "We
  estimate 13 s" → "The estimated median is about 13 s." "Our test showed…" →
  "A local test of the prod image showed…".
- Name the owning thing instead of "our": "our image build" → "the Airflow
  image build", "our library code" → "the `workflow/lib` code".

This rule overrides the "use I" and "have a reaction" advice in
`emil-unslop-writing`. A ticket states facts. It has no opinion voice.

## STE-mini

Same subset as the `commit-pr` skill, without its subject exception (Jira has
no imperative-fragment subject, so every line is a full simple sentence):

- Active voice, simple present or simple past. No complex tenses. Name the
  actor: "the scheduler drops the task", not "the task is dropped".
- Short sentences: max 25 words for descriptions, max 20 for steps. Shorter
  is better. Split long sentences.
- One idea per sentence. One instruction per sentence.
- One term per thing. No synonyms, no jargon, no idioms. Reuse the same word.
- No `-ing` clauses to carry order or cause. Write two plain sentences instead.
- Short paragraphs, one topic each, at most three sentences.

Good: "The CSV export fails after the upgrade. The server returns error 500
because the date format changed. Exports should produce the old file format
again."

Wrong: "We're leveraging the new infra, facilitating a seamless export
experience by configuring the pipeline…". First person, slop words, `-ing`
chain, no clear problem.

## Slop sweep

Apply the `emil-unslop-writing` pass to every ticket: words, then sentences,
then punctuation, then claims. The tells that show up most in tickets:

- Model words. Swap for the plain word: leverage/utilize → use, facilitate →
  help, enhance → improve (or the exact change), crucial/critical → name the
  consequence, seamless/robust → delete, additionally → also, numerous →
  many, in order to → to, due to the fact that → because.
- Costume verbs. "serves as", "offers", "features" → "is", "has".
- Adverbs and intensifiers. "significantly slower" → the number. "very
  flaky" → the failure rate.
- Stacked hedges. One "may" at most. A measured number needs no hedge.
- Rule of three. Count the real items. Two causes get two sentences.
- "Not just X, but Y". State Y.
- Trailing `-ing` conclusions. "…, ensuring reliability" → delete, or give the
  point its own sentence with evidence.
- Unsourced claims. "It is known that…", "Users report…" → name the source,
  link it, or cut it.
- Generic endings. "This will greatly improve the experience." → the
  specific number or delete.
- Punctuation. No em dashes; use periods or commas. No mid-sentence colon
  connectors. No bold inline headers. No emojis. Straight quotes.

## Verify

In order:

```text
title names open work (bug behavior or imperative outcome, never a done state) → soft BLUF → main details only → wanted outcome, no fix
→ who is affected and why it matters are visible
→ no I/we/our/us/my anywhere
→ about 80–120 words unless more detail is needed
→ one topic per paragraph, split when long
→ formatting only where it aids scanning (backticks, ≤2 bold, flat lists, small tables)
→ STE-mini sentences → slop sweep clean (no model words, no em dashes)
→ no headers (#{1,2} absent, #### only if needed)
→ no PM template → no literal \n escapes
```

Report only the broken rules, with a corrected version. Readability test:
cover the title, read the body alone. A stranger must grasp the problem, who
it affects, and the wanted outcome without asking what to build. Final test:
which sentence would make a reader suspect a model wrote it? Fix it.

## Posting mechanics

Jira text is pasted or posted as-is. Use real newlines, never `\n` escapes.
`"para1\n\npara2"` renders as visible `\n\n`. Use only the Markdown from the
Formatting section: backticks, bold, flat lists, simple tables, and code
blocks. The Jira editor converts these on paste. Put a blank line between
paragraphs and before a list or table.
