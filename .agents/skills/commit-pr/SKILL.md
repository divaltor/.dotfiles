---
name: commit-pr
description: "Write, review, or improve Git commit messages, GitHub PR descriptions, and PR comments that explain a change. Use when the user asks for a commit message, a PR description, or a PR comment/reply."
---

# Commit and PR Descriptions

Write so a reader learns **why** the change happened, not what changed.
The diff shows *what*; the text supplies only the *why*. In a PR or comment,
put the one thing the reader must know or do first (BLUF), then only the
facts the code cannot show.

## Route by artifact

```text
What are you writing?
├── Commit message     → Match the repo → Why-only rule → Plain words → Commits → Verify: commit
├── PR description     → Match the repo → Why-only rule → Plain words → BLUF → Shape tree → PR descriptions → Verify: PR
└── PR comment / reply → Why-only rule → Plain words → BLUF → Shape tree → PR comments → Verify: PR
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

The one imperative allowed is a required action the diff cannot show, such
as "Merge before the first run of X". It is the bottom line of a PR, not a
description of the code.

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

## BLUF (PR descriptions and comments)

BLUF, bottom line up front: the first sentence is what the reader must know
or do, and everything after it is optional support, ordered so the reader
can stop at any point. A reviewer opens the PR to decide something. Give
the decision input first, not the story of how you got there.

**The bottom line is the first sentence and stands alone.** Pick the first
item that applies:

```text
What is the most important thing for the reader?
├── An action or order they must follow  → that (merge before X, deploy order)
├── A risk they can cause or miss        → that (silent data loss, outage)
├── A verdict you need from them         → that (the decision and your pick)
└── Otherwise                            → the problem and its size, or the payoff
```

**Support, in order of importance.** Each paragraph is one short block of
facts the reader cannot get elsewhere. Write it so cutting the last
paragraph never breaks the one before it.

**Inherited-from-code test (mandatory before output).** The reader opens
the diff next to your text. Delete every sentence the code, the title, or
the repo already gives them:

- what a file, table, DAG, or function does, and what it is called
- lists of columns, fields, flags, or types, and how they map
- which callers or sensors the diff touches
- a restatement of the title

What stays is only what the code cannot say: the cause, the cost of doing
nothing, a rejected alternative, a number from outside the repo, a required
order. When the code can say it but does not, the fix is a code comment or a
better name, not a PR paragraph. A fact a future reader of the file needs
(a column whose meaning is unknown, a source typo kept on purpose) goes in
a comment next to the code, because a PR description is gone from the file
after merge.

Wrong, for a PR titled `Add longitude_recognition_board_rs_la DDL`: three
paragraphs about the DAG that loads the table, the 37-column file, and a
bulleted "Notes on the types" for four columns. All of it is the DDL read
aloud. Right:

```markdown
Merge before the first run of `load_longitude_recognition_board`, which
needs this table to exist.

The table omits the last 15 of the file's 37 columns, because they are
empty in all 1,982 rows of the current export. The DAG fails validation
if they ever carry data.
```

The first sentence is the one required step. The second paragraph is the
one choice a reviewer cannot see in the DDL, because it lives in the data.

### Keep the text easy to read

- **Bold is rare.** At most one short phrase per description, and only a
  good outcome the change delivers: `drops that to **~2 GB**`. Never bold a
  whole sentence, a warning, a step order, a code name, or a label. A change
  with no clear win to show gets no bold.
- **One mechanism, max 3 sentences.** Drop side facts that do not change the
  conclusion.
- **Max 3 numbers per paragraph, rounded** (`3.6B`, not `3,632,958,680`).
  Prefer one ratio over several raw counts. Keep each number's scope: a
  figure from an 8-day window is not "every day". Mark an estimate with one
  word (`~2 GB, estimated`), not a sentence about the method.
- **Jargon only when the reader needs the word later.** Otherwise say what
  the thing does. A kept term gets a definition of under 10 words, once.
- **One name per object.** Pick it on first mention and keep it.
- **Plain sentences.** Active voice, max 25 words, one idea each. No `-ing`
  clauses to carry order or cause: write two sentences.
- **No hedges or meta-talk:** no "prior investigation", "not a post-change
  benchmark", "nothing else changes". An unmerged change is obviously not
  in production.
- **No "I checked..." / "I verified..."** and no verification section. A check
  appears only as a fact inside the reason: "Each date folder holds only
  rows from that date, so skipping old folders loses nothing." Never mention
  linters, type checks, or passing tests.
- **No instructions to the reader** ("make sure to..."). State the fact. The
  only allowed directive is a required step order, and it belongs in the
  bottom line.
- **One screen.** The visible part stays under 150 words. On GitHub, raw
  measurements go in `<details><summary>Measurements</summary>...</details>`;
  elsewhere cut them.
- **Cold-reader check** when the visible text exceeds 80 words: read only
  the text as someone who never saw the code or the thread (use a subagent
  when available). Replace or cut every word or step that reader would not
  understand.

## Shape tree (PR descriptions and comments)

Walk this for each part of the text, not once for the whole text:

```text
What does this part carry?
├── A cause, a reason, a tradeoff         → prose
├── Steps that must happen in order       → one arrow line: a → b → c
├── 2+ cases with the same attributes     → table
│   (run modes, before/after per object,
│    option A vs option B)
├── A flow, state change, or alignment    → ASCII in a `text` block
│   that prose needs 3+ lines for           (see Diagrams)
├── Measured before/after numbers         → <details> with the numbers
└── Anything else                         → prose sentences, never bullets
```

- **Prose is the default** because a reason needs "because" and "so". A
  bullet drops those words, and bullets invite padding.
- **A table earns its place** when the reader compares down a column. It
  needs at least 2 rows and 2 columns of real data; one row is a sentence.
- **A table or diagram replaces prose**, it does not repeat it. Delete
  every sentence the table already says.
- **Max one table or diagram** per description, placed after the bottom line.

## PR descriptions

Decide the size before writing:

```text
Do the title and the diff explain the change to a teammate?
├── Yes (rename, typo, version bump, small config change, plain DDL)
│   → No body. If the user asks for one, the bottom line alone, or nothing.
└── No → Bottom line, then only the paragraphs that pass the
         inherited-from-code test.
