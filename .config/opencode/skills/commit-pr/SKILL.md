---
name: commit-pr
description: "Write, review, or improve Git commit messages, GitHub PR descriptions, and PR comments that explain a change. Use when the user asks for a commit message, a PR description, or a PR comment/reply."
---

# Commit and PR Descriptions

Write so a reader learns **why** the change happened, not what changed.
The diff shows *what*; the text supplies only the *why*.

## Route by artifact

```text
What are you writing?
├── Commit message     → Match the repo → Why-only rule → Commits → Verify: commit
├── PR description     → Match the repo → Why-only rule → Reader-first → PR descriptions → Verify: PR
└── PR comment / reply → Why-only rule → Reader-first → PR comments → Verify: PR
```

## Match the repo first

Before writing, read local history:

```bash
git log -20 --format='%s%n%b---'
```

History decides **format**: subject dialect (plain imperative vs `type:`
prefixes), trailer and ticket-reference style, wrapping, and language.
This skill decides **content**: the why-only rule always applies, even when
history is full of what-narrating bodies. Use the format defaults below only
when history gives no signal.

## Why-only rule (all artifacts)

Allowed: facts the diff cannot show — failure cause, user or cost impact,
rejected alternative, tradeoff, external constraint.

Forbidden: any sentence a reader could reconstruct from the diff. That
includes imperatives like `Treat / Use / Add / Keep / Split / Pin / Switch`,
`We now…`, and a tool, model, or flag name stated as an instruction. State
facts instead: "Psycopg 3 exposes the first result…", not "Use one
result-producing statement…".

**Subtraction test (mandatory before output):** cover the diff and read the
text alone. If a sentence lets you guess what the code does, delete it. If
nothing remains, a commit ships subject-only. Mention the fix only as
`because + outside-diff fact`, never as an action. The last sentence states
the cost of doing nothing, why the alternative loses, or the tradeoff —
never the change restated as an action.

Good: "DuckDB 1.5 rejects the virtual-hosted URL because it does not match
the wildcard certificate, which failed `convert_details` after the
upgrade." Wrong: "Configure the DuckDB S3 secret to use path-style URLs." —
that is the diff, spoken aloud.

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

- Optional. When the subject and the diff make the why obvious
  (`Fix typo in installation guide`), skip the body.
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

## Reader-first (PR descriptions and comments)

Grammar alone does not make text easy. Cut load: fewer facts, fewer terms,
fewer numbers. A teammate from another team must be able to repeat the main
point after one read.

- **Answer first.** The first sentence is the whole answer, readable alone,
  bold in Markdown. Everything after it is support the reader may skip.
- **One mechanism, max 3 sentences.** Drop side facts that do not change the
  conclusion (edge cases, percentages, "plus some extra rows from…").
- **Max 3 numbers per paragraph, rounded** (`3.6B`, not `3,632,958,680`).
  Prefer one ratio (`~99% less`) over several raw counts. Keep only numbers
  that size the problem or the payoff, and keep each number's scope: a
  figure from an 8-day window is not "every day". Mark an estimate with one
  word (`~2 GB, estimated`), not a sentence about the method.
- **Jargon only when the reader needs the word later.** Otherwise say what
  the thing does: "Redshift keeps the min and max value of each block", not
  "zone maps". A kept term gets a definition of under 10 words, once.
