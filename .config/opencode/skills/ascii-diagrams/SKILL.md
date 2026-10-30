---
name: ascii-diagrams
description: "Use when the user asks for ASCII diagrams, timeline diagrams, flow diagrams, schedule explanations, stack traces, flamegraphs, or a single user-friendly ASCII output with Apple/Uber-like clean styling. Routes Mermaid-renderable shapes to Mermaid first; falls back to ASCII for flamegraphs, XY plots, memory layouts, and explicit ASCII requests."
---

# ASCII Diagrams

Use this skill when a diagram will explain timing, data flow, state, architecture, comparisons, profiling, or operational behavior more clearly than prose.

Not for code-shape diffs or rendered HTML artifacts — use the `explain` skill for those.

## Pick the output

The OpenCode TUI renders Mermaid directly, so Mermaid is the default for every shape it supports. ASCII is for shapes Mermaid cannot draw and for surfaces that cannot render Mermaid. Walk this tree every time:

```text
Did the user ask for ASCII, or is the target plain text
(commit body, code comment, terminal output)?
├── Yes → ASCII shape tree below
└── No
    ├── Arrows between steps, services, or dependencies?  → Mermaid flowchart
    ├── Request lifecycle across services?                → Mermaid sequenceDiagram
    ├── States and transitions, migrations, drift?        → Mermaid stateDiagram-v2
    ├── Ranges, durations, parallel tracks?               → Mermaid gantt
    ├── Time-anchored phases, before/after?               → Mermaid timeline
    ├── Branch and merge history?                         → Mermaid gitGraph
    ├── 3+ parallel rows of facts?                        → Markdown pipe table
    └── Otherwise                                         → ASCII shape tree below

ASCII shape tree
├── One value, ratio, threshold, before/after, ≤5 rows?   → Shape 1 Simple
├── Width means time or share across nested calls?        → Shape 3 Flamegraph
├── Nesting or causality of calls, no time axis?          → Shape 3 Call tree
├── Value against a continuous axis; the curve matters?   → Shape 5 XY plot
├── Position means offset, address, or geometry?          → Shape 6 Layout
├── Events or ranges on a time axis?                      → Shape 4 Timeline
└── Arrows between distinct nodes carry meaning?          → Shape 2 Flow
```

The tree checks the smaller shapes first. Never wrap a number, a ratio, or a two-line answer in a flow: the reader has to trace arrows to find a fact that a bar or a sentence states directly.

Keep Mermaid plain: short real labels, only the diagram types listed above, no styling directives. Unrenderable syntax degrades to raw source in the TUI. Put measured values, real identifiers, and `←` causes into labels, edge text, and Notes.

## Style

- **Open flows by default.** Plain labels joined by connectors. Add a border only when it marks a real boundary (external system, process or host edge, component group); borders everywhere hide which boundaries matter.
- **Rounded corners always.** Draw box corners with `╭ ╮ ╰ ╯`, never `┌ ┐ └ ┘`. Square corners read as terminal UI chrome; rounded ones match the open, light style. Keep interior junctions (`┬ ┴ ├ ┤ ┼`) and plot axis origins (`└─▶`) as they are.
- **One idea per block.** More than ~8 nodes or more than two rails in one band means split into sections or switch shape.
- **Labels ≤ 4 words** plus the exact identifier or number that makes the point.
- **Summary only for a decision.** End with a one-line summary only when there is a decision or conclusion worth restating; otherwise end at the diagram.

## Shape 1 — Simple ASCII

Use for ratios, magnitudes, short comparisons, config snapshots, or enumerations. Often the best answer is a single bar chart or a 3-row table — not a diagram.

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
 −Δ ┤               ▇
    0                          1   +Δ behind · −Δ ahead · 0 reference
```

Curve plus an envelope band (`█` actual run, `░` ±σ band):

```text
e + ┤                       ░░░░
    │              ░░░░░░░░░░░░░
  0 ┤█░█░░░░░█░█░░░░░░░░░█░█░░░░
    │  ░░░░░█░░░░█░░░░█░█░░░░░░
e − ┤             ░░░░░░░░░░░░░
    └──────────────────────────▶ t
```

## Shape 6 — Layout / geometry

Use for memory and buffer layouts, on-disk formats, or spatial/vector relationships — anything where *position* carries the meaning.

```text
        head ─┐ (next write)
 idx:  0    1    2    3   …   15
      ╭────┬────┬────┬────┬────╮
      │ t₀ │ t₁ │ t₂ │ t₃ │ t₁₅│   timestamps (µs)
      ╰────┴────┴────┴────┴────╯
        ↑ oldest          newest ↑
```

```text
              ● point
              ┊  ⟂ perpendicular onto nearest segment
              ▼
   •╮     A        B
    ╰•╮ ╭•───X────•╮
      ╰•╯       ╰•── … ──▶

  X = A + t·(B − A)
  t = clamp(0, (● − A)·(B − A) / |B − A|², 1)
```

## Output rules

- Put every ASCII diagram, chart, table, tree, or layout in its own fenced block (`text`, or a language tag for call trees). Never put prose, headings, conclusions, or Markdown lists inside the fence: the user copies the block as-is and should not have to strip prose out of it.
- Write explanation as rendered Markdown before or after the block, and never repeat in prose what the diagram already shows.
- When the user asks for a single ASCII output, return one `text` block containing only the diagram.

## Width safety

A right border stays straight only when every interior line has the same display width. Drift is a width problem, not a reason to drop the border.

- **Pad every interior line** between `│ … │` with trailing spaces to one width, and make the top and bottom `─` runs that same width.
- **Interiors hold text only.** Put ASCII text or one repeated glyph (`●●●●●`) inside a box; never put arrows or other symbols there. Glyphs like `→ ▶ ▲ ▼` render 2 cells wide in some terminals and push the right border out of line.
- **Flow goes outside the box.** Route arrows and branches (`│ ▼ ├ ─▶`) in the open space around boxes.
- **One box, one idea.** Split a tall multi-line box into small boxes joined by external connectors.

```text
        ╭─────────────╮
in ────▶│  worker: 5  │────▶ out
        ╰──────┬──────╯
               │ overflow
               ▼
            dropped
```

## Verify before output

1. The output choice came from the tree in "Pick the output".
2. Every rail character (`│ ▼ └ ┴`) sits in the same column on every line it spans.
3. Every box's interior lines and borders have the same width.
4. Bar and flamegraph lengths match `round(value / max × width)`.
5. No prose, headings, or lists inside a fence.
