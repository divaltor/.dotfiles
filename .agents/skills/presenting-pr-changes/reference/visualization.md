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
5. **Encoding:** which channel carries it, and whether color highlights one result or distinguishes several stages.
6. **Scales:** zero or not, linear or log.
7. **Guides:** only the labels, ticks and notes the reader needs to check the claim.

Most failed charts plot raw data in a default form and then write a title the chart does not show. Work down the list instead.

## Transform the data to the claim

- "X got 3× faster": plot the multiple, or both values indexed to before, with a rule at 1×.
- "X is 38% of Y": draw the share as a length (one stacked bar), not two raw counts.
- "N% finish within X": draw the cumulative share with a rule at N%.
- Groups of different sizes: plot a rate per unit, and name the denominator in the subtitle.
- Before and after: use outlined bars on one zero-based axis, project the before endpoint to the after row and hatch the reduction span. Put its delta below the span when it is too narrow to hold text; never widen it to fit. Repeat the same construction for several items, keeping one scale.

## Pick the form by the question

| Question | Form | Template |
| --- | --- | --- |
| Parts of a total, before and after | outlined stacked bars, changed part first, hatched reduction to the before total | `chart.html`, `type: 'stacked'` |
| Before/after reduction | outlined bars with a hatched reduction span and baseline projection | `chart.html`, `type: 'reduction'` |
| Three or more successive stages | separate outlined bars per stage, one shared zero-based scale | `chart.html`, `type: 'grouped'` |
| Ranking or counts (findings per rule, files per team) | outlined horizontal bars sorted by value, named result lightly tinted; no delta hatching | `chart.html`, `type: 'bars'` |
| What held when, in which order (a race, a leak across an await, a retry) | before and after lanes on one shared axis of stages, with labeled regions | `timeline.html` |
| What talks to what, or work moving across a boundary (deferred import, new queue, removed hop) | before and after blueprint diagram, same positions | `diagram.html` |
| One or two numbers | a sentence in the Slack message, not an image | none |

Never let area or angle carry the point: no pies, donuts, bubbles or treemaps. Never use two y axes.

## Encode by accuracy

Readers judge position best, then length, then angle and area, then color. Put the compared quantity on position or length, on a common baseline. In a stacked bar only the first part has a common baseline, so put the part the claim is about first. Never stack successive stage measurements: they are not additive parts. Color highlights the named result or identifies stages; it never carries a value on its own.

## Scales

- Bars start at zero, because length encodes the value. Lines may start above zero, because only position does; pick round ticks that cover min to max.
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
2. Default to one named result in `--accent`. For multiple stages, use gray (`--context`) for the baseline, blue (`--accent`) for the first change and teal (`--stage-next`) for the next; add another distinct hue only when another measured stage requires it. Label stages directly rather than relying on color alone.
3. One hue means one thing across the whole image: if accent is "after", it is "after" everywhere.
4. `--worse` appears only when a number got worse or a state is broken. It means bad, never a category.
5. Never put text on a saturated fill, and never use gradients, glows, tinted backgrounds or colored side borders.
6. Mark "not taken" or "not yet" with `--context`, dashes or an outline, not with opacity on text.

## Anatomy

- Title 34px, weight 600; subtitle 19px muted. No eyebrow label above the title.
- Plot: no frame, no background, no axis lines. Gridlines run only across the value axis, 1px `--line`.
- Every bar, part and span has a subtle 4px corner radius: ranking, stacked, reduction and timeline alike. Never square ends, never pills.
- Ranking bars: about 30% gap, value at the end; neutral outlines with 7.5% accent tint only on the named result. Stacked bars: outlined parts with light tint, no solid fills, a 2px gap between parts; project the before total and hatch any reduction. Reduction bars: 1.25px neutral before outline, 1.5px accent after outline with 7.5% fill, and a dashed hatched span to the projected baseline.
- Hatching is drawn at 1:1 pixels, so every hatched span has the same line weight and pitch.
- Text that sits over marks gets a halo (`paint-order: stroke; stroke: var(--bg); stroke-width: 6px` in SVG) so it stays readable.
- Never: chart frames, both axis lines, tick marks, rotated labels, smoothed curves, area fills, pill bars, 3D, rainbow series.

## Diagrams

