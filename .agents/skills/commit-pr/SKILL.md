---
name: commit-pr
description: "Write, review, or improve Git commit messages, GitHub PR descriptions, and PR comments that explain a change. Use when the user asks for a commit message, a PR description, or a PR comment/reply."
---

# Commit Messages (and PR text)

Write so a reader learns **why** the change happened, not what changed.
The diff shows *what*; the text supplies only the *why*. In a PR or comment,
put the main why first (BLUF), then only the facts the code cannot show.

This file covers commit messages and the rules every artifact shares. For a
PR description or a PR comment, also read `references/pull-requests.md`.

## Body or no body (decide first)

**Default: no body.** A PR ships with its title only; a commit ships
subject-only. Most changes are obvious from the title and the diff, and a
body on an obvious change teaches reviewers to skip bodies, including the
ones that matter.

Write a body only when a teammate who reads the title and the diff would
still ask "why?", and the answer is a fact neither of them shows. That
means at least one of these is true:

- A bug fix whose cause is not in the title (the input, state, or upstream
  change that broke it).
- A choice a reviewer would question: a rejected alternative, a tradeoff,
  an approach that looks wrong but is not.
- A required order outside the diff: deploy, migration, backfill, another
  repo's PR first.
- A number or constraint from outside the repo: a measurement, a cost, a
  vendor limit, a fact about the data.
- A risk the reader can cause or miss: silent data loss, an outage, an
  irreversible step.

None is true → no body. Diff size does not decide it: a one-line timeout
change with a measured reason needs a body, a 300-line rename does not.

Asking for a PR or a commit is not asking for a body. Write a body for an
obvious change only when the user explicitly asks for a description, and
then only the one sentence a reviewer could not guess.

A body never consists of:

- the title or the diff restated ("The list now starts collapsed").
- what still works ("The chevron still expands and collapses it").
- the history of the code ("#11 made the list collapsible").
- how it was checked (browser clicks, tests, lint).
- team knowledge every reviewer has (naming prefixes, which sensors depend
  on a DAG).

Wrong, for `Collapse Abacus sidebar modules by default`, a one-line diff
that removes `defaultOpen`: three paragraphs saying the list starts
collapsed, the chevron still works, #11 had set `defaultOpen`, and a
browser check passed. Every sentence is the title, the diff, or a check.
Right: no body.

## Route by artifact

```text
What are you writing?
├── Commit message     → Body gate → Match the repo → Why-only rule → Plain words → Commits → Verify
├── PR description     → Body gate → Match the repo → Why-only rule → Plain words → references/pull-requests.md
└── PR comment / reply → Why-only rule → Plain words → references/pull-requests.md
```

For a PR description or comment, read `references/pull-requests.md` before
writing: it holds BLUF, the shape tree, the layouts, and the PR checklist.
Commits never need it.

When the body gate says no body, stop there: write the subject or title
and nothing else.

## Match the repo first

Before writing, read local history:

```bash
git log -20 --format='%s%n%b---'
```

History decides **format**: subject dialect (plain imperative vs `type:`
prefixes), trailer and ticket-reference style, wrapping, and language.
This skill decides **content**: the why-only rule always applies, even when
history is full of what-narrating bodies. Use the format defaults below only
when history gives no signal. Recent PR descriptions do not override the
bold, shape, or stack rules either: many were written by an older version
of this skill, so copying them repeats its mistakes.

## Why-only rule (all artifacts)

Allowed: facts the diff cannot show — failure cause, user or cost impact,
rejected alternative, tradeoff, external constraint.

Forbidden: any sentence a reader could reconstruct from the diff. That
includes imperatives like `Treat / Use / Add / Keep / Split / Pin / Switch`,
`We now…`, and a tool, model, or flag name stated as an instruction. State
facts instead: "Psycopg 3 exposes the first result…", not "Use one
result-producing statement…".

One exception in a PR or comment: a single "now" sentence that states the
observable result in the reader's terms, such as "It now reports
`invalid-argument-type`" or "A typical pod now needs ~260 MB". It names
what the reader will see, never what the code does to get there. Ruff, ty,
and Ghostty use exactly one such sentence after the symptom, because the
reader needs the outcome and the diff shows only the mechanism.

The one imperative allowed is a required step the diff cannot show, such
as a deploy order. In a PR it goes in the step-order arrow line, never in
the first sentence.

Quoting the one line of code that decides the behavior is evidence, not a
restatement, when the sentence above it gives the why (layout B below).

**Subtraction test (mandatory before output):** cover the diff and read the
text alone. If a sentence lets you guess what the code does, delete it. If
nothing remains, a commit ships subject-only and a PR ships with no body.

Mention the fix only as
`because + outside-diff fact`, never as an action. The last sentence states
the cost of doing nothing, why the alternative loses, or the tradeoff —
never the change restated as an action.

