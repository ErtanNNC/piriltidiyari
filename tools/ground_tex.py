#!/usr/bin/env python3
"""Turn a FLUX ground drawing into a seamless grey detail map for
WorldLook.ground_detail (assets/textures/<name>.png, 512 px, mean 0.5).

  python3 tools/ground_tex.py work/free_model/zemin_cayir_42.webp zemin_cayir [--crop 0.1]

--crop trims that fraction from every side first (drawings with a border).
The floors keep their own colours: only light/dark detail is taken.
"""
import argparse
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("name")
    ap.add_argument("--crop", type=float, default=0.08)
    ap.add_argument("--contrast", type=float, default=0.16)
    a = ap.parse_args()
    im = Image.open(a.src).convert("RGB")
    w, h = im.size
    c = a.crop
    im = im.crop((int(w * c), int(h * c), int(w * (1 - c)), int(h * (1 - c)))).resize((512, 512), Image.LANCZOS)
    px = np.asarray(im).astype(np.float32)
    # seamless: blend with a half-shifted copy, weighted by distance to the edges
    shifted = np.roll(np.roll(px, 256, 0), 256, 1)
    y, x = np.mgrid[0:512, 0:512] / 511.0
    edge = np.minimum(np.minimum(x, 1 - x), np.minimum(y, 1 - y))
    wgt = np.clip(edge / 0.25, 0, 1)[..., None]
    out = px * wgt + shifted * (1 - wgt)
    lum = out @ np.array([0.299, 0.587, 0.114])
    lum = (lum - lum.mean()) / (lum.std() + 1e-6) * a.contrast + 0.5
    dst = os.path.join(ROOT, "assets", "textures", a.name + ".png")
    Image.fromarray(np.clip(lum * 255, 0, 255).astype(np.uint8)).save(dst)
    print("doku:", dst)


if __name__ == "__main__":
    main()
