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

Decision checklist before drawing:

1. Is the answer fundamentally **a number, ratio, or short list**? → simple ASCII, not a flow.
2. Does the explanation require **arrows between distinct nodes**? → flow.
3. Is it about **where time/CPU/memory is spent** or **nested call relationships**? → flamegraph or stack.
4. Is the X axis **time**? → timeline.
5. If two shapes fit, pick the smaller one.

When in doubt, prefer the simplest shape that still answers the question.

## Style

Aim for clean, premium, Apple/Uber-like text styling:

- minimal visual noise
- generous spacing
- short headings
- boxed sections with rounded corners only when they add clarity
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

Keep nodes few. If you need more than ~8 boxes, split into sections or switch shape.

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

Rules for call stacks / trees:

- use 2-space indent per level, `→` prefix on every child
- one call per line; keep identifiers exact (`Module.method()`)
- group independent stacks under a plain heading line, separated by a blank line
- pick a language tag (`ts`, `py`, `go`, …) so identifiers highlight
- omit args unless they carry the explanation; never invent types

Rules for flamegraphs:

- align all bars to the same left edge
- one frame per line, label first then bar
- show absolute time or % on the right
- only include frames that matter; collapse the rest into `…`

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

## Rules

- Return the diagram as a single `text` code block when the user asks for a single ASCII output.
- Do not use Mermaid or other rendered diagram syntaxes.
- Keep labels short and readable.
- Avoid dense tables unless a table is the clearest shape.
- Prefer vertical sections over one huge crowded diagram.
- Include only the details needed to understand the point.
- End with a compact summary box only when there is a decision or conclusion worth restating.
- Never wrap a simple number, ratio, or 2-line answer in a flow diagram.
