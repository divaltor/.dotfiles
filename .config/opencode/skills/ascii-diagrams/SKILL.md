---
name: ascii-diagrams
description: Use when the user asks for ASCII diagrams, timeline diagrams, flow diagrams, schedule explanations, or a single user-friendly ASCII output with Apple/Uber-like clean styling.
---

# ASCII Diagrams

Use this skill when a diagram will explain timing, data flow, state, architecture, comparisons, or operational behavior more clearly than prose.

Prefer ASCII diagrams when the user asks for:

- ASCII output, ASCII graph, or text-only diagram
- timeline or schedule explanation
- flow, pipeline, dependency, or lifecycle visualization
- side-by-side comparison
- a user-friendly diagram that can be pasted into Slack, docs, tickets, or PRs

## Style

Aim for clean, premium, Apple/Uber-like text styling:

- minimal visual noise
- generous spacing
- short headings
- boxed sections with rounded corners
- aligned columns and timelines
- clear labels close to the thing they explain
- one strong visual idea per section
- concise summary at the end

Use Unicode box drawing where helpful:

```text
╭────────────────────────────────────────────────────────────────────────────╮
│ Section title                                                              │
╰────────────────────────────────────────────────────────────────────────────╯
```

Use simple timeline markers:

```text
Sunday        Monday        Tuesday       Wednesday     Thursday      Friday
  │             │             │             │             │             │
  │             ▲             │             │             │             │
  │        important event
```

Use filled blocks to show selected ranges:

```text
Sunday        Monday        Tuesday       Wednesday     Thursday      Friday
  │             │             │             │             │             │
  │             █████████████████████████████████████████████████████████
  │             ▲
  │             starts here
```

## Rules

- Return the diagram as a single `text` code block when the user asks for a single ASCII output.
- Do not use Mermaid or other rendered diagram syntaxes.
- Keep labels short and readable.
- Avoid dense tables unless a table is the clearest shape.
- Prefer vertical sections over one huge crowded diagram.
- Include only the details needed to understand the point.
- End with a compact summary box when there is a decision or conclusion.

## Template

```text
╭────────────────────────────────────────────────────────────────────────────╮
│ Clear title                                                                │
╰────────────────────────────────────────────────────────────────────────────╯

Context line:
  short assumption or scenario


Section one
───────────

    Label A       Label B       Label C       Label D
      │             │             │             │
      │             ▲             │             │
      │        event or boundary

    Meaning:
    short explanation


Section two
───────────

    Label A       Label B       Label C       Label D
      │             │             │             │
      ██████████████████████████████████████████
      ▲
      starts here

    Meaning:
    short explanation


╭────────────────────────────────────────────────────────────────────────────╮
│ Summary                                                                    │
╰────────────────────────────────────────────────────────────────────────────╯

Option A:
  concise result

Option B:
  concise result
```
