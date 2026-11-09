#!/usr/bin/env python3
"""Paint a model with its own drawing (front projection).

TRELLIS.2 builds very good shapes from a drawing, but its texture stage came
out dark/red on the rented GPU. This takes only the shape: simplify it to a
phone budget, unwrap UVs (xatlas), and bake a texture by projecting the
drawing from the front. Surfaces the front view can't see (back, under the
chin) take a blurred copy of the drawing, so they keep the body colors but
not the eyes or mouth.

  python3 tools/project_texture.py shape.glb drawing_cut.png out.glb [--tris 8000] [--tex 1024]

The drawing must have a transparent background (free_model.cutout). The mesh
is Y-up and faces +Z (TRELLIS); its silhouette from the front is fitted to
the drawing's alpha bounding box.
"""
import argparse

import numpy as np
from PIL import Image, ImageFilter


def simplify(src, tris, smooth=20, pitch=0.006):
    """TRELLIS.2 shapes are covered in folded fur ripples and thousands of
    small blobs; decimated they fold over each other and the game's outline
    shell shows through as black shards. Rebuild the surface from a filled
    voxel grid (marching cubes: one clean skin), smooth, then decimate."""
    import pymeshlab
    import trimesh
    sc = trimesh.load(src)
    g = sc.dump(concatenate=True) if hasattr(sc, "geometry") and len(sc.geometry) > 1 else (
        list(sc.geometry.values())[0] if hasattr(sc, "geometry") else sc)
    g = trimesh.Trimesh(g.vertices, g.faces, process=True)
    vox = g.voxelized(pitch * max(g.extents)).fill()
    skin = vox.marching_cubes
    skin.apply_transform(vox.transform)
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(skin.vertices, skin.faces))
    ms.apply_coord_taubin_smoothing(stepsmoothnum=smooth)
    ms.meshing_decimation_quadric_edge_collapse(targetfacenum=tris, preservenormal=True, optimalplacement=True,
                                                 planarquadric=True, qualitythr=0.5)
    m = ms.current_mesh()
    out = trimesh.Trimesh(m.vertex_matrix(), m.face_matrix(), process=True)
    # stray crumbs left by the grid
    parts = out.split(only_watertight=False)
    big = max(len(p.faces) for p in parts)
    out = trimesh.util.concatenate([p for p in parts if len(p.faces) >= 0.01 * big])
    trimesh.repair.fix_normals(out)
    return out


