#!/usr/bin/env python3
"""Give an auto-rigged character a clean skeleton and skin weights, and move
its animation clips onto it.

  python3 tools/rebuild_rig.py out.glb idle=a.glb walk=b.glb run=c.glb ...

Auto-riggers can put bones in odd places on chibi characters (a foot inside
the tail, a hand behind the back) and let leg bones move the tail. This keeps
only what was bought, the motion: a new humanoid skeleton is built from the
mesh's own shape (feet found on the ground, hands at the far ends of the arm
band, hips and neck heights from the old rig), every vertex is bound to the
bones of its body region (head, tail, left/right arm, left/right leg, torso)
with soft blends at the seams, and each clip is retargeted with
merge_anims.retarget. The mesh faces +Z (as the rigger exports it), so the
model json needs "facing": 0. Run tools/shrink_glb.py on the result.
"""
import sys

import numpy as np

from merge_anims import Rig, add_acc, qslerp, read_acc, read_glb, retarget, write_glb

SPINE = ["Hips", "Spine02", "Spine01", "Spine", "neck", "Head", "head_end"]
ARM = ["Shoulder", "Arm", "ForeArm", "Hand"]
LEG = ["UpLeg", "Leg", "Foot", "ToeBase"]
# how much of each torso bone's bend to keep
CALM = {"Hips": 0.5, "Spine02": 0.45, "Spine01": 0.45, "Spine": 0.45, "neck": 0.35, "Head": 0.35}


def skeleton(P, old):
    """Joint positions (mesh space) and parents."""
    hips_y = old["Hips"][1]
    neck_y = old["neck"][1]
    top = P[:, 1].max()
    band = P[(P[:, 1] > hips_y) & (P[:, 1] < neck_y)]
    cx = float(np.median(band[:, 0]))
    cz = float(np.median(band[:, 2]))
    depth = float(cz - P[:, 2].min())
    J, par = {}, {}
    # spine up the middle
    ys = np.linspace(hips_y, neck_y * 0.97, 4)
    for name, y in zip(SPINE[:4], ys):
        J[name] = np.array([cx, y, cz])
    J["neck"] = np.array([cx, neck_y, cz])
    J["Head"] = np.array([cx, neck_y + 0.02 * top, cz])
    J["head_end"] = np.array([cx, top, cz])
    for i in range(1, len(SPINE)):
        par[SPINE[i]] = SPINE[i - 1]
    # feet: what touches the ground in front of the tail, left (+x) / right
    ground = P[(P[:, 1] < 0.05 * top) & (P[:, 2] > cz - 0.25 * depth)]
    legs = {}
    for side, sgn in (("Left", 1.0), ("Right", -1.0)):
        pts = ground[(ground[:, 0] - cx) * sgn > 0.01]
        fx = float(np.median(pts[:, 0])) if len(pts) else cx + sgn * 0.1 * top
        fz = float(np.median(pts[:, 2])) if len(pts) else cz
        legs[side] = (fx, fz)
        J[side + "UpLeg"] = np.array([fx, hips_y * 0.95, (fz + cz) * 0.5])
        J[side + "Leg"] = np.array([fx, hips_y * 0.5, fz])
        J[side + "Foot"] = np.array([fx, 0.05 * top, fz])
        J[side + "ToeBase"] = np.array([fx, 0.012 * top, fz + 0.05 * top])
        par[side + "UpLeg"] = "Hips"
        par[side + "Leg"] = side + "UpLeg"
        par[side + "Foot"] = side + "Leg"
        par[side + "ToeBase"] = side + "Foot"
    # arms: the far ends of the arm band, in front of the tail
    armband = P[(P[:, 1] > hips_y + 0.01 * top) & (P[:, 1] < neck_y + 0.02 * top) & (P[:, 2] > cz - 0.3 * depth)]
    reach = {}
    for side, sgn in (("Left", 1.0), ("Right", -1.0)):
        off = (armband[:, 0] - cx) * sgn
        pts = armband[off > np.percentile(off, 97)]
        tip = pts.mean(axis=0)
        r = float(abs(tip[0] - cx))
        reach[side] = r
        sy = neck_y - 0.03 * top
        J[side + "Shoulder"] = np.array([cx + sgn * 0.25 * r, sy, cz])
        J[side + "Arm"] = np.array([cx + sgn * 0.5 * r, sy, cz + 0.2 * (tip[2] - cz)])
        J[side + "ForeArm"] = np.array([cx + sgn * 0.75 * r, (sy + tip[1]) * 0.5, cz + 0.6 * (tip[2] - cz)])
        J[side + "Hand"] = np.array([tip[0] - sgn * 0.03 * top, tip[1], tip[2]])
        par[side + "Shoulder"] = "Spine"
        par[side + "Arm"] = side + "Shoulder"
        par[side + "ForeArm"] = side + "Arm"
        par[side + "Hand"] = side + "ForeArm"
    info = {"cx": cx, "cz": cz, "hips_y": hips_y, "neck_y": neck_y, "top": top, "depth": depth, "reach": reach}
    return J, par, info


