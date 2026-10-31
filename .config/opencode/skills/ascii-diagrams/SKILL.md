---
name: ascii-diagrams
description: "Use when the user asks for ASCII diagrams, timeline diagrams, flow diagrams, charts, sparklines, wireframes, schedule explanations, stack traces, flamegraphs, or a single user-friendly ASCII output with Apple/Uber-like clean styling. Routes Mermaid-renderable shapes to Mermaid in the TUI, prefers ASCII in GitHub PRs, renders charts, flows, plans and wireframes from a spec with a bundled glyph-kit renderer, and hand-draws flamegraphs, XY plots, and memory layouts."
---

# ASCII Diagrams

Use this skill when a diagram will explain timing, data flow, state, architecture, comparisons, profiling, or operational behavior more clearly than prose.

Not for code-shape diffs or rendered HTML artifacts — use the `explain` skill for those.

## Pick the output

Where the reader sees the figure decides the format. Walk this tree every time:

```text
Where will the reader see it?
├── Plain text (commit body, code comment, terminal, Slack),
│   or the user asked for ASCII                        → ASCII tree
├── GitHub PR (description, comment, review)
│   ├── Request lifecycle across 3+ services?          → Mermaid sequenceDiagram
│   ├── Branch and merge history?                      → Mermaid gitGraph
│   ├── 3+ parallel rows of facts?                     → Markdown pipe table
│   └── Otherwise                                      → ASCII tree
└── OpenCode TUI
    ├── Arrows between steps, services, deps?          → Mermaid flowchart
    ├── Request lifecycle across services?             → Mermaid sequenceDiagram
    ├── States and transitions, migrations, drift?     → Mermaid stateDiagram-v2
    ├── Ranges, durations, parallel tracks?            → Mermaid gantt
    ├── Time-anchored phases, before/after?            → Mermaid timeline
    ├── Branch and merge history?                      → Mermaid gitGraph
    ├── 3+ parallel rows of facts?                     → Markdown pipe table
    └── Otherwise                                      → ASCII tree

ASCII tree
├── One value, one ratio, or a short enumeration?      → Shape 1 Simple
├── Width means time or share across nested calls?     → Shape 3 Flamegraph
├── Nesting or causality of calls, no time axis?       → Shape 3 Call tree
├── Curve against a continuous axis?                   → Shape 5 XY plot
├── Position means offset, address, or geometry?       → Shape 6 Layout
├── A kit kind fits (table in "Render with the kit")?  → render it
├── Events or ranges on a time axis?                   → Shape 4 Timeline
└── Arrows between distinct nodes carry meaning?       → Shape 2 Flow
```

Why PRs default to ASCII: GitHub lays Mermaid out automatically with generic
styling, and it shows as raw source in email notifications and `gh pr view`.
A rendered or hand-drawn figure puts measured values and labels exactly where
they explain the change. Sequences across 3+ services and git graphs stay
Mermaid because ASCII draws them worse.

The tree checks the smaller shapes first. Never wrap a number, a ratio, or a two-line answer in a flow: the reader has to trace arrows to find a fact that a bar or a sentence states directly.

Keep Mermaid plain: short real labels, only the diagram types listed above, no styling directives. Unrenderable syntax degrades to raw source in the TUI. Put measured values, real identifiers, and `←` causes into labels, edge text, and Notes.

## Render with the kit

Kinds that fit common figures (list all with `node <skill>/scripts/glyph-kit.mjs types`):

| Content                                                    | Kind                                       |
| ---------------------------------------------------------- | ------------------------------------------ |
| Two or more numbers side by side (percentiles, sizes)      | `barChart`                                 |
| Before and after per measure                               | `compare`                                  |
| One trend, progress toward a cap, headline numbers         | `sparkline`, `meter`, `metricPanel`        |
| Two-axis density, drop-off, measured plus projected        | `heatmap`, `funnel`, `forecast`            |
| Straight sequence of steps, or steps with yes/no decisions | `flow`, `branchFlow`                       |
| States and the events between them                         | `stateMachine`                             |
| Who owns which step, work over weeks                       | `swimlane`, `gantt`                        |
| Roadmap, priorities, decisions with reasons                | `board`, `impactEffort`, `decisionLog`     |
| A screen or layout                                         | `screen`, `appShell`, `listDetail`, `modal`, `cardGrid` |