Good: "DuckDB 1.5 rejects the virtual-hosted URL because it does not match
the wildcard certificate, which failed `convert_details` after the
upgrade." Wrong: "Configure the DuckDB S3 secret to use path-style URLs." —
that is the diff, spoken aloud.

## Plain words (all artifacts)

Readers spot generated text from repeated habits, not one mistake. Strip
these from every commit body, PR description, and comment.

- No em dashes. End the sentence or use a comma.
- Plain verbs: use, help, show, improve. Not leverage, utilize, facilitate,
  enhance, ensure, streamline. Write "is" and "has", not "serves as",
  "features", or "boasts".
- No promotional adjectives (robust, seamless, comprehensive, critical).
  Give the number or the consequence instead.
- No trailing clause that adds an unproven conclusion ("…, ensuring
  correctness", "…, improving performance"). Cut it, or give it its own
  sentence with evidence.
- No "not just X, but Y". State Y. Count the real items instead of padding
  a list to three.
- No contrast or scope disclaimers: "X, not Y", "deploys the prerequisites,
  not the fix", "This PR does not…", "Merging this PR…", "This PR adds…".
  They describe the PR instead of the reason. State the reason; work left
  for later appears only as a step in the arrow line.
- No label lead-ins that restate their line: `Note:`, `Merge order:`,
  `Checked locally:`, `**Impact:**`. A label turns prose into a form and
  says nothing the sentence does not. Write the sentence.
- Straight quotes in Markdown and commit text.

## Commits

```text
Capitalize the subject, imperative, no final period

Optional body, max 3 lines: the cause, then the cost of doing nothing.
Wrap at 72 characters.

Resolves: #123
```

**Subject**

- Target 50 characters; hard limit 72. Git tools and GitHub truncate past
  72. A subject that will not fit in 50 usually means the commit does too
  much — prefer splitting into atomic commits.
- Imperative test: the subject completes "If applied, this commit will
  ___." Good: `Fix race in cache eviction`. Wrong: `Fixed race…`,
  `Fixing race…`. The imperative ban in the why-only rule applies to the
  body, not the subject.

**Body**

- Only when the body gate passes. Otherwise subject-only.
- Max 3 lines total, including an optional limit line. Mechanism,
  measurements, and deploy order belong in the PR.
- Terse voice: answer first, no recap, fragments fine, articles optional.
  Never drop not / never / only / except. Code names and numbers stay
  exact.
- A before/after number is one arrow with unit and scope written once:
  `Rows read (8-day test): 18.6B → 94M`. In a commit, an arrow means only
  "becomes".
- Limit line only when a reader would assume more was fixed:
  `Not covered: adserver_api_event, not sorted by date.`
- No diagrams. A fenced block is noise in plain-text `git log`, and it
  breaks the 3-line limit.

**Trailers**, after a blank line:

- Related issues when they exist (`Resolves: #123`, `Related: #612`, or the
  repo's own style).
- No PR link: GitHub already shows the PR for every commit.
- An agent thread URL only when you know it exactly and teammates can open
  it. Amp adds `Amp-Thread-ID` itself when it commits, so never write one.
  OpenCode sessions are private by default: add `Session: <share URL>` only
  after `/share` returned that URL. Never guess or build a URL.
- Never add attribution footers or `Co-Authored-By` unless the user asks.

```text
Use raw date ranges in sp_monitoring_and_dq

DATE(time_stamp) hides the sort key, so Redshift reads every block of
events_mastertable. Rows read (8-day test): 18.6B → 94M.

Related: #612
```

## Posting mechanics

Pass multi-line text with real newlines, never `\n` escapes. An inline
`"para1\n\npara2"` stores literal backslash-n text, which renders as
visible `\n\n`. Use a quoted heredoc:

```bash
git commit -F - <<'EOF'
Subject line

Body paragraph wrapped at 72 characters.

Resolves: #123
EOF
```

## Verify

Run this checklist silently. Never print it, its results, or a
"verified / checks passed" note in the response: the user asked for the
text, and a list of ticks only adds reading. Output the final text alone.
Mention a check only when a rule could not be met and the user must decide.

1. Subject: imperative, capitalized, no final period, ≤50 target, ≤72 hard.
2. Blank line after the subject.
3. Body absent unless the body gate passes; then ≤3 lines wrapped at 72,
   no diagram.
4. Subtraction test passes; last sentence is not the change as an action.
5. Trailers: issues and shared-thread URL only, no PR link, no attribution.
6. Real newlines, no literal `\n`.

When reviewing existing text, report only the broken rules, with a
corrected version. When asked to review history, a cheap pass for the hard
limit:

```bash
git log --format=%s | awk 'length > 72'
```

Empty output means every subject fits.
