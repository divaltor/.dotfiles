---
name: presenting-pr-changes
description: "Turns a pull request or code change into one still image for colleagues: a mechanism page that explains a bug and its fix, or a chart page for measured before/after numbers, in FT colours with IBM Plex Sans and Ioskeley Mono. Use when asked to present, package, show, or explain a PR or change to others as an image, screenshot, card, chart, or one-pager. Not for videos (use package-my-work)."
---

# Presenting PR changes

The reader is a colleague who did not review the PR. They see one image in Slack, Jira or a PR comment and give it about 30 seconds. One page carries one idea, and every rule below follows from that.

## 1. Pick the format

```
What does the change do for the reader?
├── Fixes behaviour that was wrong (bug, leak, race, wrong default)
│   → mechanism page, templates/mechanism.html                          (§4)
├── Moves a measured number (memory, runtime, cost, parse time)
│   → chart page, templates/chart.html                                  (§5)
│     ├── parts of a total, before and after → type: 'stacked'
│     └── one value per item, before and after → type: 'dumbbell'
├── Changes what DAG authors write or configure
│   → mechanism page without the timeline: before/after is the DAG
│     author's code, and the lead says who has to change what
├── Sweeps the codebase (lint, formatting, upgrade, migration)
│   → the single most important finding as a mechanism page, plus the
│     "Across the codebase" list at the bottom                           (§4.7)
└── Several unrelated changes
    → one page per change, at most 3. More than that, and the PR text
      is the document, not an image.
```

A list of five findings gets skimmed. One mechanism, explained properly, gets remembered and repeated.

## 2. Gather facts before any design

- Read the PR body, the diff (`git diff <base>...<head>`) and any measurement output.
- Every claim needs a source you can point to: a diff hunk, a test run, a command output. Before writing "X caused Y", re-read the code path and confirm Y happens on it. If you can't trace it, cut the claim. A "shared default leaks state between tasks" claim was cut once because the code that mutates state never received the default.
- Code excerpts are exact lines from the diff. Allowed edits: drop lines and mark the gap with a `…` line, and re-wrap a long call the way the formatter would. Never add comments, rename anything or reorder lines.
- Numbers are copied, never re-rounded. Compute deltas and percentages from the values shown on the page, so a reader can check them.

## 3. Leave out bookkeeping

Never show PR numbers, Jira keys, branch names, commit SHAs, tool versions, file paths, test names or author names. Readers need what changed and why; the bookkeeping lives in the PR. In charts, "dev" and "PR #1635" become "before" and "after".

## 4. Mechanism page

Sections, top to bottom:

1. **Source line** (only when a tool found the problem): one mono line, such as `ruff ASYNC119 yield-in-context-manager-in-async-generator`.
2. **Headline:** the bug stated as a past-tense fact, at most 12 words, naming the thing that misbehaved. "Every trigger kept its team context open across `yield`", not "Fix ContextVar handling".
3. **Lead:** 3–4 sentences in the order cause → effect → failure. Name the real function, type and error.
4. **Timeline** (only when the bug is about time or order): before and after lanes over the same segments. A claret bar marks where the bad state holds; teal bars mark where the fixed state holds. Under each bar, a lowercase fragment on the left and the end result in bold on the right. Skip the timeline when the bug is a wrong value; the code and one sentence carry it.
5. **Code:** Before and After side by side when the longest line is 52 characters or less (13.5px mono fits two columns in 1080px). Otherwise stack them at 15px. Wrap the lines that changed in `<b>` so they render in ink; the rest stays faint.
6. **Evidence:** one sentence on how the fix was proven, such as a test that fails on the old code and passes on the new.
7. **Across the codebase** (sweeps only): at most 5 rows of number + fragment, then at most one sentence. No big-number cards.

## 5. Chart page

- **Title:** the finding with its numbers ("cut task pod memory by 29% to 39%"), not the metric's name.
- **Subtitle:** the metric and the conditions it was measured under.
- **Axis:** stacked bars start at 0, because bar length encodes the value. Dumbbells may start above 0, because only position encodes the value; pick round ticks that cover min to max. The unit goes on the last tick only.
- **Labels:** value and unit at the bar end, with the delta muted next to it. Identifiers such as DAG ids are mono (`id: true` in `DATA`) and sit on their own line above the dumbbell row, because a long id overlaps the dots otherwise.
- **Colour:** baseline and before are base or faint, after is teal. Claret appears only when a number got worse.
- **Note:** method, run counts and caveats in 1–2 sentences. A median always says how many runs it is a median of.
- The template builds everything from the `DATA` array. Edit only `DATA` unless the layout breaks.

## 6. House style

- **Palette (FT):** paper `#FFF1E5`, ink `#262A33`, muted `#66605C`, faint `#A39A92`, rule `#E6D2C0`, segment `#F2DFCE`, base `#C9BDB2`, claret `#990F3D`, teal `#0D7680`. Colour appears only where it encodes before vs after.
- **Fonts:** IBM Plex Sans (400/500/600) for all text, Ioskeley Mono (400/500) for code and identifiers, loaded with `@font-face` from `~/Library/Fonts`. `render.sh` stops if either is missing or fails to load.
- **Ligatures off in mono:** `font-feature-settings: 'calt' 0, 'liga' 0, 'dlig' 0`. Never use `font-variant-ligatures`: every `font:` shorthand resets it, and `->` then renders as an arrow, which misquotes the code.
- **Code blocks:** a white surface, 4px radius, no border, shadow, side bar or tinted rows. Emphasis comes from ink vs faint text only.
- **Never:** outlined badges, uppercase letter-spaced labels, rows of big-number stat cards, gradients, icons, emoji or shadows.
- **Canvas:** 1080 CSS px wide at device scale 2. The height follows the content.

## 7. Text pass

Load `emil-unslop-writing` and run it over every string on the page. On top of it: no em dashes; labels in sentence case; notes as lowercase fragments; repeat one noun for one thing ("team context" everywhere, not "team var" in one place).

## 8. Design pass

Load `emil-unslop-design` and walk every element with its question: what breaks if this is gone? Delete what survives on decoration alone, then walk again.

## 9. Render and check

1. Copy the template to `.amp/in/artifacts/<topic>/page.html` in the workspace, so the PNG can be embedded in the reply. Put `/.amp/in/` in the repo's `info/exclude` first.
2. Run `scripts/render.sh .amp/in/artifacts/<topic>/page.html .amp/in/artifacts/<topic>/out/<name>.png`. It measures the content height, then screenshots at 2160px wide.
3. Inspect the PNG with `view_media`. Name the checks in the objective: no text overlaps, nothing runs past the right edge, `->` shows as two characters, every number matches its source.
4. Embed the PNG in the reply, keep `page.html` next to it, and say how to re-render. Offer one next step, such as a Slack post to go with the image.