```

An empty body is a valid result, not a missing one. Padding a small PR
teaches reviewers to skip descriptions, including the ones that matter.

Wrong, for a PR titled `Rename monthly Adbook order DAG` that also updates
two sensors: "Airflow exposes it as `biteam_adbook_monthly_order` because
FTDAG adds the team prefix. Both booking DAGs depend on this DAG; stale
sensor targets would leave them waiting." Every sentence is the title, the
diff, or team knowledge. Right: no body.

Order for longer PRs, each part only when it exists:

1. **Bottom line:** one or two sentences, chosen by the tree above.
2. **Why it happens and why the change is safe,** one short paragraph.
3. **Required step order** (deploy, migration, backfill) as one arrow line.
   Put an exception inside the step it affects, in parentheses. When the
   order is a risk, the alert below carries it instead of the bottom line
   repeating it.
4. **Raw measurements** in `<details>`, when they exist.
5. **Links last,** only those GitHub does not already show.

- **No stack lines:** GitHub shows the base branch and linked PRs, so leave
  out `Stacked on #...` and merge-order lines. Name another PR only when its
  order is a requirement the UI cannot show, such as a PR in another repo
  that must deploy first. That PR then goes into the step-order arrow line.
- **Headers:** never `#` or `##`. Use `####` only when the description
  exceeds 150 visible words and has two separate topics; max 2.
- **No generic sections:** no `Summary`, `Why`, `Changes`, `Notes`,
  `Validation`, `Test plan`, checklists, or `As a... I want...`, unless the
  user explicitly asks for a structured format.
- **GitHub alerts** (`> [!WARNING]`) only for a problem the reader can cause
  or miss: silent data loss, an outage, an irreversible step. Never for
  style, performance notes, or general caution.
- **Diagrams:** only when the why has visual shape (before/after flow, state
  change, request lifecycle) and prose needs 3+ lines. Max 5 rows, labels
  instead of raw data. Pick the shape with the `ascii-diagrams` skill;
  prefer ASCII in a `text` block and use Mermaid only for branching graphs.

```markdown
`sp_load_moat_new` scans ~250 GB of S3 every day to keep ~33M rows.
Reading only the recent date folders drops that to **~2 GB** (estimated).

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

17.9k files and 3.68B rows scanned per run, 98-1,072 s per run,
~$37/month saved.

</details>
```

## PR comments and replies

A reviewer reads many threads. The first sentence is the bottom line: agree,
disagree, or the direct answer to the question.

- Then the reason as one outside-diff fact.
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

Run this checklist silently. Never print it, its results, or a
"verified / checks passed" note in the response: the user asked for the
text, and a list of ticks only adds reading. Output the final text alone.
Mention a check only when a rule could not be met and the user must decide.

**Commit**

1. Subject: imperative, capitalized, no final period, ≤50 target, ≤72 hard.
2. Blank line after the subject.
3. Body absent, or ≤3 lines wrapped at 72, no diagram.
4. Subtraction test passes; last sentence is not the change as an action.
5. Trailers: issues and shared-thread URL only, no PR link, no attribution.
6. Real newlines, no literal `\n`.

**PR description or comment**

1. Sentence 1 is the bottom line and stands alone. Bold only one payoff
   phrase, or none.
2. Subtraction and inherited-from-code tests pass; a small PR has no body.
3. ≤3 rounded numbers per paragraph; every kept term defined.
4. One name per object; sentences ≤25 words.
5. No hedges, "I checked", reader instructions, or bullet lists.
6. Each part shaped by the shape tree; ≤1 table or diagram.
7. No em dashes, slop verbs, or label lead-ins.
8. No `#`/`##`; alert only for a real risk; no stack or merge-order line
   unless the order is a requirement the UI cannot show.
9. Visible text ≤150 words (comments ≤80); cold-reader check if >80.
10. Real newlines, no literal `\n`.

When reviewing existing text, report only the broken rules, with a
corrected version. When asked to review history, a cheap pass for the hard
limit:

```bash
git log --format=%s | awk 'length > 72'
```

Empty output means every subject fits.
