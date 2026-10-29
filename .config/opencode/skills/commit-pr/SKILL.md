---
name: commit-pr
description: "Write, review, or improve Git commit messages, GitHub PR descriptions, and PR comments that explain a change. Use when the user asks for a commit message, a PR description, or a PR comment/reply."
---

# Commit and PR Descriptions

Write so a reader learns **why** the change happened, not what changed.
The diff shows *what*; the description supplies only the *why*.

Sources: cbea.ms/git-commit and tbaggery.com/2008/04/19/a-note-about-git-commit-messages.

## Match the repo first

Before writing, read local history and follow its conventions:

```bash
git log -20 --format='%s%n%b---'
```

Match the subject dialect (plain imperative vs `type:` prefixes), trailer and
ticket-reference style, wrapping habits, and language. Fall back to the
defaults below only when history gives no signal.

## Commit template

```text
Capitalize the subject, ~50 chars, imperative, no final period

Optional body, max 3 lines: the cause, then the cost of doing nothing.
Wrap at 72 characters. Details live in the PR or the linked thread.

Resolves: #123
Amp-Thread-ID: https://ampcode.com/threads/T-…
```

- Imperative test: the subject must complete "If applied, this commit will
  ___." Good: `Fix race in cache eviction`. Wrong: `Fixed race...`,
  `Fixing race...`.
- The body explains why, not what. Allowed: facts the diff cannot show
  (failure cause, user / cost impact, rejected alternative, tradeoff).
  Forbidden: any sentence reconstructible from the diff — imperatives like
  `Treat / Use / Add / Keep / Split / Pin / Switch`, `We now…`, or a tool /
  model / flag name stated as an instruction. State facts: "Psycopg 3 exposes
  the first result…", not "Use one result-producing statement…".
- Subtraction test (mandatory before output): cover the diff, read the body
  alone. If you can guess what code does, delete that sentence. If nothing
  remains, ship subject-only. Mention the fix only as `because + outside-diff
  fact`, never as an action.
- Never end the body with the change restated as an action. The last sentence
  must state the cost of doing nothing, the reason the alternative loses, or
  the tradeoff.
- A single title can be the whole message. When the subject and the diff make
  the why obvious (`Fix typo in installation guide`), skip the body.
- If the subject won't fit in ~50 characters, the commit probably does too
  much — prefer splitting into atomic commits.
- Never append generated attribution footers or `Co-Authored-By` trailers
  unless the user asks. Issue and thread link trailers are not
  attribution; see below.

## Commit bodies: terse, details live in the PR

A commit body answers one question: why did this change happen. The
mechanism, measurements, and deploy order live in the PR or the agent
thread, and the commit links there.

- Max 3 lines. The cause, then the cost of doing nothing. Fragments are
  fine.
- Terse voice: answer first, no ceremony, no recap, articles optional.
  Never drop not / never / only / except. Code names and numbers stay
  exact.
- A before/after number is one arrow with its unit and scope written once:
  `Rows read (8-day test): 18.6B → 94M`. In a commit, an arrow means only
  "becomes".
- Optional limit line, only when a reader would assume more was fixed:
  `Not covered: adserver_api_event, not sorted by date.`
