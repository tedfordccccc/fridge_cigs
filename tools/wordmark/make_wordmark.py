"""Generate the shaded Spencerian wordmark SVG used in the app header.

Technique: shape the text with Pinyon Script (SIL OFL), then stamp the glyph outlines
repeatedly along the x-axis ("broad nib" offset). Near-vertical downstrokes thicken a lot,
horizontal hairlines barely change, which mimics pressed steel-nib shading.

Usage:  python3 make_wordmark.py "Fridge Cig Report" -o wordmark.svg [--nib 21 --stroke 3 --track 40]
Deps:   pip install uharfbuzz fonttools svgpathtools
Style:  the SVG uses classes .pr-face and .pr-shadow; color them in CSS (fill + stroke).
"""
import argparse, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from glyphs import paths
from svgpathtools import parse_path

ap = argparse.ArgumentParser()
ap.add_argument("text"); ap.add_argument("-o", "--out", default="wordmark.svg")
ap.add_argument("--nib", type=int, default=21, help="offset span in font units/1000em; higher = bolder")
ap.add_argument("--track", type=int, default=40, help="extra letter spacing in font units")
a = ap.parse_args()

font = os.path.join(os.path.dirname(__file__), "PinyonScript-Regular.ttf")
ps, w, upm = paths(font, a.text, track=a.track)
s = 1000 / upm; d = " ".join(ps)
xmin, xmax, ymin, ymax = parse_path(d).bbox()
pad = 20
x0, y0 = xmin * s - pad, ymin * s - pad
W, H = (xmax - xmin) * s + a.nib + 2 * pad + 4, (ymax - ymin) * s + 2 * pad + 4
d = re.sub(r"-?\d+\.\d+", lambda m: str(round(float(m.group()), 1)), d)
uses = "".join(f'<use href="#pr-glyphs" x="{i}"/>' for i in range(0, a.nib + 1, 3))
svg = (f'<svg class="wordmark" viewBox="{x0:.0f} {y0:.0f} {W:.0f} {H:.0f}" role="img" aria-label="{a.text}" '
       f'xmlns="http://www.w3.org/2000/svg"><defs><path id="pr-glyphs" transform="scale({s:.5f})" d="{d}"/></defs>'
       f'<g class="pr-shadow" transform="translate(5,7)">{uses}</g><g class="pr-face">{uses}</g></svg>')
open(a.out, "w").write(svg)
print(f"wrote {a.out} ({len(svg)} bytes)")
