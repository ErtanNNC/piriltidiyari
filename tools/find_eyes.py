#!/usr/bin/env python3
"""Find the two eyes on front shots of the imported characters, for blinking.

  godot ... -- --scene=preview --demo=eyes --out=DIR | grep -E "EYESHOT|EYEZ" > DIR/map.txt
  python3 tools/find_eyes.py DIR [--write]
  (run both twice: the second run adds each eye's depth from the model)

Each shot is orthographic from the front (camera centered on x=0, y=height/2,
`size` meters tall over 720 px). The eyes are the two round dark blobs (the
big pupils of the art) side by side in the upper part. Prints them as
fractions of the model's height ([x, y, r]) plus the skin color above them
(the eyelid color); --write stores "eyes" and "lid" in assets/models/<id>.json.
DIR/check.png shows what was found.
"""
import json
import os
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageDraw

W, H = 1280, 720
# found wrong (hands on a dark cloak): keep these jsons as they are
SKIP = {"miril"}


def components(mask):
    seen = np.zeros(mask.shape, bool)
    out = []
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        pts = []
        while q:
            y, x = q.popleft()
            pts.append((y, x))
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        out.append(np.array(pts))
    return out


def find(path, h, size):
    for limit in (0.36, 0.24, 0.16):
        res = _find(path, h, size, limit)
        if res:
            return res
    return None


def _find(path, h, size, limit):
    im = np.asarray(Image.open(path).convert("RGB")).astype(float) / 255.0
    bg = np.median(im[5:20, 5:20].reshape(-1, 3), axis=0)
    lum = im @ np.array([0.299, 0.587, 0.114])
    lum = lum / max(bg.mean(), 0.2)
    sat = im.max(axis=2) - im.min(axis=2)
    ppm = H / size  # pixels per meter
    dark = (lum < limit) & (sat < 0.45)
    # meters -> only the upper 3/4, skip the outer border
    cand = []
    for c in components(dark):
        n = len(c)
        if n < 40:
            continue
        y0, x0 = c.min(axis=0)
        y1, x1 = c.max(axis=0)
        bw, bh = x1 - x0 + 1, y1 - y0 + 1
        if not (0.55 < bw / bh < 1.8):
            continue
        if n / (bw * bh) < 0.45:
            continue
        r_m = max(bw, bh) / 2 / ppm
        if not (0.014 * h < r_m < 0.16 * h):
            continue
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        xm = (cx - W / 2) / ppm
        ym = h / 2 + (H / 2 - cy) / ppm
        if ym < 0.3 * h:
            continue
        cand.append({"x": xm, "y": ym, "r": r_m, "n": n, "px": (cx, cy, max(bw, bh) / 2)})
    best = None
    for i, a in enumerate(cand):
        for b in cand[i + 1:]:
            if a["x"] * b["x"] >= 0:
                continue
            if abs(a["y"] - b["y"]) > 0.06 * h or max(a["n"], b["n"]) > 2.2 * min(a["n"], b["n"]):
                continue
            score = a["n"] + b["n"] - abs(a["x"] + b["x"]) * ppm * 10
            if best is None or score > best[0]:
                best = (score, a, b)
    if best is None:
        return None
    _, a, b = best
    eyes = sorted([a, b], key=lambda e: -e["x"])  # left (+x) first
    # eyelid: the skin just above both eyes
    samples = []
    arc = []
    for e in eyes:
        cx, cy, rp = e["px"]
        for k in range(-8, 9):
            a = np.pi * (0.5 + k / 12.0)  # an arc over the eye
            px = int(cx + np.cos(a) * rp * 1.5)
            py = int(cy - np.sin(a) * rp * 1.5)
            if 0 <= px < W and 0 <= py < H:
                arc.append(im[py, px])
                if lum[py, px] > limit + 0.08 and lum[py, px] < 0.97:
                    samples.append(im[py, px])
    lid = np.median(np.array(samples if len(samples) > 4 else arc), axis=0)
    return eyes, lid


def pretty(opts):
    """json with one key per line but short number lists kept on one line."""
    import re
    text = json.dumps(opts, indent="\t", ensure_ascii=False)
    return re.sub(r"\[\s*([-0-9.,\s]+?)\s*\]", lambda m: "[" + ", ".join(x.strip() for x in m.group(1).split(",")) + "]", text)


def main():
    d = sys.argv[1]
    write = "--write" in sys.argv
    root = os.path.join(os.path.dirname(__file__), "..", "assets", "models")
    lines = open(os.path.join(d, "map.txt")).read().splitlines()
    rows = [l.split() for l in lines if l.startswith("EYESHOT")]
    # depths come from the same demo once the eyes are in the json (2nd run)
    depth = {l.split()[1]: [float(v) for v in l.split()[2:4]] for l in lines if l.startswith("EYEZ")}
    tiles = []
    for _, mid, h, size in rows:
        h, size = float(h), float(size)
        png = os.path.join(d, mid + ".png")
        res = find(png, h, size)
        im = Image.open(png).convert("RGB")
        dr = ImageDraw.Draw(im)
        if res is None:
            print(mid, "no eyes")
        else:
            eyes, lid = res
            hexc = "#%02x%02x%02x" % tuple(int(v * 255) for v in lid)
            out = [[round(e["x"] / h, 4), round(e["y"] / h, 4), round(e["r"] * 1.15 / h, 4)] for e in eyes]
            if mid in depth:
                out = [o + [depth[mid][k]] for k, o in enumerate(out)]
            print(mid, json.dumps(out), hexc)
            if mid in SKIP:
                continue
            for e in eyes:
                cx, cy, rp = e["px"]
                rp *= 1.15
                dr.ellipse([cx - rp, cy - rp, cx + rp, cy + rp], outline=(255, 0, 0), width=3)
            dr.rectangle([0, 0, 60, 60], fill=tuple(int(v * 255) for v in lid))
            if write:
                jp = os.path.join(root, mid + ".json")
                opts = json.load(open(jp)) if os.path.exists(jp) else {}
                opts["eyes"] = out
                opts["lid"] = hexc
                open(jp, "w").write(pretty(opts) + "\n")
        dr.text((70, 10), mid, fill=(0, 0, 0))
        tiles.append(im.crop((340, 0, 940, 720)).resize((300, 360)))
    sheet = Image.new("RGB", (300 * 5, 360 * ((len(tiles) + 4) // 5)), "white")
    for i, t in enumerate(tiles):
        sheet.paste(t, ((i % 5) * 300, (i // 5) * 360))
    sheet.save(os.path.join(d, "check.png"))


if __name__ == "__main__":
    main()
