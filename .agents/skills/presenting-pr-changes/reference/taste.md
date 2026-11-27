# Taste: Apple and Linear

Visual rules for a calm still image. Every rule carries its why so it generalizes to custom diagrams and edge cases.

## Attention and hierarchy

- **Supporting chrome recedes; only the claim is at full strength.** Ticks, gridlines, and notes use `--muted` and smaller type; titles, highlighted marks, and values use `--ink` or `--accent`.
  Why: an image read in 30 seconds in Slack cannot split attention between axes and the finding.
- **Build hierarchy from lightness first, then size, then weight.** Two neutral text levels (`--ink`, `--muted`), weight `600` only on the title; `--muted` still clears 4.5:1 contrast.
  Why: dark-on-light contrast holds up when Slack scales the PNG down.
- **Structure is felt, not seen.** Use whitespace and shared left edges first, hairline rules (`--line`) second, surfaces (`--surface`) only for real containers like code lines. Never box a chart.
  Why: borders multiply noise and compete with data marks.
- **Unboxed metric glyphs only.** When tagging a metric domain (`CPU`, `Memory`, `I/O`, `Latency`, `Cost`), use an unboxed 16px 1.35px-stroke glyph + sentence-case label above the title, never a bordered pill or uppercase eyebrow.
  Why: pills read as interactive buttons on a static image; uppercase eyebrows shout over the claim.

## Color and marks

- **Warm near-white canvas (`oklch(98.2% 0.005 90)`, `#faf9f5`).** Slightly warmer than pure white without turning into tinted paper.
  Why: matches light reading surfaces (Amp, docs, Slack) and avoids harsh glare while keeping neutral grays crisp.
- **Equal perceptual weight in OKLCH.** One accent (`--accent` blue) by default; add `--stage-next` (teal) for a second measured stage. Reserve `--worse` (red) strictly for regressions or broken states.
  Why: equal lightness in OKLCH gives blue, teal, and red equal visual weight; reusing red as a category breaks semantic trust.
- **Grounded baselines, light-tinted claims.** Baseline (`before`) bars fill with `--base-fill` (`oklch(95.4% 0.004 85)`) and a `1.25px` `0.4`-opacity ink outline; changed bars use a `1.5px` stroke and `8%` tint. Every bar uses a `4px` corner radius.
  Why: hollow transparent baselines read unfinished on `#faf9f5`, while heavy solid fills overpower direct value labels and hide projection guides.
- **Hatch only removed or broken spans at 1:1 pixels.** Never hatch rankings or healthy runs.
  Why: hatching isolates vacated work or broken intervals without introducing another hue.

## Typography

- **Inter (variable `opsz`) + Geist Mono at `0.94em`.** Tracking scales with size (`-0.022em` at 34px, `-0.011em` at 19px, `0` at 17px and below); leading scales inversely (`1.15` title, `1.45` body/notes).
  Why: Geist Mono's x-height (`0.530`) is wider than Inter (`0.546`); `0.94em` stops inline identifiers from reading oversized.
- **Tabular numerals everywhere digits align; real minus `−` (`\u2212`); mono ligatures off.** Always set `font-feature-settings: 'calt' 0, 'liga' 0, 'dlig' 0` (never `font-variant-ligatures`, which `font:` shorthands reset).
  Why: columns compare cleanly only with tabular digits, and ligatures turn `->` into an arrow that misquotes code.

## Tokens

| Token | Value | Use |
| --- | --- | --- |
| `--bg` | `oklch(98.2% 0.005 90)` | Canvas (`#faf9f5`) |
| `--surface` | `oklch(95.2% 0.005 85)` | Code lines, diagram nodes, timeline segments |
| `--base-fill` | `oklch(95.4% 0.004 85)` | Baseline (`before`) bars and requested envelopes |
| `--line` | `oklch(90.2% 0.006 85)` | Gridlines and hairline dividers |
| `--context` | `oklch(74% 0.007 85)` | Secondary marks and quiet traces |
| `--muted` | `oklch(46% 0.008 80)` | Subtitles, ticks, notes, metric labels |
| `--ink` | `oklch(20% 0.005 80)` | Titles, primary labels, values |
| `--accent` | `oklch(55% 0.19 256)` | Primary result or first changed stage |
| `--stage-next` | `oklch(49% 0.10 185)` | Second measured stage (teal) |
| `--worse` | `oklch(55% 0.2 27)` | Regression or broken state only |

### Accent overrides (`?theme=` or `DATA.colors`)

Keep the default `#faf9f5` canvas and neutral grays locked across every theme; optional color changes swap only accent tokens (`--accent`, `--stage-next`, `--worse`) via `?theme=ft`, `theme: 'ft'`, or `colors: { accent, 'stage-next', worse }`:

- **`ft` (FT peach accents on `#faf9f5`):** `--accent: oklch(57% 0.14 44)` (warm FT peach/terracotta), `--stage-next: #0d7680` (FT teal), `--worse: #990f3d` (FT claret).
