"""Generate the PWA / home-screen icons: a red enamel sign tile with a cream inset border
and a script "F" (Pinyon Script, SIL OFL) with the deep-red drop shadow, matching the header.

Usage:  python3 tools/icons/make_icons.py      (writes web/public/icons/*.png)
Deps:   pip install pillow
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONT = os.path.join(ROOT, "tools", "wordmark", "PinyonScript-Regular.ttf")
OUT = os.path.join(ROOT, "web", "public", "icons")
RED, RED_INK, CREAM = "#c8102e", "#9e0b22", "#fbf5e6"


def tile(size, maskable=False):
    s = 4  # draw at 4x, then downsample for smooth edges
    S = size * s
    im = Image.new("RGBA", (S, S), RED if maskable else (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if not maskable:
        d.rounded_rectangle((0, 0, S - 1, S - 1), radius=int(S * 0.2), fill=RED)
    # Maskable icons get cropped to a circle by Android, so keep artwork in the middle 80%.
    inset = S * (0.16 if maskable else 0.07)
    d.rounded_rectangle((inset, inset, S - inset, S - inset), radius=int(S * 0.13),
                        outline=CREAM, width=max(2, int(S * 0.018)))
    font = ImageFont.truetype(FONT, int(S * (0.52 if maskable else 0.66)))
    l, t, r, b = d.textbbox((0, 0), "F", font=font)
    x, y = (S - (r - l)) / 2 - l, (S - (b - t)) / 2 - t
    off = S * 0.018
    for dx in range(0, int(S * 0.02) + 1, max(1, s)):  # thicken like the wordmark's broad nib
        d.text((x + dx + off, y + off * 1.4), "F", font=font, fill=RED_INK)
    for dx in range(0, int(S * 0.02) + 1, max(1, s)):
        d.text((x + dx, y), "F", font=font, fill=CREAM)
    return im.resize((size, size), Image.LANCZOS)


os.makedirs(OUT, exist_ok=True)
for name, size, mask in [("icon-192.png", 192, False), ("icon-512.png", 512, False),
                         ("icon-maskable-512.png", 512, True), ("apple-touch-icon.png", 180, True)]:
    tile(size, mask).save(os.path.join(OUT, name))
    print("wrote", name)