- Trailers, after a blank line: related issues when they exist
  (`Resolves: #123`, `Related: #612`, or the repo's own style), and the
  agent thread URL only when you know it exactly and teammates can open
  it. Amp adds `Amp-Thread-ID: <thread URL>` itself when it commits, so
  never add a second one. OpenCode sessions are private by default: add
  `Session: <share URL>` only after `/share` returned that URL. Never
  guess or build a URL. No PR link: GitHub already shows the PR for
  every commit.

```text
Use raw date ranges in sp_monitoring_and_dq

DATE(time_stamp) hides the sort key, so Redshift reads every block of
events_mastertable. Rows read (8-day test): 18.6B → 94M.

Related: #612
Amp-Thread-ID: https://ampcode.com/threads/T-…
```

## Reader-first (PR text, PR comments)

Commit bodies follow the terse rules above; these rules are for longer
text. Grammar alone does not make text easy. Cut load: fewer facts, fewer terms,
fewer numbers. Reading test: a teammate from another team can repeat the main
point after one read.

- First sentence is the whole answer, readable alone. Bold it in Markdown.
  Everything after it is support the reader may skip.
- One mechanism, max 3 sentences. Drop side facts that do not change the
  conclusion (edge cases, percentages, "plus some extra rows from…").
- Max 3 numbers per paragraph, rounded (`3.6B`, not `3,632,958,680`).
  Prefer one ratio (`~99% less`) over several raw counts. Keep only numbers
  that size the problem or the payoff. Keep each number's scope: a figure
  measured over an 8-day window is not "every day".
- Mark an estimate with one word (`~2 GB, estimated`), not a caveat
  sentence about how it was estimated.
- Jargon only when the reader needs the word later. Otherwise say what the
  thing does: "Redshift keeps the min and max value of each block", not
  "zone maps". If you keep a term, define it once in under 10 words.
- One name per object. Pick it on first mention and never switch ("date
  folder" everywhere, not folder / partition / prefix in turn).
- No hedges or meta-talk: no "prior read-only investigation", "not a
  post-change benchmark", "nothing else changes", "not run in production
  yet". An unmerged change is obviously not in production.
- No "I checked…" / "I verified…" sentences and no separate verification
  part. A check appears only as evidence inside the reason, as a fact:
  "Each date folder holds only rows from that date across all 3.6B rows,
  so skipping old date folders loses nothing." Never mention linters,
  type checks, tests passing, or other routine checks.
- No instructions to the reader ("must load it by hand", "make sure to…").
  State the fact; the reader draws the conclusion. The only allowed
  directive is a required order of steps (see PR descriptions).
- No bullet lists in the output. Write prose. Write an ordered procedure
  as one arrow line: `create table → register folders → deploy procedure`.
- Show contrasts, do not narrate them. Two options → two code lines with a
  short comment each, or a two-row table.
- Diagrams: max 5 rows, labels instead of raw data (`skip` / `read`, not
  full timestamps).
- One screen: the visible part stays under ~150 words. On GitHub, raw
  measurements and depth go in `<details><summary>Measurements</summary>…
  </details>`. Otherwise cut them.
- Cold-reader check before output: read only the text, as someone who never
  saw the code or the thread (use a subagent when available). Every word or
  step that reader would not understand gets replaced or cut.

## STE-mini (bodies and PR paragraphs)

Write bodies and PR text in plain, simple English. Same subset as the
`jira-issue` skill, with one exception noted at the end:

- Active voice, simple present or simple past. No complex tenses.
- Short sentences: max 25 words. Shorter is better. Split long sentences.
- One idea per sentence. One instruction per sentence.
- One term per thing. No synonyms, no jargon, no idioms. Reuse the same word.
- No `-ing` clauses to carry order or cause. Write two plain sentences instead.
- Short paragraphs, one topic each.
- Exception: commit subjects and bodies are not full STE sentences. The
  subject stays an imperative fragment, ~50 chars, no final period; the
  body follows the terse commit rules.

## PR descriptions: freeform, no headers, no PM template

Default: one or two short plain-text paragraphs. Freeform — what was found,
the problem, why it should be fixed. Like the user writes it, not a product
template.

Order for longer PRs, each part only when it exists:

1. Bold sentence: the problem and its size, or the payoff.
2. Why it happens and why the change is safe, one short paragraph. Checks
   appear here only as facts inside the reason.
3. Required step order (deploy, migration, backfill) as one arrow line.
   Put an exception inside the step it affects, in parentheses, instead of
   its own sentence.
4. `<details>` with raw measurements, when they exist.
5. Stack and links last: `Stacked on #556.`

GitHub alerts (`> [!WARNING]`) are rare. Use one only for a real problem the
reader can cause or miss: silent data loss, an outage, an irreversible step.
Never for style, performance notes, or general caution. When the step order
is the risk, the alert holds the risk sentence and the arrow line.

Example of the full shape:

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

- No headers by default. Applies to text you write, not to this file. Never
  use `#` or `##`. Use `####` only when a long description cannot stay
  readable without a split, max 1–2 per description.
- No generic sections: no `Summary`, `Why`, `Validation`, `Test plan`,
  no checklists, no `As a… I want… So that…`. Use a structured format only
  when the user explicitly requests one.
- Same why-rule as commits: never narrate what the diff shows or restate the
  change as an action. Good: "DuckDB 1.5 rejects the virtual-hosted URL
  because it does not match the wildcard certificate, which failed
  `convert_details` after the upgrade." Wrong: "Configure the DuckDB S3
  secret to use path-style URLs." — that is the diff, spoken aloud.
- Before posting, run the subtraction test against the diff.

## Posting mechanics

Pass multi-line text with real newlines, never `\n` escapes. Write to a file
and pass it whole, or use a quoted heredoc:

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

An inline `"para1\n\npara2"` stores the literal backslash-n text, which
renders as visible `\n\n`.

## Verify

In order:

```text
imperative → ≤72-char subject → capitalized → no period → blank line
→ optional ≤3-line 72-wrapped body → issue / shared thread
trailers, no PR link → subtraction test passes → no closing
action → answer in sentence 1 → ≤3 rounded numbers, no undefined
jargon → one name per object → no hedges, "I checked", reader
instructions, or bullet lists → alert only for a real risk → cold-reader
check → STE-mini sentences → no headers (#{1,2} absent, #### only if needed)
→ references at bottom → no literal \n escapes
```

Report only the broken rules, with a corrected version. Cheap history pass:

```bash
git log --format=%s | awk 'length > 72'
```

Empty output means every subject fits the hard cap.

## Diagrams (only when shape helps)

Default stays prose-only. Add one diagram maximum, after the why-paragraph,
only when the *why* has visual shape (before/after flow, state change,
request lifecycle). Pick the shape with the `ascii-diagrams` skill; skip it
when prose covers it in two lines.

- Commit bodies (terminal, no Markdown): ASCII in a fenced `text` block.
  Keep every line ≤72 columns, never re-wrap. Never in the subject.
- PR descriptions (GitHub): prefer ASCII in a `text` block — it survives
  copy-paste and plain-text renderers. Use Mermaid only for shapes that need
  rendering, such as branching graphs.
