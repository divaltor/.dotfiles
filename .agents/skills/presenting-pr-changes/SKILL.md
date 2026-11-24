---
name: presenting-pr-changes
description: "Turns a change or a piece of work into one still chart or diagram for colleagues: measured before/after numbers as a chart, or a mechanism as a before/after timeline, in a calm Apple- and Linear-style look set in Inter and Geist Mono. Use when asked to present, package, show, or explain work, a PR, or a change to others as an image, chart, diagram, card, or one-pager. Not for videos (use package-my-work)."
---

# Presenting work as a picture

The reader is a colleague who did not do the work. They see one image in Slack, Jira or a doc and give it about 30 seconds. One image carries one claim, and the picture carries it: a chart or a diagram, with text only to name what the picture shows. A page of prose with a screenshot of code is a document, not a presentation.

Read [reference/visualization.md](reference/visualization.md) before drawing anything and [reference/taste.md](reference/taste.md) before changing any style. The templates already follow both.

When a reference image is supplied, match its visual construction before choosing a template. Compare the rendered result with the reference, not just the prose rules. For before/after reductions, use outlined bars, baseline projection guides and a dashed hatched reduction span (`type: 'reduction'`); solid ranking bars are not a substitute.

## 1. Pick the picture

```
What does the work change for the reader?
├── Moves a measured number (memory, runtime, cost, counts)
│   → chart, templates/chart.html
│     ├── parts of a total, before and after     → type: 'stacked'
│     ├── before/after, one or several items     → type: 'reduction'
│     ├── three or more successive stages       → type: 'grouped'
│     └── a ranking or counts across items       → type: 'bars'
├── Fixes behaviour about time or order (leak, race, retry, lifetime)
│   → before/after lanes, templates/timeline.html
├── Changes structure, flow, or boundaries
│   → blueprint diagram, templates/diagram.html (constructions in reference/visualization.md)
│     ├── work or cost leaves a shared stage     → split / deferral
│     ├── a hop is added, removed, or bypassed   → routing (before/after)
│     ├── two scopes or windows intersect        → overlap / boundary
│     ├── N items batch, stream, or join         → fan-in / batching
│     └── callers share one schema or contract   → relation / interface
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
- **Marks:** every number in the title is a labeled mark. Use one blue accent by default; for multiple stages, use the stable series colors below. `--worse` only for a number that got worse or a broken state.
- **Bottom text adds only what the picture does not already say.** Never repeat the metric, unit, sample size, a value on a mark, or a change the marks already show; the title and subtitle already said them. Bottom text answers the questions the bars leave open.
- **Facts** (charts, `facts: [{label, value, text, color}]`): two or three columns, usually **What stayed the same** (the evidence nothing else changed, such as `0 differences` in DAGs and import errors) and **What it costs** (what the change trades for the win, such as `+286 MiB, +2.1 s` in the parent). `value` is a short measured result in the color of the stage it belongs to, so it reads as part of the chart; `text` is one sentence saying what it means. Skip a column you have no source for; never pad. Never give reader instructions or describe chart mechanics.
- **Method** (charts, `method`): one muted line on how it was measured that the subtitle does not already say, such as runs per file, environment or isolation.
- **Note** (timelines, or a chart caveat that fits no column): one or two short sentences on how the numbers were measured or the limitation that affects them, under the same no-repeat rule.
- **Source line** (timeline only, optional): one mono line naming the tool that found the problem, such as `ruff ASYNC119 yield-in-context-manager-in-async-generator`.

`chart.html` and `timeline.html` build the page from the `DATA` constant at the top; edit only `DATA` unless the layout breaks. In `timeline.html`, describe each lane as regions over stages (`set`, `broken`, `cleared`) with a label inside each one that matters, and put events such as `yield` in `boundaries`; the page refuses to render a label that does not fit its region. `diagram.html` edits the inline SVG directly following the construction table in `reference/visualization.md`.

## 5. Style

The rules and the reason for each are in reference/taste.md. In short:

- Near-white warm canvas, near-black ink, one muted gray for secondary text. Default to `--accent` (blue) for the claim. When comparing multiple stages, use gray (`--context`) for the baseline, blue for the first changed stage and teal (`--stage-next`) for the next. Keep each stage's color consistent across groups and label it directly; use additional distinct hues only when more measured stages require them. Red (`--worse`) means regression, never an arbitrary stage. Tokens are OKLCH in each template's `:root`.
- Use `type: 'grouped'` for separate stage measurements, with `series: [{name, color}]` and `rows: [{name, values}]` in the same series order. The first series is the baseline: an unfilled neutral outline, like the before bar of a reduction. Every later stage gets the reduction construction against it: tinted outline in its stage color, a dashed hatched span back to the baseline endpoint, and its value with the change from baseline (`1,062 ms −8.3%`). Give all bars one zero-based scale. Reserve `stacked` for additive parts of a total; successive snapshots are not parts to stack.
- Marks use thin outlines, at most 7.5% tint and a subtle 4px corner radius, not solid fills or square ends. Hatch measured reductions or the broken intervals of a timeline, only those intervals; do not add hatching to rankings where no change is measured.
- Inter (variable, optical sizes) for all text: title 34/600, subtitle 19/400, labels 17, ticks and notes 15–16. Geist Mono at 0.94em for identifiers. Both load with `@font-face`. `render.sh` downloads them from the Google Fonts repository into `~/.cache/presenting-pr-changes/fonts` on first run, fills the templates' `{{FONTS}}` placeholder with that path, and stops if either fails to load.
- **Ligatures off in mono:** `font-feature-settings: 'calt' 0, 'liga' 0, 'dlig' 0`. Never use `font-variant-ligatures`: every `font:` shorthand resets it, and `->` then renders as an arrow, which misquotes the code.
- **Never:** boxes around charts, outlined badges, uppercase letter-spaced labels, rows of big-number stat cards, gradients, icons, emoji, shadows, or a brand palette.
- **Canvas:** 1080 CSS px wide at device scale 2. The height follows the content.

## 6. Text pass

Load `emil-unslop-writing` and run it over every string on the page. On top of it: no em dashes; labels in sentence case; notes as plain sentences, not cryptic fragments; repeat one noun for one thing ("team context" everywhere, not "team var" in one place). Check that the bottom text repeats nothing already on the image and answers a question the bars leave open (what stayed the same, what it costs, how it was measured), rather than telling readers what to do.

## 7. Design pass

Load `emil-unslop-design` and walk every element with its question: what breaks if this is gone? Delete what survives on decoration alone, then walk again.

## 8. Render and check

1. Copy the template to `.amp/in/artifacts/<topic>/page.html` in the workspace, so the PNG can be embedded in the reply. Put `/.amp/in/` in the repo's `info/exclude` first.
2. Run `python3 scripts/check.py .amp/in/artifacts/<topic>/page.html` and fix any errors before rendering.
3. Run `scripts/render.sh .amp/in/artifacts/<topic>/page.html .amp/in/artifacts/<topic>/out/<name>.png`. It measures the content height, then screenshots the whole page at 2160px wide, padding included. When `chart.html` still holds several charts, render each one on its own padded canvas with a query: `scripts/render.sh '.amp/in/artifacts/<topic>/page.html?chart=stacked' out/stacked.png` (`?chart=` takes a type or a position from 1). Never deliver an element screenshot, such as agent-browser `screenshot .chart` or a DevTools node capture: it drops the page padding and the image runs to its edges.
4. Inspect the PNG with `view_media`. Name the checks in the objective: the canvas keeps its margins on all four sides, every number in the title is a labeled mark, no text overlaps a mark or gridline, nothing runs past the right edge, `->` shows as two characters, every number matches its source, and no arrow enters a target crookedly. With a reference image, also check the outlines, fills, hatching and guide geometry against it; typography alone is not a match.
5. Embed the PNG in the reply, keep `page.html` next to it, and say how to re-render. Offer one next step, such as a Slack post to go with the image.
