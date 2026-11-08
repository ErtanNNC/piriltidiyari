#!/usr/bin/env python3
"""Shrink the embedded textures of a .glb (AI-made models come with 2048 px
JPEGs; 1024 px is plenty for a phone and halves the APK growth).

  python3 tools/shrink_glb.py in.glb out.glb [--size 1024] [--quality 85]

Only images are touched; meshes, materials and nodes stay as they are.
Also prints the mesh bounds and triangle count.
"""
import argparse
import io
import json
import struct

from PIL import Image


def read_glb(path):
    b = open(path, "rb").read()
    assert b[:4] == b"glTF", "not a glb"
    n = struct.unpack_from("<I", b, 12)[0]
    doc = json.loads(b[20:20 + n])
    off = 20 + n
    blen = struct.unpack_from("<I", b, off)[0]
    return doc, bytearray(b[off + 8:off + 8 + blen])


def write_glb(path, doc, binary):
    js = json.dumps(doc, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    binary = bytes(binary) + b"\0" * ((4 - len(binary) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(path, "wb") as f:
        f.write(b"glTF" + struct.pack("<II", 2, total))
        f.write(struct.pack("<I", len(js)) + b"JSON" + js)
        f.write(struct.pack("<I", len(binary)) + b"BIN\0" + binary)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--size", type=int, default=1024)
    ap.add_argument("--quality", type=int, default=85)
    a = ap.parse_args()
    doc, bin_in = read_glb(a.src)
    views = doc["bufferViews"]
    new_data = {}
    for img in doc.get("images", []):
        v = img["bufferView"]
        bv = views[v]
        raw = bytes(bin_in[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]])
        im = Image.open(io.BytesIO(raw)).convert("RGB")
        if max(im.size) > a.size:
            im = im.resize((a.size, a.size * im.height // im.width), Image.LANCZOS)
        out = io.BytesIO()
        im.save(out, "JPEG", quality=a.quality)
        new_data[v] = out.getvalue()
        img["mimeType"] = "image/jpeg"
    # rebuild the binary chunk view by view (4-byte aligned)
    out = bytearray()
    for i, bv in enumerate(views):
        data = new_data.get(i)
        if data is None:
            o = bv.get("byteOffset", 0)
            data = bytes(bin_in[o:o + bv["byteLength"]])
        out += b"\0" * ((4 - len(out) % 4) % 4)
        bv["byteOffset"] = len(out)
        bv["byteLength"] = len(data)
        out += data
    doc["buffers"][0]["byteLength"] = len(out)
    write_glb(a.dst, doc, out)
    tris = 0
    for m in doc["meshes"]:
        for p in m["primitives"]:
            if "indices" in p:
                tris += doc["accessors"][p["indices"]]["count"] // 3
            pos = doc["accessors"][p["attributes"]["POSITION"]]
            print("bounds", [round(x, 3) for x in pos["min"]], [round(x, 3) for x in pos["max"]])
    print("triangles", tris, "bytes", len(out))


if __name__ == "__main__":
    main()