A kit kind wins over a hand-drawn shape whenever both fit: the kit computes
bar lengths and closes every frame, which is where hand-drawn figures fail.
Hand-draw Shape 2 only for services or components talking to each other,
where boundaries and annotations carry the point.

`<skill>` is this skill's base directory (normally
`~/.config/opencode/skills/ascii-diagrams`). `scripts/glyph-kit.mjs` is a
dependency-free fork of [glyph-kit](https://github.com/alextraykov/glyph-kit)
(MIT, `LICENSE`) that draws light frames with rounded corners. Write scratch
specs in the user's workspace or `/tmp`, never in `<skill>`.

1. **Copy the data shape** from `node <skill>/scripts/glyph-kit.mjs guide <kind>`.
   Never guess it from the kind's name: `flow` takes plain strings
   (`["build", "test"]`), and `compare` takes shares from 0 to 1 in `a` and
   `b`, with the printed values in `aText` and `bText`.
2. **Write the spec** with `kind`, `title`, `data`, and, whenever `data` holds a
   number, `source` (command, file, or dashboard plus a date). The renderer
   refuses numbers without a source; never invent one to get past it.
3. **Render:** `node <skill>/scripts/glyph-kit.mjs render spec.json --to text --no-color`
   (`render -` reads the spec from stdin). Use `--to text` for commits, Slack,
   terminals, and PRs, `--to markdown` for a doc with a title and source line,
   and `--compact` only for strict 7-bit ASCII or a model's context.
4. **Read stderr.** A refusal names the problem in a sentence; fix the spec,
   not the output. A label cut with `…` loses words: shorten it to 24 cells.
5. **Paste the output unchanged** into a `text` fence. Never re-align a
   rendered figure by hand; edit the spec and render again. Bars draw in data
   order: sort unordered categories by value, but keep natural orders such as
   p50 → p99.
6. **Put the conclusion in the sentence next to the figure.**

Other outputs, all through `node <skill>/scripts/glyph-kit.mjs`: `render --to html`,
`export <spec> --to svg|png|pdf|mdx` (`reference/export.md`), `live <spec> --to html`
for moving process diagrams (`reference/live.md`), `deck`, and `check spec.json`
to list every problem at once. Call something out with `focus`, never with
colour (`reference/spec.md`). Read `reference/areas/<area>.md` only when two
kinds still seem to fit.

## Style

These rules are for hand-drawn figures. Kit output already uses rounded light
frames; its heavy (`┏`) and double (`╔`) frames mark start and end states, and
its `►`, `┆`, and `→` glyphs are measured, so leave them as rendered.


- **Open flows by default.** Plain labels joined by connectors. Add a border only when it marks a real boundary (external system, process or host edge, component group); borders everywhere hide which boundaries matter.
- **Rounded corners always.** Draw box corners with `╭ ╮ ╰ ╯`, never `┌ ┐ └ ┘`. Square corners read as terminal UI chrome; rounded ones match the open, light style. Keep interior junctions (`┬ ┴ ├ ┤ ┼`) and plot axis origins (`└─▶`) as they are.
- **One idea per block.** More than ~8 nodes or more than two rails in one band means split into sections or switch shape.
- **Labels ≤ 4 words** plus the exact identifier or number that makes the point.
- **Summary only for a decision.** End with a one-line summary only when there is a decision or conclusion worth restating; otherwise end at the diagram.

## Shape 1 — Simple ASCII

Use for one value, one ratio, config snapshots, or enumerations. Two or more real numbers to compare go to the kit (`barChart`, `compare`); hand-draw these bars only when the kit is unavailable. Often the best answer is a single bar chart or a 3-row table — not a diagram.

Bar length is proportional: `cells = round(value / max × width)`, with width ≤ 40 cells. Values sit in one right-aligned column. Wrong proportions tell the reader a false ratio before they read the numbers.

```text
p50   ▇▇                                  42 ms
p95   ▇▇▇▇▇▇▇▇                           180 ms
p99   ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇     640 ms
```

Before / after:

```text
before    ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇    2.4 s
after     ▇▇▇▇▇                      540 ms   (4.4× faster)
```

Tiny enumeration:

```text
• reads      cached, 1 RTT
• writes     quorum, 2 RTT
• failover   ~3 s, no data loss
```

Reference table inside a fence (ASCII forced) — always separate the header row:

```text
value            meaning                  safe use
──────────────────────────────────────────────────────
logical_date     scheduled run identity   legacy paths
event.timestamp  asset emission time      observability
dag_run.run_id   unique consumer run      storage paths
```

## Shape 2 — Flow diagram

Use only when arrows between distinct nodes carry meaning (services, steps, states, dependencies).

Lay linear flows left-to-right: the reader scans in the same direction as text, and the diagram stays a few lines tall. Use top-to-bottom only for hierarchies, or when labels shortened to ≤ 4 words still exceed ~100 columns.

**Open flow (default).** Nodes are plain text labels joined by connectors. Put payload or type notes in parentheses on the line below their node, starting under the node's first character. Drop branches with a vertical rail (`│`) and `▼`.

```text
user mentions @bot in chat X ──▶ Update.guest_message ──▶ bot.on("guest_message")
        │                        (Message + guest_query_id)         │
        │                                                           ▼
        └── not sent as "message" or        ctx.api.answerGuestQuery(queryId, result)
            "inline_query" to your bot      (InlineQueryResult, like inline mode)
```

- One connector family per diagram: `──▶` horizontal, `│ ▼ └──` vertical. Never mix arrow styles (`→ ▶` with `◄ ⤷`).
- Each rail stays in one column: every `│`, `▼`, and `└` of the same rail sits in that column on every line.

**Boxed flow (only when a boundary matters).** Keep each box small and route connectors outside the borders; follow Width safety below.

```text
╭────────╮     ╭─────╮     ╭──────────╮
│ Client │────▶│ API │────▶│ Database │
╰────┬───╯     ╰──┬──╯     ╰──────────╯
     │            │
     │            ▼
     │        ╭────────╮
     ╰───────▶│ Worker │
              ╰────────╯
```

## Shape 3 — Stack / flamegraph

Use for call stacks, hot paths, profiles, nested durations, or "where did the time go".

**Flamegraph:** root on top, width ∝ time, using the same proportional rule as Shape 1. Label first, bar below, time or % right-aligned. Collapse irrelevant frames into `…`.

```text
main                                                          1000 ms
████████████████████████████████████████████████████████████
  handleRequest                                               820 ms
  █████████████████████████████████████████████████
    parseBody                                                 120 ms
    ███████
    queryDB                                                   560 ms
    ██████████████████████████████████
      serialize                                                90 ms
      █████
    render                                                    140 ms
    ████████
  log                                                         180 ms
  ███████████
```

**Call tree** (causality and nesting, no time axis): 2-space indent per level, `→` on every child, one exact identifier per line (`Module.method()`). Separate independent stacks with a blank line and a heading line. Tag the block with the language (`ts`, `py`, `go`) so identifiers get syntax highlighting.

````text
```ts
LocationServiceMap.get(ref)
  → build location layer
    → Config.layer reads authored documents
      → merge authored documents
      → run currently active Config loaders
    → Policy.layer reads transformed Config
    → Catalog.layer reads transformed Config
      → materialize baseline provider/model catalog
  → PluginBoot baseline ready
    → Frontend.fetchCatalog()

PluginBoot background fiber
  → install/update plugin packages concurrently
  → activate completed plugins
    → Config.loader(pluginID).replace(transform)
    → ReloadScheduler.request()
      → debounce short burst of completed activations
      → Reload.all()
        → Config.get()
          → run newly active Config loaders
        → Catalog.reload()
          → Catalog.Event.Updated
            → Frontend.refetchCatalog()
```
````

## Shape 4 — Timeline

Use when the X axis is time and Mermaid cannot be used. Keep every day rail in its column on every line.

```text
Sun        Mon        Tue        Wed        Thu        Fri
 │          │          │          │          │          │
 │          ▲ deploy v2           │          │          │
 │          ███████████████████████████████████████████
 │          ▲ canary window       │          │          │
```

## Shape 5 — XY plot

Use when a value changes over a continuous axis (time, distance, progress) and the *shape of the curve* is the point: growth, drift, deltas, spread.

- Label the Y axis above the top tick; put the X axis label after the arrow.
- `┤` for plain ticks, `┼` where a zero/baseline line crosses.
- One glyph per column so points stay vertically aligned.
- Legend on one line under the plot, never inside it.

Single curve (elapsed time vs track progress):

```text
elapsed
   28s ┤                    ▇
       │                 ▇  ▇
       │              ▇  ▇  ▇
   14s ┤┄┄┄┄┄┄┄┄▇  ▇  ▇  ▇  ▇
       │     ▇  ▇  ▇  ▇  ▇  ▇
    0s ┤▇  ▇  ▇  ▇  ▇  ▇  ▇  ▇
       └─────────┴──────────────▶ progress
       0        0.42            1
```

Signed values around a zero baseline:

```text
 +Δ ┤      ▇  ▇
    │   ▇  ▇  ▇  ▇
  0 ┼──────────────────────────▶ progress
    │            ▇  ▇  ▇
 -Δ ┤               ▇
    0                          1   +Δ behind · -Δ ahead · 0 reference
```

Curve plus an envelope band (`█` actual run, `░` ±σ band):

```text
e + ┤                       ░░░░
    │              ░░░░░░░░░░░░░
  0 ┤█░█░░░░░█░█░░░░░░░░░█░█░░░░
    │  ░░░░░█░░░░█░░░░█░█░░░░░░
e - ┤             ░░░░░░░░░░░░░
    └──────────────────────────▶ t
```

## Shape 6 — Layout / geometry

Use for memory and buffer layouts, on-disk formats, or spatial/vector relationships — anything where *position* carries the meaning.

```text
                     head ─┐ (next write)
 idx:    0     1     2     3     4   …  15
      ╭─────┬─────┬─────┬─────┬─────╮
      │ t₀  │ t₁  │ t₂  │  ·  │  ·  │ … timestamps (µs)
      ╰─────┴─────┴─────┴─────┴─────╯
         ▲ oldest    ▲ newest
```

```text
              ■ point
              ┊  perpendicular onto nearest segment
              ▼
   •╮     A        B
    ╰•╮ ╭•───X────•╮
      ╰•╯       ╰•── … ──▶

  X = A + t·(B - A)
  t = clamp(0, (■ - A)·(B - A) / |B - A|², 1)
```

## Output rules

- Put every ASCII diagram, chart, table, tree, or layout in its own fenced block (`text`, or a language tag for call trees). Never put prose, headings, conclusions, or Markdown lists inside the fence: the user copies the block as-is and should not have to strip prose out of it.
- Write explanation as rendered Markdown before or after the block, and never repeat in prose what the diagram already shows.
- When the user asks for a single ASCII output, return one `text` block containing only the diagram.

## Width safety

A right border stays straight only when every interior line has the same display width. Drift is a width problem, not a reason to drop the border.

- **Pad every interior line** between `│ … │` with trailing spaces to one width, and make the top and bottom `─` runs that same width.
- **Interiors hold text only.** Put ASCII text or one repeated glyph (`■■■■■`) inside a box; never put arrows or other symbols there. Glyphs like `→ ▶ ▲ ▼` render 2 cells wide in some terminals and push the right border out of line.
- **Flow goes outside the box.** Route arrows and branches (`│ ▼ ├ ─▶`) in the open space around boxes.
- **One box, one idea.** Split a tall multi-line box into small boxes joined by external connectors.
- **Use only measured glyphs.** The safe set is in `<skill>/reference/characters.md`. `↑ − ● ⟂ ✓` are unmeasured: use `▲ - ■ ok` instead.

**Lint every hand-drawn figure before sending it.** The linter reads `text` fences only, so lint a copy with tagged fences renamed:

```bash
sed 's/^```[a-z][a-z]*$/```text/' draft.md > /tmp/lint.md && node <skill>/scripts/lint.mjs /tmp/lint.md
```

A pass prints nothing and exits 0. Fix every `error` (unequal box rows, text touching a border, unmeasured glyphs): a box one cell off reads as broken. Warnings about `▶` only matter in Departure Mono and can stay.

```text
        ╭─────────────╮
in ────▶│  worker: 5  │────▶ out
        ╰──────┬──────╯
               │ overflow
               ▼
            dropped
```

## Verify before output

1. The output choice came from the tree in "Pick the output"; a figure a kit kind fits was rendered, not hand-drawn.
2. Every rail character (`│ ▼ └ ┴`) sits in the same column on every line it spans.
3. Every box's interior lines and borders have the same width.
4. Bar and flamegraph lengths match `round(value / max × width)`.
5. No prose, headings, or lists inside a fence.
6. Hand-drawn figures pass `scripts/lint.mjs` with no errors.