def seg_dist(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-9), 0.0, 1.0)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def weights(P, idx, J, par, info, names):
    kids = {n: [c for c, p in par.items() if p == n] for n in names}
    D = np.zeros((len(P), len(names)))
    for k, n in enumerate(names):
        segs = [seg_dist(P, J[n], J[c]) for c in kids[n]] or [np.linalg.norm(P - J[n], axis=1)]
        D[:, k] = np.min(segs, axis=0)
    cx, cz, top = info["cx"], info["cz"], info["top"]
    x, y, z = P[:, 0] - cx, P[:, 1], P[:, 2] - cz
    allow = np.zeros_like(D, dtype=bool)
    col = {n: k for k, n in enumerate(names)}

    def give(mask, bones):
        for b in bones:
            allow[mask, col[b]] = True

    head = y > info["neck_y"] + 0.015 * top
    tail = (~head) & (z < -0.3 * info["depth"])
    rest = ~head & ~tail
    give(head, ["Head"])
    give(head & (y < info["neck_y"] + 0.06 * top), ["neck"])
    give(tail, ["Hips", "Spine02"])
    for side, sgn in (("Left", 1.0), ("Right", -1.0)):
        r = info["reach"][side]
        arm = rest & (x * sgn > 0.42 * r) & (y > info["hips_y"])
        give(arm, [side + b for b in ARM] + ["Spine"])
        leg = rest & (x * sgn > 0.0) & (y < info["hips_y"] + 0.02 * top)
        give(leg, [side + b for b in LEG] + ["Hips"])
    torso = rest.copy()
    give(torso, ["Hips", "Spine02", "Spine01", "Spine", "neck"])
    W = np.where(allow, 1.0 / (D + 0.01 * top) ** 4, 0.0)
    W /= W.sum(axis=1, keepdims=True)
    # soften the seams: a few rounds of averaging with mesh neighbours
    tri = idx.reshape(-1, 3)
    n = len(P)
    for _ in range(3):
        acc = W.copy()
        cnt = np.ones(n)
        for a, b in ((0, 1), (1, 2), (2, 0)):
            np.add.at(acc, tri[:, a], W[tri[:, b]])
            np.add.at(cnt, tri[:, a], 1)
            np.add.at(acc, tri[:, b], W[tri[:, a]])
            np.add.at(cnt, tri[:, b], 1)
        W = acc / cnt[:, None]
    # the head stays rigid (no stretching faces)
    W[head & (y > info["neck_y"] + 0.06 * top)] = np.eye(len(names))[col["Head"]]
    top4 = np.argsort(-W, axis=1)[:, :4]
    w4 = np.take_along_axis(W, top4, axis=1)
    w4 /= w4.sum(axis=1, keepdims=True)
    return top4.astype(np.uint16), w4.astype(np.float32)