def raster(tri2d, res, values):
    """Rasterize triangles (N,3,2 pixel coords) keeping per pixel the max of
    an interpolated value (N,3). Returns (res,res) array, -inf where empty."""
    buf = np.full((res, res), -np.inf)
    for t, val in zip(tri2d, values):
        x0, y0 = np.floor(t.min(0)).astype(int)
        x1, y1 = np.ceil(t.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, res - 1), min(y1, res - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        w = bary(t, xs, ys)
        if w is None:
            continue
        inside = (w >= -1e-4).all(0)
        z = (w * val[:, None, None]).sum(0)
        sub = buf[y0:y1 + 1, x0:x1 + 1]
        upd = inside & (z > sub)
        sub[upd] = z[upd]
    return buf


def bary(t, xs, ys):
    (ax, ay), (bx, by), (cx, cy) = t
    d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
    if abs(d) < 1e-12:
        return None
    w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / d
    w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / d
    return np.stack([w0, w1, 1 - w0 - w1])


def fill(rgb, holes, alpha):
    """Replace `holes` pixels by the nearest pixel inside `alpha` that isn't one."""
    from scipy import ndimage
    keep = alpha & ~holes
    if not keep.any():
        return rgb
    _, (iy, ix) = ndimage.distance_transform_edt(~keep, return_indices=True)
    out = rgb.copy()
    out[holes] = rgb[iy[holes], ix[holes]]
    return out


def bake(mesh, drawing, tex=1024):
    import xatlas
    img = Image.open(drawing).convert("RGBA")
    rgba = np.asarray(img).astype(np.float32) / 255
    alpha = rgba[..., 3] > 0.5
    ys, xs = np.nonzero(alpha)
    ix0, ix1, iy0, iy1 = xs.min(), xs.max(), ys.min(), ys.max()
    rgb = rgba[..., :3]
    h, w = alpha.shape
    # the drawing's ink lines would land as black shards wherever the shape
    # and the drawing don't match exactly (the game draws its own outline):
    # fill thin dark strokes with the nearest paint; big dark blobs (eyes) stay
    from scipy import ndimage
    lum = rgb @ np.array([0.3, 0.59, 0.11], np.float32)
    dark = (lum < 0.3) & alpha
    blobs = ndimage.binary_opening(dark, iterations=max(3, w // 170))
    blobs = ndimage.binary_dilation(blobs, iterations=2) & dark
    strokes = dark & ~blobs
    edge = alpha & ~ndimage.binary_erosion(alpha, iterations=max(2, w // 256))
    rgb = fill(rgb, strokes | (edge & (lum < 0.5)), alpha)
    # the sides the front view can't see: body paint only (eyes, mouth and
    # small marks filled in too), softly blurred
    body = fill(rgb, (dark | (lum < 0.45) | ndimage.binary_dilation(blobs, iterations=w // 80)) & alpha, alpha)
    blur = np.asarray(Image.fromarray((body * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(31))
                      .filter(ImageFilter.GaussianBlur(w / 128))).astype(np.float32) / 255

    v = mesh.vertices
    lo, hi = v.min(0), v.max(0)

    def to_img(p):
        px = ix0 + (p[..., 0] - lo[0]) / (hi[0] - lo[0]) * (ix1 - ix0)
        py = iy1 - (p[..., 1] - lo[1]) / (hi[1] - lo[1]) * (iy1 - iy0)
        return px, py

    # front depth (max z) in drawing pixels, at reduced resolution
    dres = 512
    sc = dres / max(w, h)
    px, py = to_img(v)
    tri2d = np.stack([px, py], -1)[mesh.faces] * sc
    depth = raster(tri2d, dres, v[mesh.faces][:, :, 2])

    atlas = xatlas.Atlas()
    atlas.add_mesh(v, mesh.faces)
    po = xatlas.PackOptions()
    po.padding = 4
    po.resolution = tex
    po.bilinear = True
    atlas.generate(pack_options=po)
    vmap, idx, uvs = atlas[0]
    pos = v[vmap]
    nrm = mesh.vertex_normals[vmap]
    # unpainted texels (gaps, slivers) take the body colour, never black
    out = np.tile(np.median(blur[alpha], axis=0), (tex, tex, 1)).astype(np.float32)
    filled = np.zeros((tex, tex), bool)
    span = hi[2] - lo[2]
    for f in idx:
        t = uvs[f] * tex
        x0, y0 = np.floor(t.min(0)).astype(int)
        x1, y1 = np.ceil(t.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, tex - 1), min(y1, tex - 1)
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        b = bary(t, gx, gy)
        if b is None:
            continue
        inside = (b >= -0.15).all(0)
        if not inside.any():
            continue
        bw = b[:, inside]
        p = (bw.T @ pos[f])
        n = (bw.T @ nrm[f])
        n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
        qx, qy = to_img(p)
        qxi = np.clip(qx.astype(int), 0, w - 1)
        qyi = np.clip(qy.astype(int), 0, h - 1)
        dz = depth[np.clip((qy * sc).astype(int), 0, dres - 1), np.clip((qx * sc).astype(int), 0, dres - 1)]
        seen = p[:, 2] >= dz - 0.04 * span
        wf = np.clip(n[:, 2] * 2.5 + 0.35, 0, 1) * seen * alpha[qyi, qxi]
        col = rgb[qyi, qxi] * wf[:, None] + blur[qyi, qxi] * (1 - wf[:, None])
        ty, tx = np.nonzero(inside)
        out[ty + y0, tx + x0] = col
        filled[ty + y0, tx + x0] = True
    # grow the islands a few texels so mipmaps don't bleed black at seams
    from scipy import ndimage
    for _ in range(4):
        grown = ndimage.grey_dilation(out * filled[..., None], size=(3, 3, 1))
        cnt = ndimage.maximum_filter(filled.astype(np.uint8), size=3).astype(bool)
        out = np.where(filled[..., None], out, grown)
        filled = cnt
    # xatlas UVs have v up from the bottom of the image
    texture = Image.fromarray((np.clip(out[::-1], 0, 1) * 255).astype(np.uint8))
    return pos, idx, uvs, texture, vmap


def main():
    import trimesh
    ap = argparse.ArgumentParser()
    ap.add_argument("shape")
    ap.add_argument("drawing")
    ap.add_argument("out")
    ap.add_argument("--tris", type=int, default=8000)
    ap.add_argument("--tex", type=int, default=1024)
    ap.add_argument("--smooth", type=int, default=20, help="Taubin smoothing steps before simplifying")
    a = ap.parse_args()
    mesh = simplify(a.shape, a.tris, a.smooth)
    pos, idx, uvs, texture, vmap = bake(mesh, a.drawing, a.tex)
    mat = trimesh.visual.material.PBRMaterial(baseColorTexture=texture, metallicFactor=0.0, roughnessFactor=1.0)
    out = trimesh.Trimesh(pos, idx, process=False, visual=trimesh.visual.TextureVisuals(uv=uvs, material=mat))
    # the game's outline is a shell pushed out along the normals: on a
    # bumpy mesh it pokes through as dark shards, so the normals come from a
    # well smoothed copy (also gives softer toon shading)
    soft = mesh.copy()
    trimesh.smoothing.filter_taubin(soft, iterations=60)
    out.vertex_normals = soft.vertex_normals[vmap]
    trimesh.Scene(out).export(a.out)
    print("üçgen:", len(out.faces), "->", a.out)


if __name__ == "__main__":
    main()