- **One name per object.** Pick it on first mention and never switch ("date
  folder" everywhere, not folder / partition / prefix in turn).
- **Plain sentences.** Active voice, simple present or past. Max 25 words
  per sentence, one idea per sentence. No idioms. No `-ing` clauses to carry
  order or cause — write two sentences.
- **No hedges or meta-talk:** no "prior read-only investigation", "not a
  post-change benchmark", "nothing else changes", "not run in production
  yet". An unmerged change is obviously not in production.
- **No "I checked…" / "I verified…"** and no verification section. A check
  appears only as a fact inside the reason: "Each date folder holds only
  rows from that date across all 3.6B rows, so skipping old date folders
  loses nothing." Never mention linters, type checks, or passing tests.
- **No instructions to the reader** ("must load it by hand", "make sure
  to…"). State the fact; the reader draws the conclusion. The only allowed
  directive is a required step order.
- **No bullet lists.** Write prose. Write an ordered procedure as one arrow
  line: `create table → register folders → deploy procedure`.
- **Show contrasts, do not narrate them.** Two options → two code lines with
  a short comment each, or a two-row table.
- **One screen.** The visible part stays under 150 words. On GitHub, raw
  measurements go in `<details><summary>Measurements</summary>…</details>`;
  elsewhere cut them.
- **Cold-reader check** when the visible text exceeds 80 words: read only
  the text, as someone who never saw the code or the thread (use a subagent
  when available). Replace or cut every word or step that reader would not
  understand. Shorter text skips this; the subtraction test covers it.

## PR descriptions

Default: one or two short plain-text paragraphs — what was found, the
problem, why it should be fixed. No headers, no template sections.

Order for longer PRs, each part only when it exists:

1. Bold sentence: the problem and its size, or the payoff.
2. Why it happens and why the change is safe, one short paragraph. Checks
   appear only as facts inside the reason.
3. Required step order (deploy, migration, backfill) as one arrow line.
   Put an exception inside the step it affects, in parentheses.
4. `<details>` with raw measurements, when they exist.
5. Stack and links last: `Stacked on #556.`

- **Headers:** never `#` or `##`. Use `####` only when the description
  exceeds 150 visible words and has two separate topics; max 2.
- **No generic sections:** no `Summary`, `Why`, `Validation`, `Test plan`,
  checklists, or `As a… I want… So that…`, unless the user explicitly asks
  for a structured format.
- **GitHub alerts** (`> [!WARNING]`) only for a problem the reader can cause
  or miss: silent data loss, an outage, an irreversible step. Never for
  style, performance notes, or general caution. When the step order is the
  risk, the alert holds the risk sentence and the arrow line.
- **Diagrams:** none by default. Add one, after the why-paragraph, only when
  the why has visual shape (before/after flow, state change, request
  lifecycle) and prose needs more than two lines. Max 5 rows, labels
  instead of raw data (`skip` / `read`, not timestamps). Pick the shape with
  the `ascii-diagrams` skill; prefer ASCII in a `text` block because it
  survives copy-paste and plain-text renderers, and use Mermaid only for
  branching graphs.

```markdown
**`sp_load_moat_new` scans ~250 GB of S3 every day to keep ~33M rows.
Reading only the recent date folders drops that to ~2 GB (estimated).**

Today Redshift does not know the IAS table is split into date folders, so
every run reads every file. Last week that took up to 18 minutes per run.
Each date folder holds only rows from that date across all 3.6B rows, so
skipping old date folders loses nothing.

> [!WARNING]
> Redshift ignores a date folder until it is registered, and the load
> then skips its rows without any error. Deploy in this order: create the
> table → register the 739 existing date folders (all except
> `backfill_11_10-21_10/`, a duplicate of 2024-10-21) → deploy
> org/data-platform-dags#2798 → register date folders created after
> 2026-10-29 → deploy the procedure.

<details><summary>Measurements</summary>

17.9k files and 3.68B rows scanned per run, 98–1,072 s per run,
~$37/month saved.

</details>

Stacked on #556.
```

## PR comments and replies

A reviewer reads many threads; they need your decision, not a recap.

- First sentence is the decision: agree, disagree, or the direct answer to
  the question. Then the reason as one outside-diff fact.
- When a commit addresses the comment, end with its short SHA
  (`Fixed in a1b2c3d.`). Do not describe what the commit changed.
- Max 80 words. No thanks, apologies, or restating the reviewer's comment.
- Disagreement states the cost of the suggested option, not an opinion:
  "Caching here returns stale prices for up to 5 minutes after an update."

## Posting mechanics

Pass multi-line text with real newlines, never `\n` escapes. An inline
`"para1\n\npara2"` stores literal backslash-n text, which renders as
visible `\n\n`. Use a quoted heredoc or a file:

```bash
git commit -F - <<'EOF'
Subject line

Body paragraph wrapped at 72 characters.

Resolves: #123
EOF
```

```bash
gh pr create --body-file body.md   # or gh pr edit --body-file body.md
```

## Verify

**Commit**

1. Subject: imperative, capitalized, no final period, ≤50 target, ≤72 hard.
2. Blank line after the subject.
3. Body absent, or ≤3 lines wrapped at 72, no diagram.
4. Subtraction test passes; last sentence is not the change as an action.
5. Trailers: issues and shared-thread URL only, no PR link, no attribution.
6. Real newlines, no literal `\n`.

**PR description or comment**

1. Sentence 1 is the whole answer (bold in a description).
2. Subtraction test passes.
3. ≤3 rounded numbers per paragraph; every kept term defined.
4. One name per object; sentences ≤25 words.
5. No hedges, "I checked", reader instructions, or bullet lists.
6. No `#`/`##`; alert only for a real risk; references at the bottom.
7. Visible text ≤150 words (comments ≤80); cold-reader check if >80.
8. Real newlines, no literal `\n`.

When reviewing existing text, report only the broken rules, with a
corrected version. Cheap history pass for the hard limit:

```bash
git log --format=%s | awk 'length > 72'
```

Empty output means every subject fits.
