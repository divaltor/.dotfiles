---
name: presenting-pr-changes
description: "Turns a change or a piece of work into one still chart or diagram for colleagues: measured before/after numbers as a chart, or a mechanism as a before/after timeline, in a calm Apple- and Linear-style look set in Inter and Geist Mono. Use when asked to present, package, show, or explain work, a PR, or a change to others as an image, chart, diagram, card, or one-pager. Not for videos (use package-my-work)."
---

# Presenting work as a picture

The reader is a colleague who did not do the work. They see one image in Slack, Jira or a doc and give it about 30 seconds. One image carries one claim, and the picture carries it: a chart or a diagram, with text only to name what the picture shows. A page of prose with a screenshot of code is a document, not a presentation.

Read [reference/visualization.md](reference/visualization.md) before drawing anything and [reference/taste.md](reference/taste.md) before changing any style. The templates already follow both.

## 1. Pick the picture

```
What does the work change for the reader?
├── Moves a measured number (memory, runtime, cost, counts)
│   → chart, templates/chart.html
│     ├── parts of a total, before and after     → type: 'stacked'
│     ├── one value per item, before and after   → type: 'dumbbell'
│     └── a ranking or counts across items       → type: 'bars'
├── Fixes behaviour about time or order (leak, race, retry, lifetime)
│   → before/after lanes, templates/timeline.html
├── Changes what talks to what (a new hop, a removed call, a queue)
│   → before/after diagram drawn by hand from the diagrams section of
│     reference/visualization.md, in the timeline template's tokens
├── Sweeps the codebase (lint, upgrade, migration)
│   → bars of the counts that matter (findings per rule, files per team),
│     plus a timeline for the one finding that was a real bug
├── Fixes a wrong value with no number to measure
│   → no image: one sentence in the message says it better
└── Several unrelated changes
    → one image each, at most 3
```

Measure before you draw. A change that moves a number deserves the number: run the benchmark, count the files, time the parse. A chart of a real measurement persuades where a paragraph does not.

## 2. Gather facts

- Read the PR body, the diff (`git diff <base>...<head>`) and any measurement output.
- Every claim needs a source you can point to: a diff hunk, a test run, a command output. Before writing "X caused Y", re-read the code path and confirm Y happens on it. If you can't trace it, cut the claim.
- Numbers are copied, never re-rounded. Compute deltas and percentages from the values on the page, so a reader can check them.
- Code appears only as identifiers in labels (`execute()`, `smaps_rollup`) or as one exact line from the diff. Never a code block of the before and after.

## 3. Leave out bookkeeping

Never show PR numbers, Jira keys, branch names, commit SHAs, tool versions, file paths, test names or author names. In charts, "dev" and "PR #1635" become "before" and "after".

## 4. Write the claim, then build down to it

Follow the layer order in reference/visualization.md: claim, data, transform, form, encoding, scales, guides.

- **Title:** the finding with its numbers, at most 14 words. "Cut task pod memory by 29% to 39%", not "Memory usage". For a timeline, the rule the fix establishes: "Team context now ends at every `yield`".
- **Subtitle:** the metric and the conditions it was measured under, or what the bar in a timeline marks. One line.
- **Marks:** every number in the title is a labeled mark. The thing the title names is `--accent`; everything else is gray. `--worse` only for a number that got worse or a broken state.
- **Note:** method, run counts and caveats in one or two sentences. A median says how many runs it is a median of.
- **Source line** (timeline only, optional): one mono line naming the tool that found the problem, such as `ruff ASYNC119 yield-in-context-manager-in-async-generator`.

Both templates build the page from the `DATA` constant at the top. Edit only `DATA` unless the layout breaks.

## 5. Style

The rules and the reason for each are in reference/taste.md. In short:

- Near-white warm canvas, near-black ink, one muted gray for secondary text, one accent hue (`--accent`, blue) for the claim, `--worse` (red) for regressions. Tokens are OKLCH in each template's `:root`.
- Inter (variable, optical sizes) for all text: title 34/600, subtitle 19/400, labels 17, ticks and notes 15–16. Geist Mono at 0.94em for identifiers. Both load with `@font-face` from `~/Library/Fonts`; `render.sh` stops if either is missing or fails to load.
- **Ligatures off in mono:** `font-feature-settings: 'calt' 0, 'liga' 0, 'dlig' 0`. Never use `font-variant-ligatures`: every `font:` shorthand resets it, and `->` then renders as an arrow, which misquotes the code.
- **Never:** boxes around charts, outlined badges, uppercase letter-spaced labels, rows of big-number stat cards, gradients, icons, emoji, shadows, or a brand palette.
- **Canvas:** 1080 CSS px wide at device scale 2. The height follows the content.

## 6. Text pass

Load `emil-unslop-writing` and run it over every string on the page. On top of it: no em dashes; labels in sentence case; notes as lowercase fragments; repeat one noun for one thing ("team context" everywhere, not "team var" in one place).

## 7. Design pass

Load `emil-unslop-design` and walk every element with its question: what breaks if this is gone? Delete what survives on decoration alone, then walk again.

## 8. Render and check

1. Copy the template to `.amp/in/artifacts/<topic>/page.html` in the workspace, so the PNG can be embedded in the reply. Put `/.amp/in/` in the repo's `info/exclude` first.
2. Run `scripts/render.sh .amp/in/artifacts/<topic>/page.html .amp/in/artifacts/<topic>/out/<name>.png`. It measures the content height, then screenshots at 2160px wide.
3. Inspect the PNG with `view_media`. Name the checks in the objective: every number in the title is a labeled mark, no text overlaps a mark or gridline, nothing runs past the right edge, `->` shows as two characters, every number matches its source.
4. Embed the PNG in the reply, keep `page.html` next to it, and say how to re-render. Offer one next step, such as a Slack post to go with the image.
