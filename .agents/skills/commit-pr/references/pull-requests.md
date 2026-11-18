# Pull Request Descriptions and Comments

Read `../SKILL.md` first. Its body gate, "match the repo", why-only rule, and
plain-words rules apply to everything below. This file adds what only PR text
needs: BLUF, the shape tree, the two layouts, comment rules, and the checklist.

## BLUF (PR descriptions and comments)

BLUF, bottom line up front: the first sentence is the main why, and
everything after it is optional support, ordered so the reader can stop at
any point.

**The first sentence is the main why and stands alone.** It names the code
object in backticks and states the cause and its consequence:
"`<object>` does X, so Y happens." Never open with what merging the PR
does, what it leaves out, a deploy order, or a warning. Those go in the
arrow line or an alert below.

Wrong: "Merging this PR deploys the AWS prerequisites, not the Lambda fix."
Right: "The shared CircleCI role trusts every branch of a project, so any
feature branch of `data-platform-redshift-ddls-backup` could deploy to
Prod."

For a bug or incident, the first sentence is what the reader saw, in their
nouns: the failure, the stuck deploy, the wrong number. "On 12 Nov the
3.4.0 migration ran 25 minutes in prod and the deploy got stuck." The
mechanism comes second. A reviewer recognizes a symptom at once; a cause
needs the code open.

**Support, in order of importance.** Each paragraph is one short block of
facts the reader cannot get elsewhere. Write it so cutting the last
paragraph never breaks the one before it.

**Code formatting.** Every repo, file, table, column, DAG, function, role,
stack, claim, branch, and flag name goes in backticks, every time. Naming
the object inside a why sentence is required; explaining what it does is
not.

**Inherited-from-code test (mandatory before output).** The reader opens
the diff next to your text. Delete every sentence the code, the title, or
the repo already gives them:

- what a file, table, DAG, or function does
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
The table omits the last 15 of the file's 37 columns, because they are
empty in all 1,982 rows of the current export. `load_longitude_recognition_board`
fails validation if they ever carry data.

`load_longitude_recognition_board` needs this table before its first run.
```

The first sentence is the one choice a reviewer cannot see in the DDL,
because it lives in the data. The required order comes second.

### Keep the text easy to read

- **Bold is rare.** At most one short phrase per description, and only a
  good outcome the change delivers: `drops that to **~2 GB**`. Never bold a
  whole sentence, a warning, a step order, a code name, or a label. A change
  with no clear win to show gets no bold.
- **One mechanism, max 3 sentences.** Drop side facts that do not change the
  conclusion. When there are two separate bugs, say so and number them in
  prose: "Two separate bugs here. (1) … (2) …", so neither hides inside the
  other.
- **Name the cost.** When the change has a price (memory kept, a broken
  convention, a number that reads higher, a partly written result on
  failure), give it one sentence: "The cost is ~1 extra page (~300 KB) for
  an idle terminal." A reviewer trusts a change that admits its price, and
  otherwise finds it in review. No cost, no sentence.
- **Every number carries its conditions.** One line under a table, or one
  clause in the sentence: dataset or env, run count and statistic, which
  direction is better. "Medians of 5 runs, prod image `26487`." A number
  without them cannot be checked.
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
  linters, type checks, or passing tests. The strongest check is a sameness
  fact on real inputs: "All 844 DAGs from the 12 team repos parse the same
  as on `dev`." Ruff dropped Test Plan from its template because it
  "prompts contributors to recap tests that already run in CI".
- **One human judgment is allowed.** When the change rests on a call you
  made, say it once in first person: "I think keeping the old image until
  the transfer ends is nicer than Kitty's behavior." An honest doubt counts
  too ("I'm not sure how long this has been broken"). One is a voice;
  several are hedging.
- **No instructions to the reader** ("make sure to..."). State the fact. The
  only allowed directive is a required step order, and it belongs in the
  arrow line.
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
├── A code name                           → inline `code`, always
├── The input or error the reader saw     → fenced block: the failing query,
│   (a bug they can reproduce)              call, or error line, trimmed
├── The line of code that decides the     → fenced block with a language tag,
│   behavior the why is about               only that line, trimmed with …
├── Steps that must happen in order       → one arrow line: a → b → c
├── 3+ cases compared on 2+ attributes    → table (see the table test)
├── 2 cases, or 1 attribute               → one sentence: `160 MiB → 76 MiB`
├── A flow, state change, or alignment    → ASCII in a `text` block
│   that prose needs 3+ lines for           (see Diagrams)
├── Raw measurement dumps                 → <details> with the numbers
└── Anything else                         → prose sentences, never bullets
```

- **Prose is the default** because a reason needs "because" and "so". A
  bullet drops those words, and bullets invite padding.
- **Table test:** would the reader scan down a column to compare cases? If
  they read each row once, left to right, it is a sentence. A table below
  3 rows or 2 compared columns costs more than the sentence it replaces: it
  breaks the reading flow and drops the "because". Wrong: a 2-row
  before/after table for one metric. Right: "Peak memory: ~160 MiB →
  **~76 MiB**." Code names inside cells stay in backticks.
- **A table, code quote, or diagram replaces prose**, it does not repeat
  it. Delete every sentence it already says.
- **Max one code quote and one table or diagram** per description, placed
  after the first sentence. For a bug, prefer the reproducer over the
  deciding line: the reviewer can paste it and watch it fail.

## PR descriptions

