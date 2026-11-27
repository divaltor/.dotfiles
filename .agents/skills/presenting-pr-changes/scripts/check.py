#!/usr/bin/env python3
"""Pre-render lint for presenting-pr-changes HTML and inline SVG pages.

Catches structural and style faults before Chrome renders the PNG:
- banned SVG gradients, filters, shadows, or 3D/skew transforms
- stroked SVG text (unless using paint-order: stroke as a background halo)
- font-variant-ligatures (reset by font: shorthands; use font-feature-settings)
- all-caps SVG labels or upside-down rotated text
- hardcoded local font paths instead of {{FONTS}}
- missing data-height / data-fonts hooks required by render.sh
"""

import re
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path


def extract_static_svgs(html: str) -> list[str]:
    """Return top-level static <svg>...</svg> blocks outside <script> using stdlib HTMLParser."""
    starts = [0]
    for line in html.splitlines(keepends=True):
        starts.append(starts[-1] + len(line))

    def offset(pos: tuple[int, int]) -> int:
        line, col = pos
        return starts[line - 1] + col

    svgs: list[str] = []

    class SvgLocator(HTMLParser):
        def __init__(self) -> None:
            super().__init__(convert_charrefs=False)
            self.in_script = False
            self.svg_depth = 0
            self.svg_start: int | None = None

        def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
            if tag == "script":
                self.in_script = True
            elif tag == "svg" and not self.in_script:
                if self.svg_depth == 0:
                    self.svg_start = offset(self.getpos())
                self.svg_depth += 1

        def handle_endtag(self, tag: str) -> None:
            if tag == "script":
                self.in_script = False
            elif tag == "svg" and not self.in_script and self.svg_depth > 0:
                self.svg_depth -= 1
                if self.svg_depth == 0 and self.svg_start is not None:
                    end = html.find(">", offset(self.getpos()))
                    svgs.append(html[self.svg_start : len(html) if end == -1 else end + 1])
                    self.svg_start = None

        def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
            if tag == "svg" and not self.in_script and self.svg_depth == 0:
                svgs.append(self.get_starttag_text() or "")

    parser = SvgLocator()
    parser.feed(html)
    parser.close()
    return svgs


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1] if isinstance(tag, str) else ""


def parse_style(style: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for decl in (style or "").split(";"):
        name, sep, val = decl.partition(":")
        if sep:
            out[name.strip().lower()] = val.strip()
    return out


def check_svg(svg_text: str, idx: int) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    try:
        root = ET.fromstring(svg_text)
    except ET.ParseError as err:
        return [f"SVG #{idx}: malformed XML ({err})"], []

    if not root.get("viewBox"):
        errors.append(f"SVG #{idx}: missing viewBox attribute")

    def walk(node: ET.Element, inherited_stroke: str, turn: float) -> None:
        name = local(node.tag)
        styles = parse_style(node.get("style") or "")
        stroke = styles.get("stroke", node.get("stroke", inherited_stroke))
        paint_order = styles.get("paint-order", node.get("paint-order", ""))
        cls = node.get("class") or ""
        transform = styles.get("transform", node.get("transform") or "")
        turn += sum(float(a) for a in re.findall(r"rotate\(\s*(-?[\d.]+)", transform))

        if name in ("linearGradient", "radialGradient", "filter"):
            errors.append(f"SVG #{idx}: <{name}> is banned (no gradients, shadows, or filters)")
        if re.search(r"skew|rotate3d|perspective", transform):
            errors.append(f"SVG #{idx}: <{name}> uses banned transform {transform!r}")

        if name == "text":
            label = " ".join("".join(node.itertext()).split())
            shown = f'"{label[:40]}"'
            is_halo = "stroke" in paint_order or "halo" in cls.split()
            if stroke not in ("none", "") and not is_halo:
                errors.append(
                    f"SVG #{idx}: text {shown} inherits stroke={stroke!r}; "
                    "set stroke=\"none\" (or use paint-order: stroke only for a halo)"
                )
            if 90 < turn % 360 < 270:
                errors.append(f"SVG #{idx}: text {shown} is rotated {turn:g} deg (upside down)")
            if styles.get("text-transform") == "uppercase" or (
                re.search(r"\b[A-Z]{4,}\b", label)
                and label.upper() == label
                and not re.fullmatch(r"[A-Z0-9_.\-/ ]+", label)
            ):
                warnings.append(f"SVG #{idx}: text {shown} looks all-caps; prefer sentence case")

        for child in node:
            walk(child, stroke, turn)

    walk(root, root.get("stroke", "none"), 0.0)
    return errors, warnings


def check_html(path: Path) -> tuple[list[str], list[str]]:
    text = path.read_text(encoding="utf-8")
    errors: list[str] = []
    warnings: list[str] = []

    if "font-variant-ligatures" in text:
        errors.append("Use font-feature-settings: 'calt' 0, 'liga' 0, 'dlig' 0 instead of font-variant-ligatures")
    if "box-shadow" in text or "drop-shadow" in text:
        errors.append("Shadows are banned by taste.md")
    if "linear-gradient(" in text or "radial-gradient(" in text:
        errors.append("CSS gradients are banned by taste.md")
    if "dataset.height" not in text or "dataset.fonts" not in text:
        errors.append("Page must set document.body.dataset.height and document.body.dataset.fonts for render.sh")
    if re.search(r"file:///Users/[^'\"]+\.(ttf|woff2)", text):
        warnings.append("Hardcoded local font path found; prefer file://{{FONTS}}/ so render.sh stays portable")
    if "\u2014" in text:
        warnings.append("Em dash (—) found; SKILL.md prefers no em dashes")

    for i, svg in enumerate(extract_static_svgs(text), start=1):
        svg_errors, svg_warnings = check_svg(svg, i)
        errors.extend(svg_errors)
        warnings.extend(svg_warnings)

    return errors, warnings


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: check.py <page.html> [more.html ...]", file=sys.stderr)
        return 2

    exit_code = 0
    for arg in sys.argv[1:]:
        p = Path(arg)
        errors, warnings = check_html(p)
        for w in warnings:
            print(f"WARN  {p}: {w}")
        for e in errors:
            print(f"ERROR {p}: {e}")
            exit_code = 1
        if not errors and not warnings:
            print(f"OK    {p}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
