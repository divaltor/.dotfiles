# Taste: Apple and Linear

Rules for a calm, neutral look that applies to a still image. Each rule says why, so it can be applied to cases it does not name.

## Attention

- **Supporting elements recede; only the claim is at full strength.** Ticks, gridlines, legends and notes are muted and small; the title, the highlighted marks and their values are ink.
  Why: Linear, "Don't compete for attention you haven't earned". Its sidebar was dimmed so the work area wins; a chart's chrome is the sidebar.
- **Every element must survive "what breaks if this is gone?".**
  Why: Apple, Purpose. Every element spends the reader's attention, and an image read in 30 seconds has none to spare.
- **Simplicity, not minimalism.** Add the label, unit or baseline the reader needs to check the claim, even if the page gets busier.
  Why: Apple, Simplicity. "Sometimes adding context simplifies"; a bare chart that hides its unit looks clean and fails.

## Hierarchy

- **Build hierarchy from lightness first, then size, then weight.** Two text colors (`--ink`, `--muted`), four sizes, and weight 600 only for the title.
  Why: Linear worked in "opacities of black and white" to set hierarchy, and Apple builds hierarchy from weight, size and leading as one set, not size alone.
- **Content gets more contrast, not less.** Body text and values are near-black on near-white; muted text still passes 4.5:1.
  Why: Linear's redesign made text "darker in light mode" because content stands out from chrome by contrast, and the image is often viewed scaled down in Slack.

## Structure

- **Structure should be felt, not seen.** Use space and alignment before rules, rules before boxes, and never a box around a chart.
  Why: Linear, "Structure should be felt not seen": borders had "quietly proliferated" and were removed or softened.
- **Align every label, mark and value on a few shared edges.**
  Why: Linear aligned sidebar labels and icons both ways: "you won't see it at once, but you'll feel it". Apple, Craft: every spacing and alignment value is a choice you can defend.
- **Place a label next to the mark it names.** Direct labels over legends; values at bar ends.
  Why: Apple, Grouping and mapping. Proximity implies relationship; if a mark needs a legend lookup, the mapping is weak.

## Color

- **Neutral and timeless: grays with almost no chroma, slightly warm.** The canvas is near-white, never tinted paper or a brand color.
  Why: Linear limited "how much chrome (blue)" went into its neutrals, then moved to "a warmer gray that still feels crisp", warning that too warm turns muddy.
- **Define colors in a perceptual space (OKLCH) from a few inputs: base, accent, contrast.**
  Why: Linear rebuilt its themes in LCH from three inputs because equal lightness then looks equally light, so the accent and the regression color carry the same weight.
- **One accent, and it always means the same thing.**
  Why: Apple, Familiarity: things that look the same must behave the same. A reader who learned "blue is after" on one chart reads every chart that way.

## Type

- **One sans with optical sizes, one mono drawn on the same proportions.** Inter's variable `opsz` axis switches to its Display cut at headline sizes. Geist Mono (x-height 0.530 of the em against Inter's 0.546) sets inline at `0.94em`, so its x-height sits just under Inter's; matching it exactly makes the wider mono glyphs read larger than the text around them.
  Why: Linear uses "Inter Display to add more expression to our headings" and regular Inter for the rest. Apple: default to a face with optical sizing and tracking tables. Faces that disagree on x-height and width, such as IBM Plex Sans with narrow Ioskeley Mono, read as an accident.
- **Tracking follows size.** About `-0.022em` on the 34px title, `-0.011em` at 19px, `0` at 17px and below.
  Why: Apple, *Details of UI Typography*: large type reads too loose at its default fit; small type needs its default spacing.
- **Leading follows size inversely.** About `1.15` on titles, `1.45` on notes.
  Why: Apple: tight on large headings, looser on body copy.
- **Digits are tabular wherever they line up, and minus is a real `−`.**
  Why: columns of values only compare at a glance when the digits align.

## Tokens

Generated from three inputs: base hue 80 (warm), chroma kept under 0.01 for neutrals, accent hue 256.

| Token | Value | Use |
| --- | --- | --- |
| `--bg` | `oklch(99.3% 0.002 80)` | Canvas |
| `--surface` | `oklch(96.8% 0.003 80)` | Code lines, diagram nodes, timeline segments |
| `--line` | `oklch(91.5% 0.004 80)` | Gridlines, dumbbell connectors, hairline rules |
| `--context` | `oklch(76% 0.006 80)` | Data marks that are not the point (before, other parts, other bars) |
| `--muted` | `oklch(47% 0.008 80)` | Secondary text, ticks, notes |
| `--ink` | `oklch(20% 0.005 80)` | Titles, values, primary text |
| `--accent` | `oklch(55% 0.19 256)` | The one thing the title names (after, the fixed state) |
| `--worse` | `oklch(55% 0.2 27)` | A number that got worse, a broken state |