Only after the body gate passes, pick the layout:

```text
How many reasons does the body carry?
├── One reason (a step order may follow) → Layout A: prose with inline code
└── A choice between alternatives, or 2+ reasons
    → Layout B: why, then the deciding code and parts below as they apply
```

### Layout A: small PRs

The why as one or two short prose paragraphs with every code name in
backticks, then the arrow line when an order exists. No code block, no
table. Visible text under 80 words.

```markdown
The shared CircleCI role trusts every branch of a project, so any feature
branch of `data-platform-redshift-ddls-backup` could deploy to Prod.
`CircleCI-role-data-platform-redshift-ddls-backup` trusts only
`refs/heads/master` of that repo, so it needs no CircleCI project UUID.

Composer deploy → import `RedshiftDDLsBackup` → enable CI deploys in
Financial-Times/data-platform-redshift-ddls-backup#2
```

### Layout B: larger PRs

Each part only when it exists, in this order. Always quote the deciding
line when one line of code decides the behavior, because it is the
evidence a reviewer would otherwise hunt for in the diff. A table appears
only when it passes the table test; a B description with no table is
normal.

1. **The main why:** one sentence, cause and consequence (or the symptom,
   for a bug), code names in backticks. At most one "now" sentence with
   the observable result.
2. **The reproducer or the deciding line of code** in a fenced block with
   a language tag, trimmed with `…`.
3. **Comparison table**, only when it passes the table test: 3+
   alternatives a reviewer would ask about, with the chosen option as the
   last row, or 3+ cases with measured numbers. Its conditions go in one
   line under it.
4. **The cost**, one sentence, when one exists.
5. **Exposure** for a platform change that team DAGs consume: what other
   repos see, and the sameness fact that bounds it. A table with one row
   per behavior change and its team DAG exposure, when it passes the table
   test; otherwise one sentence.
6. **Required step order** (deploy, migration, backfill) as one arrow line.
   Put an exception or its reason inside the step, in parentheses. When the
   order is a risk, an alert carries it instead.
7. **Raw measurements** in `<details>`, when they exist.
8. **Links last,** only those GitHub does not already show: `Fixes #…`,
   upstream issues, specs, Jira.

````markdown
The shared CircleCI role trusts every branch, so a feature branch push to
`data-platform-redshift-ddls-backup` could replace the Prod Lambda.

```yaml
sub: org/677bda31-…/project/*/user/*/vcs-origin/github.com/Financial-Times/data-platform-redshift-ddls-backup/vcs-ref/refs/heads/master
```

| Trust `sub` | Branches that deploy | Needs project UUID |
|---|---|---|
| Shared template: `project/<uuid>/user/*` | every branch | yes |
| `project/<uuid>` + `refs/heads/master` | `master` | yes |
| `project/*` + repo + `refs/heads/master` | `master` | no |

Composer deploy → import `RedshiftDDLsBackup` (the role has `UpdateStack`
only) → enable CI deploys in Financial-Times/data-platform-redshift-ddls-backup#2
````

### Rules for both layouts

- **No stack lines:** GitHub shows the base branch and linked PRs, so leave
  out `Stacked on #...` and merge-order lines. Name another PR only when its
  order is a requirement the UI cannot show, such as a PR in another repo
  that must deploy first. That PR then goes into the step-order arrow line.
- **One line per paragraph:** never hard-wrap PR descriptions or comments.
  GitHub and Slack reflow text themselves, and a manual break at 72
  characters folds into ragged short lines on narrow panes and breaks
  copy-paste. Separate paragraphs with one blank line. The 72-column wrap
  applies to commit bodies only.
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

Layout B where no single line of code decides it, so the evidence is a
number, an alert carries a risky order, and raw numbers sit in `<details>`:

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

Pass multi-line text with real newlines, never `\n` escapes: an inline
`"para1\n\npara2"` renders as visible `\n\n`. Use a file:

```bash
gh pr create --body-file body.md   # or gh pr edit --body-file body.md
gh pr create --title "Collapse Abacus sidebar modules by default" --body ""   # no body
```

## Verify

Run this checklist silently. Never print it or a "verified / checks passed"
note: output the final text alone. Mention a check only when a rule could
not be met and the user must decide.

1. Sentence 1 is the main why (cause and consequence, or the symptom for a
   bug) and stands alone. At most one "now" sentence, stating an
   observable result. No "X, not Y", "Merging this PR…", or "This PR…"
   anywhere. Bold only one payoff phrase, or none.
2. A body exists only because a body-gate condition holds; subtraction and
   inherited-from-code tests pass.
3. ≤3 rounded numbers per paragraph, each with its conditions; every kept
   term defined; the cost stated when one exists.
4. One name per object, in backticks when it is a code name; sentences
   ≤25 words.
5. No hedges, "I checked", reader instructions, or bullet lists; at most
   one first-person judgment.
6. Layout A for one reason, B for a choice or 2+ reasons; B quotes the
   deciding line when one exists; every table passes the table test; ≤1
   code quote and ≤1 table or diagram.
7. No em dashes, slop verbs, or label lead-ins.
8. No `#`/`##`; alert only for a real risk; no stack or merge-order line
   unless the order is a requirement the UI cannot show.
9. Visible text ≤150 words (comments ≤80); cold-reader check if >80.
10. Real newlines, no literal `\n`; each paragraph on one line, no hard
    wraps.

When reviewing existing text, report only the broken rules, with a
corrected version.
