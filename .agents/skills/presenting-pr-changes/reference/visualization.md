# Drawing the visual

The output is one static PNG, 1080 CSS px wide, read in Slack or Jira for about 30 seconds. There is no hover and no second state: the image proves its point at rest or not at all.

## The standard

One point, legible in one second. Everything that is not the point is gray and smaller, so the point stands out. When in doubt, remove.

Images fail far more often because the chart does not show what the title claims than because they look wrong. So every image also proves its point:

- The title is the takeaway sentence, with its numbers.
- Every number in the title appears on the image as a labeled mark, computed from the data the page holds.
- The subtitle says what was measured, over what scope, and how the measure could mislead (a single run, a proxy metric, a partial period).

## Decide each layer in order

1. **Claim:** the sentence the reader takes away. It becomes the title.
2. **Data:** the rows the claim rests on, aggregated before they go into `DATA`.
3. **Transform:** the quantity the claim is about, computed from the rows.
4. **Form:** the mark that shows that quantity.
5. **Encoding:** which channel carries it, and which single thing gets color.
6. **Scales:** zero or not, linear or log.
7. **Guides:** only the labels, ticks and notes the reader needs to check the claim.

Most failed charts plot raw data in a default form and then write a title the chart does not show. Work down the list instead.

## Transform the data to the claim

- "X got 3× faster": plot the multiple, or both values indexed to before, with a rule at 1×.
- "X is 38% of Y": draw the share as a length (one stacked bar), not two raw counts.
- "N% finish within X": draw the cumulative share with a rule at N%.
- Groups of different sizes: plot a rate per unit, and name the denominator in the subtitle.
- Before and after: plot both values on one shared axis (dumbbell) or the difference, never two charts with separate scales.

## Pick the form by the question

| Question | Form | Template |
| --- | --- | --- |
| Parts of a total, before and after | one stacked bar per state, the part that changed at the bottom of the stack | `chart.html`, `type: 'stacked'` |
| One value per item, before and after | dumbbell on a shared axis | `chart.html`, `type: 'dumbbell'` |
| Ranking or counts (findings per rule, files per team) | horizontal bars sorted by value, one highlighted | `chart.html`, `type: 'bars'` |
| What held when, in which order (a race, a leak across an await, a retry) | before and after lanes on one shared axis | `timeline.html` |
| What talks to what, and which edge the change adds or removes | before and after diagram, same positions | draw by hand, see Diagrams |
| One or two numbers | a sentence in the Slack message, not an image | none |

Never let area or angle carry the point: no pies, donuts, bubbles or treemaps. Never use two y axes.

## Encode by accuracy

Readers judge position best, then length, then angle and area, then color. Put the compared quantity on position or length, on a common baseline. In a stacked bar only the first part has a common baseline, so put the part the claim is about first. Color picks out the one thing the title names; it never carries a value on its own.

## Scales

- Bars start at zero, because length encodes the value. Dumbbells and lines may start above zero, because only position does; pick round ticks that cover min to max.
- Use a log scale past about two orders of magnitude, with human ticks (1, 10, 100, 1k), and say "log scale" in the subtitle.
- Leave headroom so the largest mark does not touch the edge.

## Labels and annotations

- Label values at the end of bars and drop the value axis when every bar has its value.
- Name series directly on the marks of the first row, in the series color. A swatch legend is the last resort.
- Units go on the last tick only. Ticks: 3–5 at round values, never rotated.
- At most three annotations. Mark a reference value as a dashed `--context` rule with a short label, and the moment that explains the title as a labeled rule.
- Identifiers (DAG ids, functions, config keys) are mono and sit on their own line above their row when they are long.

## Color

1. Draw everything in grays first.
2. Color only what the title names: one thing in `--accent`. A second named thing gets `--ink`, not a second hue.
3. One hue means one thing across the whole image: if accent is "after", it is "after" everywhere.
4. `--worse` appears only when a number got worse or a state is broken. It means bad, never a category.
5. Never put text on a saturated fill, and never use gradients, glows, tinted backgrounds or colored side borders.
6. Mark "not taken" or "not yet" with `--context`, dashes or an outline, not with opacity on text.

## Anatomy

- Title 34px, weight 600; subtitle 19px muted. No eyebrow label above the title.
- Plot: no frame, no background, no axis lines. Gridlines run only across the value axis, 1px `--line`.
- Bars: square ends, about 30% gap, value at the end. Dots: 14px. Connecting lines: 3px `--line`.
- Text that sits over marks gets a halo (`paint-order: stroke; stroke: var(--bg); stroke-width: 6px` in SVG) so it stays readable.
- Never: chart frames, both axis lines, tick marks, rotated labels, smoothed curves, area fills, rounded or pill bars, 3D, rainbow series.

## Diagrams

- Draw the mechanism, not its name. A box labeled "cache" says less than a sentence; draw the path through it and the edge that disappears when it is removed.
- The title states the rule the diagram explains ("Team context now ends at every `yield`"), not its subject ("Trigger context handling").
- The path the title is about is in `--accent` (or `--worse` for the broken state) at full ink; everything else is `--muted` or `--context`.
- Timelines: one shared horizontal axis, one lane per state or caller, bar length is duration and position is when. Put each lane's outcome at its right end; mark the moment that breaks things with one labeled rule.
- Before and after: same scale, same positions, so only the changed parts move. Mark added with `+`, removed with `−` and a dashed outline, always as a glyph next to the name, never color alone.
- Nodes: a `--surface` box with 6px corners, name in `--ink`, at most one muted subtitle. Edges: 1.5px `--muted` (2px accent for the highlighted path), straight or orthogonal, one small arrowhead, every edge labeled with what it carries.
- Group by boundary with a hairline outline and a small label at its top left, never a tinted fill.

## Layout

- Content sits straight on the page. Structure with space first, hairline rules second, surfaces last; use a surface only for something real, such as a code line.
- Space on an 8px scale: 8px inside a group, at least 24px between groups, more space above a heading than below it.
- Left-align everything on a few shared edges. Nothing centered.

## Check the claim before rendering

- Every number in the title is a labeled mark on the image.
- The title's verb matches the shape: "halved" needs a mark near half, "most" needs a share above 50%.
- Nothing on the page needs the PR to be understood.
- The subtitle or note names what the data cannot show.