def main():
    out = sys.argv[1]
    args = sys.argv[2:]
    turn = 0.0
    for a in list(args):
        if a.startswith("--turn="):
            # degrees around Y that make the mesh face +Z (a Tripo model that
            # faces +X needs --turn=-90); the clips assume +Z
            turn = float(a.split("=", 1)[1])
            args.remove(a)
    pairs = [a.split("=", 1) for a in args]
    doc, binary = read_glb(pairs[0][1])
    old = Rig(doc, binary)
    prim = doc["meshes"][0]["primitives"][0]
    c, s_ = np.cos(np.radians(turn)), np.sin(np.radians(turn))
    rot = np.array([[c, 0, s_], [0, 1, 0], [-s_, 0, c]])
    for attr in ("POSITION", "NORMAL", "TANGENT"):
        if attr not in prim["attributes"] or turn == 0.0:
            continue
        arr = read_acc(doc, binary, prim["attributes"][attr]).astype(float)
        arr[:, :3] = arr[:, :3] @ rot.T
        kind = "VEC4" if arr.shape[1] == 4 else "VEC3"
        prim["attributes"][attr] = add_acc(doc, binary, arr.astype(np.float32), kind)
        if attr == "POSITION":
            acc = doc["accessors"][prim["attributes"][attr]]
            acc["min"] = [float(v) for v in arr.min(axis=0)]
            acc["max"] = [float(v) for v in arr.max(axis=0)]
    old_pos = {doc["nodes"][j]["name"]: rot @ old.bind_p[j] for j in old.joints}
    P = read_acc(doc, binary, prim["attributes"]["POSITION"]).astype(float)
    a = doc["accessors"][prim["indices"]]
    bv = doc["bufferViews"][a["bufferView"]]
    dt = {5125: np.uint32, 5123: np.uint16}[a["componentType"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    idx = np.frombuffer(bytes(binary[start:start + a["count"] * np.dtype(dt).itemsize]), dt).astype(np.int64)
    J, par, info = skeleton(P, old_pos)
    names = SPINE + [s + b for s in ("Left", "Right") for b in ARM] + [s + b for s in ("Left", "Right") for b in LEG]
    # new node tree: Armature > Hips ...; the mesh node sits beside it
    nodes = [{"name": "Armature", "children": []}]
    nid = {}
    for n in names:
        nid[n] = len(nodes)
        nodes.append({"name": n})
    for n in names:
        p = par.get(n)
        t = J[n] - (J[p] if p else np.zeros(3))
        nodes[nid[n]]["translation"] = [float(v) for v in t]
        if p:
            nodes[nid[p]].setdefault("children", []).append(nid[n])
    nodes[0]["children"].append(nid["Hips"])
    mesh_node = len(nodes)
    nodes.append({"name": "body", "mesh": 0, "skin": 0})
    nodes[0]["children"].append(mesh_node)
    ibm = np.zeros((len(names), 16), np.float32)
    for k, n in enumerate(names):
        m = np.eye(4)
        m[:3, 3] = -J[n]
        ibm[k] = m.T.reshape(-1)  # column-major
    doc["nodes"] = nodes
    doc["scenes"] = [{"nodes": [0]}]
    doc["scene"] = 0
    doc["skins"] = [{"joints": [nid[n] for n in names], "inverseBindMatrices": add_acc(doc, binary, ibm, "MAT4")}]
    jw, ww = weights(P, idx, J, par, info, names)
    while len(binary) % 4:
        binary.append(0)
    data = jw.tobytes()
    doc["bufferViews"].append({"buffer": 0, "byteOffset": len(binary), "byteLength": len(data)})
    binary += data
    doc["accessors"].append({"bufferView": len(doc["bufferViews"]) - 1, "componentType": 5123,
                             "count": int(len(jw)), "type": "VEC4"})
    prim["attributes"]["JOINTS_0"] = len(doc["accessors"]) - 1
    prim["attributes"]["WEIGHTS_0"] = add_acc(doc, binary, ww, "VEC4")
    dst = Rig(doc, binary)
    anims = []
    for key, path in pairs:
        sdoc, sbin = read_glb(path)
        src = Rig(sdoc, sbin)
        for anim in sdoc.get("animations", []):
            rot, hips = retarget(src, anim, dst)
            # chibi heads are heavy: soften the torso's bends (bind = identity)
            for dj in list(rot):
                if dst.name(dj) in CALM:
                    t_, q_ = rot[dj]
                    ident = np.array([0.0, 0.0, 0.0, 1.0])
                    q_ = np.array([qslerp(ident, q, CALM[dst.name(dj)]) for q in q_], np.float32)
                    rot[dj] = (t_, q_)
            samplers, channels = [], []
            for dj, (times, quats) in rot.items():
                samplers.append({"input": add_acc(doc, binary, times[:, None], "SCALAR"),
                                 "output": add_acc(doc, binary, quats, "VEC4"), "interpolation": "LINEAR"})
                channels.append({"sampler": len(samplers) - 1, "target": {"node": dj, "path": "rotation"}})
            if hips is not None:
                samplers.append({"input": add_acc(doc, binary, hips[0][:, None], "SCALAR"),
                                 "output": add_acc(doc, binary, hips[1], "VEC3"), "interpolation": "LINEAR"})
                channels.append({"sampler": len(samplers) - 1, "target": {"node": nid["Hips"], "path": "translation"}})
            anims.append({"name": key, "samplers": samplers, "channels": channels})
            print(key, len(channels), "channels")
    doc["animations"] = anims
    doc["buffers"][0]["byteLength"] = len(binary)
    write_glb(out, doc, binary)
    print("feet", {k: [round(v, 3) for v in J[k]] for k in ("LeftFoot", "RightFoot", "LeftHand", "RightHand")})


if __name__ == "__main__":
    main()
