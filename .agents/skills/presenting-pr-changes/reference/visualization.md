# Drawing the visual

Read this when transforming data to a claim, choosing scales/labels, or authoring `templates/diagram.html`.

## Layer order

Decide in order: **claim -> data -> transform -> form -> encoding -> scales -> guides**. Plotting raw data first and inventing a title afterward produces charts that do not prove their headline.

## Transform data to match the claim

- **"X got 3x faster":** plot the multiple or values indexed to `before` with a rule at `1x`.
- **"X is 38% of Y":** plot share as length (`stacked`, claimed part first so it shares the zero baseline).
- **"N% finish within X":** plot cumulative share with a dashed rule at `N%`.
- **Unequal group sizes:** plot a rate per unit and name the denominator in the subtitle.
- **Step-by-step budget or PR stack:** use `waterfall` so each change's contribution and any regression add up visually from `before` to `after`.
- **Utilization vs headroom (`used <= requested <= allocatable`):** use `timeseries` with `envelope` instead of stacking non-additive quantities.

Never use pies, donuts, bubbles, treemaps, dual y axes, smoothed curves, or 3D. Position and length carry comparisons; color only highlights the claim or separates stages.

## Scales and direct labels

- **Zero baseline on every bar chart (`reduction`, `stacked`, `grouped`, `columns`, `waterfall`, `bars`).** Length encodes value; truncating zero exaggerates the change. Line charts (`timeseries`) may start above zero when needed, with 3-5 round ticks.
- **Log scale** past ~2 orders of magnitude (ticks `1, 10, 100, 1k`), stated in the subtitle.
- **Direct labels over legends.** Put values at bar ends or inside tall vertical bars, and label time-series lines directly at their peak or right edge (`paint-order: stroke; stroke: var(--bg); stroke-width: 5px` halo). Use a swatch legend only when marks cannot hold names (e.g. `columns`).
- **Units on the top/last tick only.** Never rotate tick labels. Keep at most three annotations (dashed event rule or reference threshold).
- **Long code identifiers** go in mono on their own line above a horizontal row (`reduction`, `grouped`).

## Blueprint diagrams (`templates/diagram.html`)

Name the single construction relationship in one sentence before editing the SVG. Never draw spot art or metaphors (clouds, gears, locks).

| Construction | Use when | Geometry rule |
| --- | --- | --- |
| **Split / deferral** | Work or memory leaves a shared stage for a later/optional stage | One full-width `before` bar splits along an exact vertical projection guide into retained (`--accent`) + vacated (`4 5` dash + hatch), with transfer arrows to the new owner. |
| **Routing (before/after)** | A pipeline adds a cache/queue/guard or drops a hop | Keep unchanged nodes at identical `x` in both rows so only the changed hop moves. Mark added with `+`, removed with `−` and dashed outline. |
| **Overlap / boundary** | Permissions, locks, or time windows intersect | Align both scopes on one axis; tint (`0.08`) or hatch only the intersection. |
| **Fan-in / batching** | Parallel tasks join on a barrier or stream in chunks | Draw repeated units at constant pitch projecting into the barrier, with one dimension on the chunk or wait bound. |
| **Relation / interface** | A schema key or adapter unifies N callers | Place callers on one edge and the shared contract on the opposite edge; highlight only the changed edge in `--accent`. |

### Drafting rules

- **Stroke hierarchy (never thick borders):** active/result `1.5px` `--accent` (`0.08` fill), retained neutral `1.25px` `--ink` (`0.85` opacity), secondary/before `1.25px` `--ink` (`0.4` opacity, `--base-fill`), projection guides `1px` `--ink` (`0.18` opacity) with **8px clearance** from shapes, vacated regions `1.25px` `4 5` dash + 1:1 diagonal hatch.
- **Transfer arrows:** `1.25px`, `4 5` dash, open 45 deg arrowhead, orthogonal elbows with rounded corners (`Q`) so every arrowhead enters strictly vertically or horizontally. Never draw arrows for unchanged parts; use projection guides.
- **Dimensions:** split dimension lines with open `<` `>` arrowheads only for totals or multi-part spans not already labeled by a single box. Never draw unlabeled dimension arrows or corner ticks.
- **Timelines (`templates/timeline.html`):** one shared axis of stage boxes; adjacent `set` and `broken` regions merge into one outlined run, with hatching only over broken intervals. Cleared intervals use dashed outlines. Event guides stay 8px clear of bars and text.
