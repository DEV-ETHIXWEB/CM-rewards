#!/usr/bin/env python3
"""Rebuild assets/images/logo_dark.png from the full-colour logo.

The supplied mark is drawn for light paper: the "Center Market" wordmark is
burgundy, which all but vanishes against the dark theme's near-black page. This
repaints the wordmark ivory and lifts the two swooshes to their dark-mode
tints, so the mark keeps its exact shape and brand colours while staying
legible without a plate behind it.

Requires Pillow, numpy and scipy:  python3 scripts/make_dark_logo.py
"""

import pathlib

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/images/logo.png"
OUT = ROOT / "assets/images/logo_dark.png"

WORDMARK = (0xFA, 0xF6, 0xF1)  # Brand.ivory
BURGUNDY = (0xBE, 0x2A, 0x57)  # a lifted Brand.burgundyBright
GREEN = (0x1F, 0xA3, 0x4A)  # a lifted Brand.green
WIDTH = 464  # half the source: ample for the 38 dp header mark at 3x

image = np.array(Image.open(SRC).convert("RGBA"))
alpha = image[..., 3]
red, green, blue = (image[..., i].astype(int) for i in range(3))

solid = alpha > 150
burgundy = solid & (red > green + 20) & (red >= blue)
greens = solid & (green > red + 10)

# The two swooshes are one big connected run of burgundy; every other burgundy
# island is a letter or one of the dots under "Market".
labels, count = ndimage.label(burgundy)
largest = int(np.argmax(ndimage.sum(burgundy, labels, range(1, count + 1)))) + 1
swoosh = labels == largest

# Edge pixels are part-transparent blends of two colours, so rather than
# thresholding them into the wrong region each one takes the colour of the
# nearest solid pixel. That keeps the antialiasing clean after recolouring.
regions = np.zeros(alpha.shape, np.uint8)
regions[swoosh] = 1
regions[burgundy & ~swoosh] = 2
regions[greens] = 3
_, (rows, cols) = ndimage.distance_transform_edt(regions == 0, return_indices=True)
nearest = regions[rows, cols]

out = np.zeros(image.shape, np.uint8)
out[..., 3] = alpha
for region, colour in ((1, BURGUNDY), (2, WORDMARK), (3, GREEN)):
    out[nearest == region, :3] = colour

result = Image.fromarray(out)
result = result.resize((WIDTH, round(result.height * WIDTH / result.width)), Image.LANCZOS)
result.save(OUT, optimize=True)
print(f"wrote {OUT.relative_to(ROOT)} {result.size}")
