#!/usr/bin/env python3
"""Free character model pipeline (no Higgsfield credits):

  1. drawing: FLUX.1 schnell (Apache-2.0) on Hugging Face
  2. 3D: TRELLIS (Microsoft, MIT) on Hugging Face -> textured .glb
  3. clean-up: removes the flat floor/shadow slab TRELLIS builds under
     the feet, then the textures are shrunk by tools/shrink_glb.py.

  python3 tools/free_model.py <id> "<what it is>" [--seeds 7,21] [--image art.png]
      -> work/free_model/<id>_<seed>.webp (drawings, pick one)
  python3 tools/free_model.py <id> --image work/free_model/<id>_21.webp
      -> assets/models/<id>.glb (+ a starter <id>.json with facing 0)

Needs: pip install gradio_client trimesh networkx scipy pillow, and a Hugging
Face token sent by the environment (Network secret for huggingface.co and
*.hf.space; anonymous ZeroGPU quota is ~0). TRELLIS models face +Z, so the
json "facing" is 0 (Tripo's was -90). Check with
`tools/screenshot.sh out.png --scene=preview --demo=ref --model=<id>`.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
WORK = os.path.join(ROOT, "work", "free_model")
STYLE = ("{what}, cute chibi game character, big head, big glossy dark eyes, small smile, rosy cheeks, "
         "rounded soft shapes, toon style, flat colors, no baked lighting, no outlines, A-pose, front view, "
         "full body, centered, plain white background")


def drawings(model_id, what, seeds):
    from gradio_client import Client
    c = Client("black-forest-labs/FLUX.1-schnell", httpx_kwargs={"timeout": 300})
    os.makedirs(WORK, exist_ok=True)
    for seed in seeds:
        r = c.predict(prompt=STYLE.format(what=what), seed=seed, randomize_seed=False, width=1024, height=1024,
                      num_inference_steps=4, api_name="/infer")
        out = os.path.join(WORK, "%s_%d.webp" % (model_id, seed))
        shutil.copy(r[0] if isinstance(r, (list, tuple)) else r, out)
        print("çizim:", out)


def model(model_id, image):
    from gradio_client import Client, handle_file
    c = Client("trellis-community/TRELLIS", httpx_kwargs={"timeout": 900})
    c.predict(api_name="/start_session")
    img = c.predict(image=handle_file(image), api_name="/preprocess_image")
    r = c.predict(image=handle_file(img), multiimages=[], seed=1, ss_guidance_strength=7.5, ss_sampling_steps=12,
                  slat_guidance_strength=3.0, slat_sampling_steps=12, multiimage_algo="stochastic",
                  mesh_simplify=0.95, texture_size=1024, api_name="/generate_and_extract_glb")
    os.makedirs(WORK, exist_ok=True)
    raw = os.path.join(WORK, model_id + "_raw.glb")
    shutil.copy(r[2], raw)
    clean = os.path.join(WORK, model_id + "_clean.glb")
    clean_floor(raw, clean)
    dst = os.path.join(ROOT, "assets", "models", model_id + ".glb")
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "shrink_glb.py"), clean, dst], check=True)
    meta = os.path.join(ROOT, "assets", "models", model_id + ".json")
    if not os.path.exists(meta):
        json.dump({"facing": 0, "height": 1.5, "outline": 0.014}, open(meta, "w"), indent="\t")
    print("model:", dst)


def clean_floor(src, dst):
    """Drops thin, wide parts at the very bottom (the drawing's ground shadow)."""
    import numpy as np
    import trimesh
    from trimesh.graph import connected_components
    s = trimesh.load(src)
    for g in s.geometry.values():
        comps = connected_components(g.face_adjacency, nodes=np.arange(len(g.faces)), min_len=1)
        lo, hi = g.bounds
        span = hi - lo
        keep = np.ones(len(g.faces), bool)
        for c in comps:
            v = g.vertices[np.unique(g.faces[c])]
            h = np.ptp(v[:, 1])
            w = max(np.ptp(v[:, 0]), np.ptp(v[:, 2]))
            if h < 0.03 * span[1] and w > 0.4 * max(span[0], span[2]) and v[:, 1].max() < lo[1] + 0.05 * span[1]:
                keep[c] = False
                print("zemin parçası silindi:", len(c), "üçgen")
        g.update_faces(keep)
        g.remove_unreferenced_vertices()
        weld_normals(g)
    s.export(dst)


def weld_normals(g):
    """One normal per position: TRELLIS splits vertices along texture seams,
    each copy got its own normal, and the game's outline (a shell pushed out
    along the normals) cracked open there, leaving stray dark dashes by thin
    parts (horn tips, ear edges)."""
    import numpy as np
    n = g.vertex_normals.copy()
    key = np.round(g.vertices / 1e-5).astype(np.int64)
    _, inv = np.unique(key, axis=0, return_inverse=True)
    inv = inv.reshape(-1)
    acc = np.zeros((inv.max() + 1, 3))
    np.add.at(acc, inv, n)
    acc /= np.maximum(np.linalg.norm(acc, axis=1, keepdims=True), 1e-9)
    g.vertex_normals = acc[inv]


def reclean(model_id):
    """Re-run the clean-up on assets/models/<id>.glb (no GPU needed)."""
    dst = os.path.join(ROOT, "assets", "models", model_id + ".glb")
    tmp = os.path.join(WORK, model_id + "_reclean.glb")
    os.makedirs(WORK, exist_ok=True)
    clean_floor(dst, tmp)
    shutil.copy(tmp, dst)
    print("model:", dst)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("id")
    ap.add_argument("what", nargs="?", default="")
    ap.add_argument("--seeds", default="7,21")
    ap.add_argument("--image")
    ap.add_argument("--reclean", action="store_true", help="clean assets/models/<id>.glb again")
    a = ap.parse_args()
    if a.reclean:
        reclean(a.id)
    elif a.image:
        model(a.id, a.image)
    else:
        drawings(a.id, a.what, [int(s) for s in a.seeds.split(",")])