Use technical-drawing discipline (from Plotter) with our Apple/Linear tokens and takeaway-first header. Never draw metaphorical objects or spot art (gears, locks, clouds, magnifiers): a PR diagram explains code structure, not a marketing concept.

### Pick the construction

Name the single construction relationship in one sentence before drawing — what splits, moves, intersects, batches, or connects. Every diagram uses one of these five shapes:

| Construction | Use when | Geometry rule |
| --- | --- | --- |
| **Split / deferral** | Memory, work, or cost leaves a shared stage for an optional or later stage | One full-width before bar splits along an exact vertical projection guide into retained (`--accent`) + vacated (`4 5` dash + hatch), with transfer arrows to the new owner. |
| **Routing (before/after)** | A request or pipeline adds a queue/cache/guard or drops a blocking hop | Keep unchanged nodes at identical `x` positions in both rows so the eye sees only the changed hop. Mark added with `+`, removed with `−` and a dashed outline. |
| **Overlap / boundary** | Permissions, IAM policies, locks, or time windows intersect | Align both scopes on one shared axis; shade (`fill-opacity: 0.075`) or hatch only the intersection region, never the whole bars. |
| **Fan-in / batching** | Parallel tasks wait on a join, or a large payload streams in fixed chunks | Draw the repeated units at one constant pitch projecting into the barrier or batch size, with one dimension on the chunk or wait bound. |
| **Relation / interface** | A schema migration, foreign key, or unified adapter joins N callers | Place callers on one edge and the shared contract or key column on the opposite edge; connect only the changed or enforced relation in `--accent`. |

### Drafting rules

- **Stroke hierarchy comes from opacity and dash, never thick borders.** Thick lines turn a schematic into a heavy wireframe.
  - Active / named result: `1.5px`, `--accent` (`--worse` for broken states), `fill-opacity: 0.075` only on the named result.
  - Retained neutral node: `1.25px`, `--ink` at `0.85` opacity.
  - Secondary / before state: `1.25px`, `--ink` at `0.45` opacity.
  - Projection guides: `1px`, `--ink` at `0.18` opacity. Always leave an **8px clearance** from shapes so guides align edges without crashing into contours.
  - Absent / vacated / removed region: `1.25px`, `stroke-dasharray="4 5"`, clipped `12px` 45° diagonal hatch when the vacated span is the claim.
  - Transfer / movement arrow: `1.25px`, `stroke-dasharray="4 5"` with an open 45° arrowhead. Always route elbows orthogonally with rounded corners (`Q`) so every arrowhead enters its target straight vertically or horizontally; diagonal entry into a vertical arrowhead reads as a drawing bug. Never draw an arrow for an unchanged part — projection guides alone show alignment, while arrows mean movement or change.
- **Dimensions earn their place.** Use split dimension lines with open `<` `>` arrowheads meeting witness lines only when they carry a label across a total or multi-part span. Never draw an unlabeled `<--->` arrow, never add decorative corner/edge registration ticks, and never draw a dimension line across a span already enclosed and labeled by a single box.
- **Timelines:** one shared axis of stage boxes, one lane per state or caller; every region starts and ends on a stage edge. A state that persists is one outlined run across its stages, lightly tinted in the lane tone (a restrained 1.25px outline for `--worse`). Hatch only the intervals where that state is broken, never the whole run. Cleared intervals are dashed outlines, gray unless they carry the outcome. Label each region inside itself, left-aligned with its stage label, and name events between stages (a `yield`, an `await`) with a labeled projection guide that stays 8px clear of bars and text. Put the outcome in the last region, not in a caption.
- **Boundaries:** group with a `1px` hairline outline and a top-left label, never a tinted card fill. Always run `python3 scripts/check.py` before `scripts/render.sh`.

## Layout

- Content sits straight on the page. Structure with space first, hairline rules second, surfaces last; use a surface only for something real, such as a code line.
- Space on an 8px scale: 8px inside a group, at least 24px between groups, more space above a heading than below it.
- Left-align everything on a few shared edges. Nothing centered.

## Check the claim before rendering

- Every number in the title is a labeled mark on the image.
- The title's verb matches the shape: "halved" needs a mark near half, "most" needs a share above 50%.
- Nothing on the page needs the PR to be understood.
- The subtitle or note names what the data cannot show.
- Bottom text explains the measurement source, aggregation, sample or limitation in short sentences. It does not give reader instructions, explain visual mechanics or sacrifice meaning to a word limit.
