---
name: ascii-diagrams
description: Use when the user asks for ASCII diagrams, timeline diagrams, flow diagrams, schedule explanations, stack traces, flamegraphs, or a single user-friendly ASCII output with Apple/Uber-like clean styling.
---

# ASCII Diagrams

Use this skill when a diagram will explain timing, data flow, state, architecture, comparisons, profiling, or operational behavior more clearly than prose.

## Pick the right shape first

Do not default to a flow diagram. Match the diagram to the problem.

| Problem shape                                                                  | Use                          |
| ------------------------------------------------------------------------------ | ---------------------------- |
| One value, ratio, threshold, before/after, simple comparison, short enumeration | **Simple ASCII** (bars, list, table) |
| Movement between steps/services/states, pipelines, request lifecycles, deps   | **Flow diagram**             |
| Call stacks, hot paths, CPU/memory profiles, nested time spent, blame trees   | **Stack / flamegraph**       |
| Time-anchored events, schedules, ranges, durations                            | **Timeline**                 |
| A value plotted against a continuous axis (time, distance, progress); curves, drift, spread | **XY plot** |
| Memory/buffer layout, geometry, or spatial relationships                       | **Other** (layouts, vectors) |

If two shapes fit, pick the smaller one. When in doubt, prefer the simplest shape that still answers the question — never wrap a number, ratio, or 2-line answer in a flow.

## Style

Aim for clean, premium, Apple/Uber-like text styling:

- minimal visual noise
- generous spacing
- short headings
- boxed sections with rounded corners only when they add clarity
- **rounded corners always:** draw box and container corners with `╭ ╮ ╰ ╯`, never square `┌ ┐ └ ┘`; keep interior junctions (`┬ ┴ ├ ┤ ┼`) and plot axis origins (`└─▶`) as they are
- aligned columns and timelines
- one strong visual idea per section
- concise summary at the end

## Shape 1 — Simple ASCII

Use for ratios, magnitudes, short comparisons, config snapshots, or enumerations. Often the best answer is a single bar chart or a 3-row table — not a diagram.

Horizontal bar comparison:

```text
p50   ▇▇▇                              42 ms
p95   ▇▇▇▇▇▇▇▇▇▇▇▇                    180 ms
p99   ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇    640 ms
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

## Shape 2 — Flow diagram

Use only when arrows between distinct nodes carry meaning (services, steps, states, dependencies).

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

Keep nodes few. If you need more than ~8 boxes, split into sections or switch shape. Bordered boxes are good; keep each box small, pad every interior line to the same width so the right border stays straight, keep interior content simple (ASCII or a uniform glyph), and route arrows and branches in the open space between boxes rather than inside them.

## Shape 3 — Stack / flamegraph

Use for call stacks, hot paths, profiles, nested durations, or "where did the time go". Width = time or share. Stacked rows = caller → callee (root on top or bottom; be consistent).

Flamegraph (root on top, width ∝ time):

```text
main                                                          1000 ms
████████████████████████████████████████████████████████████
  handleRequest                                               820 ms
  ██████████████████████████████████████████████████
    parseBody                                                 120 ms
    ███████
    queryDB                                                   560 ms
    ██████████████████████████████████
      serialize                                                90 ms
      █████
    render                                                    140 ms
    ████████
  log                                                         180 ms
  ██████████
```

Call stack / call tree (causality and nesting, no time axis). Use an indented tree with `→` arrows in a language-tagged code block so identifiers get syntax highlighting:

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

Rules:

- **trees:** 2-space indent per level, `→` on every child, one exact identifier per line (`Module.method()`); separate independent stacks with a blank line under a heading; tag the block (`ts`, `py`, `go`, …) so identifiers highlight.
- **flamegraphs:** align all bars to the same left edge, label first then bar, show time/% on the right, collapse irrelevant frames into `…`.

## Shape 4 — Timeline

Use when the X axis is time and you need to show events or ranges.

```text
Sun        Mon        Tue        Wed        Thu        Fri
 │          │          │          │          │          │
 │          ▲          │          │          │          │
 │     deploy v2
 │          █████████████████████████████████████████████
 │          ▲
 │      canary window
