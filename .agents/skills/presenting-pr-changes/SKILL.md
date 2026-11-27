---
name: presenting-pr-changes
description: "Turns a change or a piece of work into one still chart or diagram for colleagues: measured before/after numbers as a chart, or a mechanism as a before/after timeline, in a calm Apple- and Linear-style look set in Inter and Geist Mono. Use when asked to present, package, show, or explain work, a PR, or a change to others as an image, chart, diagram, card, or one-pager. Not for videos (use package-my-work)."
---

# Presenting work as a picture

One static PNG (1080 CSS px at 2x) read in Slack or Jira in 30 seconds. One image carries one claim; text only names what the picture shows.

Read [reference/visualization.md](reference/visualization.md) only when choosing a data transform or authoring a custom `diagram.html`. Read [reference/taste.md](reference/taste.md) only when changing CSS tokens or custom SVG styling. For standard charts and timelines, edit only `DATA` in the template; the templates already encode the tokens, typography, and layout.

## 1. Pick the picture

```
What does the work change for the reader?
├── Moves a measured number (memory, CPU, latency, cost, counts)
│   → templates/chart.html (edit DATA only)
│     ├── before/after across 1..N items             → type: 'reduction'
│     ├── step-by-step attribution (PR stack/budget) → type: 'waterfall'
│     ├── parts of a total, before and after         → type: 'stacked' (`orientation: 'horizontal' | 'vertical'`)
│     ├── 3+ successive stages (long labels)         → type: 'grouped'
│     ├── 3+ successive stages (short labels)        → type: 'columns'
│     ├── trace over time / spikes / headroom        → type: 'timeseries' (+ optional envelope)
│     └── ranking or counts across items             → type: 'bars'
├── Fixes behaviour about time or order (leak, race, retry, lifetime)
│   → templates/timeline.html (edit DATA only)
├── Changes structure, flow, or boundaries
│   → templates/diagram.html (5 constructions in reference/visualization.md)
├── Sweeps the codebase (lint, upgrade, migration)
│   → type: 'bars' for the counts + timeline.html for the one real bug
├── Fixes a wrong value with no number to measure
│   → no image: write one sentence in the message
└── Several unrelated changes
    → one image each, at most 3
```

When a reference image is supplied, match its visual construction (outlines, fills, hatching, guides) before choosing a template; typography alone is not a match.

## 2. Gather verified facts and drop bookkeeping

- Measure before drawing. Every number and causal claim needs a source you can point to (diff hunk, command output, test run). If you cannot trace "X caused Y" in code, cut the claim.
- Copy measured numbers verbatim; compute deltas and percentages from the values on the page so a reader can check them.
- Never show PR numbers, Jira keys, branch names, commit SHAs, tool versions, file paths, test names, or author names. Rename "dev" and "PR #1635" to `before` and `after`.
- Omit collection timestamps, comparison windows, rollout times, and repro commands unless time is the chart's subject or the user asked for them.
- Code appears only as inline identifiers (`execute()`, `smaps_rollup`) or one exact diff line. Never show before/after code blocks.

## 3. Fill `DATA` from the claim down

- **Kind (`kind`, optional):** set `'cpu'`, `'memory'`, `'io'`, `'latency'`, `'throughput'`, `'cost'`, `'cluster'`, or `{ icon, label, color }` to show an unboxed 16px hairline glyph above the title. Omit when no domain category helps.
- **Title:** the finding with its numbers, at most 14 words (`Cut task pod memory by 29% to 39%`, not `Memory usage`). Every number in the title must appear as a labeled mark.
- **Subtitle:** one line naming the metric and scope. Add a qualifier only if omitting it would mislead (e.g. sample vs full population).
- **Marks:** baseline bars use `--base-fill`; the primary claim uses `--accent` (blue), the next stage `--stage-next` (teal), and regressions or broken states `--worse` (red). Never use `--worse` as an arbitrary category.
- **Colors (`accent` / `colors`, optional):** default blue/teal/red accents need no config. When the user asks for another accent color, pass `?accent=<name-or-css>` (and optionally `stage-next`, `worse`) to `render.sh`, or set `accent` / `colors: { accent, 'stage-next', worse }` in `DATA`. Built-in contrast-safe aliases: `ft` (peach + teal + claret), `peach`, `purple`, `crimson`, `green`, `teal`; any raw CSS color (hex, OKLCH) also works. Only accent tokens change, never the `#faf9f5` canvas or neutral grays.
- **Bottom text adds only what the marks leave open.** Never repeat the metric, unit, sample size, or a delta the marks already display.
  - `facts` (optional, up to 3 columns `{ label, value, text, color }`): supporting measurements (what stayed unchanged, what it costs). Skip columns without a source; never pad.
  - `note` (optional, 1-2 sentences): mechanism, practical benefit, or concrete regression (`Memory rose by 54 MiB`, never defensive disclaimers like `No claim of memory savings`).
  - `method` / `source`: omit by default; include only when requested or when the method is the subject.

## 4. Text and design gate

Run this checklist over every string and element before rendering:

- **No slop copy:** zero em dashes, zero hedged filler (`crucial`, `leverage`, `significantly`, `not just`), sentence case on all labels, one consistent noun per concept, real minus (`−`, `\u2212`).
- **Earn every pixel:** ask "what breaks if this is gone?" and delete decoration, legends replaceable by direct labels, and redundant bottom prose.
- **Hard bans (enforced by `check.py`):** no boxes around charts, no pill chips/badges, no uppercase letter-spaced labels, no shadows, no gradients, no `font-variant-ligatures` (use `font-feature-settings: 'calt' 0, 'liga' 0, 'dlig' 0` so `->` never ligatures).

## 5. Check, render, and inspect

1. Copy the template to `.amp/in/artifacts/<topic>/page.html` (ensure `/.amp/in/` is in `.git/info/exclude`), keeping only the entries needed in `DATA`.
2. Run `pr-present check .amp/in/artifacts/<topic>/page.html` (or `python3 scripts/check.py ...`) and fix every error.
3. Run `pr-present render .amp/in/artifacts/<topic>/page.html .amp/in/artifacts/<topic>/out/<name>.png` (or `scripts/render.sh ...`). Pass `?chart=<type>` or `?chart=<index>` when rendering one chart from a multi-chart page. Never take a DOM element screenshot; it drops canvas padding.
4. Inspect the rendered PNG visually: margins intact on all four sides, every title number present as a mark, zero label overlap or edge clipping, `->` renders as two characters, and every arrow in diagrams enters its target orthogonally.
5. Embed the PNG in the reply, keep `page.html` beside it, and note how to re-render.
