#!/usr/bin/env python3
"""Cut a busy textured model (trees, bushes: thousands of leaf pieces that
texture-aware decimation can't merge) down to a small triangle count, then
paint a new texture by looking up the original's colour at the nearest
surface point.

  python3 tools/rebake.py in.glb out.glb [--tris 2500] [--tex 512] [--voxel 0.02 --smooth 20]
"""
import argparse
import os
import sys

import numpy as np
import trimesh
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from project_texture import bary, simplify  # noqa: E402


def main():
    import pymeshlab
    import xatlas
    from scipy import ndimage
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--tris", type=int, default=2500)
    ap.add_argument("--tex", type=int, default=512)
    ap.add_argument("--voxel", type=float, default=0.0, help="rebuild from a filled voxel grid (pitch, e.g. 0.02)")
    ap.add_argument("--smooth", type=int, default=20)
    a = ap.parse_args()
    sc = trimesh.load(a.src)
    src = sc.dump(concatenate=True) if len(sc.geometry) > 1 else list(sc.geometry.values())[0]
    img = np.asarray(src.visual.material.baseColorTexture.convert("RGB")).astype(np.float32) / 255
    th, tw = img.shape[:2]
    if a.voxel:
        # one smooth skin (leaf clusters become soft blobs, no gaps for the
        # outline to show through)
        low = simplify(a.src, a.tris, smooth=a.smooth, pitch=a.voxel)
    else:
        # geometry only: weld the texture seams, then simplify freely
        g = trimesh.Trimesh(src.vertices, src.faces, process=True)
        ms = pymeshlab.MeshSet()
        ms.add_mesh(pymeshlab.Mesh(g.vertices, g.faces))
        ms.meshing_merge_close_vertices(threshold=pymeshlab.PercentageValue(0.1))
        ms.meshing_decimation_quadric_edge_collapse(targetfacenum=a.tris, preservenormal=True, optimalplacement=True,
                                                     planarquadric=True, qualitythr=0.3)
        m = ms.current_mesh()
        low = trimesh.Trimesh(m.vertex_matrix(), m.face_matrix(), process=True)
        trimesh.repair.fix_normals(low)
    atlas = xatlas.Atlas()
    atlas.add_mesh(low.vertices, low.faces)
    po = xatlas.PackOptions()
    po.padding = 3
    po.resolution = a.tex
    atlas.generate(pack_options=po)
    vmap, idx, uvs = atlas[0]
    pos = low.vertices[vmap]
    # every texel inside a chart -> its 3D point
    texel_xy, texel_p = [], []
    for f in idx:
        t = uvs[f] * a.tex
        x0, y0 = np.floor(t.min(0)).astype(int)
        x1, y1 = np.ceil(t.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, a.tex - 1), min(y1, a.tex - 1)
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        b = bary(t, gx, gy)
        if b is None:
            continue
        inside = (b >= -0.1).all(0)
        if not inside.any():
            continue
        texel_p.append(b[:, inside].T @ pos[f])
        ty, tx = np.nonzero(inside)
        texel_xy.append(np.stack([tx + x0, ty + y0], 1))
    texel_p = np.concatenate(texel_p)
    texel_xy = np.concatenate(texel_xy)
    # the original's colour at the closest surface point
    _, _, tri = trimesh.proximity.closest_point(src, texel_p)
    cp = trimesh.proximity.closest_point(src, texel_p)[0]
    w = np.nan_to_num(trimesh.triangles.points_to_barycentric(src.triangles[tri], cp), nan=1.0 / 3.0)
    uv = (src.visual.uv[src.faces[tri]] * w[:, :, None]).sum(1)
    col = img[np.clip(((1 - uv[:, 1]) * (th - 1)).astype(int), 0, th - 1),
              np.clip((uv[:, 0] * (tw - 1)).astype(int), 0, tw - 1)]
    out = np.zeros((a.tex, a.tex, 3), np.float32)
    filled = np.zeros((a.tex, a.tex), bool)
    out[texel_xy[:, 1], texel_xy[:, 0]] = col
    filled[texel_xy[:, 1], texel_xy[:, 0]] = True
    for _ in range(4):
        grown = ndimage.grey_dilation(out * filled[..., None], size=(3, 3, 1))
        out = np.where(filled[..., None], out, grown)
        filled = ndimage.maximum_filter(filled.astype(np.uint8), size=3).astype(bool)
    texture = Image.fromarray((np.clip(out[::-1], 0, 1) * 255).astype(np.uint8))
    mat = trimesh.visual.material.PBRMaterial(baseColorTexture=texture, metallicFactor=0.0, roughnessFactor=1.0)
    res = trimesh.Trimesh(pos, idx, process=False, visual=trimesh.visual.TextureVisuals(uv=uvs, material=mat))
    trimesh.Scene(res).export(a.dst)
    print("üçgen:", len(src.faces), "->", len(res.faces))


if __name__ == "__main__":
    main()