```

## Shape 5 — XY plot

Use when a value changes over a continuous axis (time, distance, progress) and the *shape of the curve* is the point: growth, drift, deltas, spread. Y axis labeled on the left, X axis along the bottom with an arrow, `┤` / `┼` for tick joints.

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

Signed values around a zero baseline (delta above/below a reference):

```text
 +Δ ┤      ▇  ▇
    │   ▇  ▇  ▇  ▇
  0 ┼──────────────────────────▶ progress
    │            ▇  ▇  ▇
 −Δ ┤               ▇
    0                          1   +Δ behind · −Δ ahead · 0 reference
```

Curve plus an envelope/spread band (`█` actual run, `░` ±σ band):

```text
e + ┤                       ░░░░
    │              ░░░░░░░░░░░░░
  0 ┤█░█░░░░░█░█░░░░░░░░░█░█░░░░
    │  ░░░░░█░░░░█░░░░█░█░░░░░░
e − ┤             ░░░░░░░░░░░░░
    └──────────────────────────▶ t
```

Rules for XY plots:

- label the Y axis above the top tick; put the X axis label after the arrow
- use `┤` for plain ticks, `┼` where a zero/baseline line crosses
- keep one glyph per column so points stay vertically aligned
- legend goes on one line under the plot, not inside it

## Shape 6 — Layout / geometry

Use for memory and buffer layouts, on-disk formats, or spatial/vector relationships — anything where *position* carries the meaning.

Ring buffer / memory layout:

```text
        head ─┐ (next write)
 idx:  0    1    2    3   …   15
      ╭────┬────┬────┬────┬────╮
      │ t₀ │ t₁ │ t₂ │ t₃ │ t₁₅│   timestamps (µs)
      ╰────┴────┴────┴────┴────╯
        ↑ oldest          newest ↑
```

Geometric projection (project a point onto the nearest segment):

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

## Rules

- **Separate rendering:** put every ASCII diagram, chart, table, tree, or layout in its own fenced code block (normally `text`; use a language tag for a call tree when syntax highlighting is useful). Never place explanatory prose, headings, conclusions, or Markdown lists inside an ASCII code block.
- Write all ordinary explanation as normal rendered Markdown before or after the block. Do not make the user manually separate prose from a copied diagram.
- Return one `text` code block containing only the diagram when the user asks for a single ASCII output.
- Do not use Mermaid or other rendered diagram syntaxes.
- Keep labels short; include only the details needed to make the point.
- Prefer vertical sections over one huge crowded diagram.
- End with a compact summary box only when there is a decision or conclusion worth restating.

### Width safety (keep bordered boxes aligned)

Bordered boxes read well and are encouraged when a boundary carries meaning. A right border only stays straight when every interior line has the **same display width**, so the drift you see is a width-consistency problem, not a reason to drop borders. A tall box with a different arrow on each interior line is the usual cause. Follow this recipe:

- **Pad every interior line to one width.** Between `│ … │` pad each line with trailing spaces to the identical width, and make the top and bottom border (`─` run) that same width. That is what keeps the right border aligned.
- **Keep interiors simple.** Prefer ASCII text (every character is one cell, so the count is reliable) or a single uniformly repeated glyph (`●●●●●`). Small, uniform interiors pad correctly; tall boxes packed with varied content drift.
- **Put flow outside the box.** Route arrows, branches, and connectors (`│ ▼ ├ ─▶`) in the open space around boxes, not on interior lines. Different arrows on different interior lines are the main cause of drift.
- **One box, one idea.** Split a tall multi-line box into small boxes joined by external connectors instead of stacking many aligned rows inside one border.
- **Pick one glyph family.** Do not mix arrow styles (`→ ▶` vs `◄ ⤷`) in the same diagram, so width assumptions stay consistent. Some glyphs are East Asian "Ambiguous" width (`→ ▶ ▲ ▼ │`) and render as 1 or 2 cells depending on the terminal; others are always 1 cell (`◄ ↻ ⤷`).

Bordered box with the flow kept outside (aligns reliably):

```text
        ╭─────────────╮
in ────▶│  worker: 5  │────▶ out
        ╰──────┬──────╯
               │ overflow
               ▼
            dropped
```
