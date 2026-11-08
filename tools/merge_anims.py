#!/usr/bin/env python3
"""Merge the animation clips of several rigged .glb files (the same model
auto-rigged once per clip) into one .glb, retargeting every clip onto the
first file's skeleton.

  python3 tools/merge_anims.py out.glb [--face=90] idle=a.glb walk=b.glb run=c.glb ...

An auto-rigger builds a slightly different skeleton each time (bone lengths
and rest directions change), so channels can't simply be copied. Each clip
is replayed in its own skeleton, every bone's rotation is taken as a turn
away from that skeleton's bind pose (world space), the same turn is applied
to the base skeleton's bind pose, and local rotations are rebuilt. Hips keep
their up/down motion (scaled to the base skeleton), not the floor drift.
Run tools/shrink_glb.py on the result.
"""
import json
import struct
import sys

import numpy as np


def read_glb(path):
    b = open(path, "rb").read()
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


COMPS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_acc(doc, binary, ai):
    a = doc["accessors"][ai]
    bv = doc["bufferViews"][a["bufferView"]]
    assert a["componentType"] == 5126, "float accessors only"
    c = COMPS[a["type"]]
    stride = bv.get("byteStride", 4 * c)
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    out = np.zeros((a["count"], c), np.float32)
    for i in range(a["count"]):
        out[i] = struct.unpack_from("<%df" % c, binary, start + i * stride)
    return out


def add_acc(doc, binary, arr, kind):
    arr = np.asarray(arr, np.float32)
    data = arr.tobytes()
    while len(binary) % 4:
        binary.append(0)
    doc["bufferViews"].append({"buffer": 0, "byteOffset": len(binary), "byteLength": len(data)})
    binary += data
    a = {"bufferView": len(doc["bufferViews"]) - 1, "componentType": 5126,
         "count": int(arr.shape[0]), "type": kind}
    if kind == "SCALAR":
        a["min"] = [float(arr.min())]
        a["max"] = [float(arr.max())]
    doc["accessors"].append(a)
    return len(doc["accessors"]) - 1


# --- quaternions [x, y, z, w] ------------------------------------------------

def qmul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return np.array([aw * bx + ax * bw + ay * bz - az * by,
                     aw * by - ax * bz + ay * bw + az * bx,
                     aw * bz + ax * by - ay * bx + az * bw,
                     aw * bw - ax * bx - ay * by - az * bz])


def qinv(q):
    return np.array([-q[0], -q[1], -q[2], q[3]]) / np.dot(q, q)


def qslerp(a, b, t):
    d = np.dot(a, b)
    if d < 0:
        b = -b
        d = -d
    if d > 0.9995:
        r = a + t * (b - a)
        return r / np.linalg.norm(r)
    th = np.arccos(d)
    return (np.sin((1 - t) * th) * a + np.sin(t * th) * b) / np.sin(th)


def mat_to_quat(m):
    # rotation part only (columns normalized: the bind matrices carry scale)
    r = m[:3, :3].copy()
    for i in range(3):
        r[:, i] /= np.linalg.norm(r[:, i])
    t = np.trace(r)
    if t > 0:
        s = np.sqrt(t + 1.0) * 2
        q = [(r[2, 1] - r[1, 2]) / s, (r[0, 2] - r[2, 0]) / s, (r[1, 0] - r[0, 1]) / s, 0.25 * s]
    elif r[0, 0] > r[1, 1] and r[0, 0] > r[2, 2]:
        s = np.sqrt(1.0 + r[0, 0] - r[1, 1] - r[2, 2]) * 2
        q = [0.25 * s, (r[0, 1] + r[1, 0]) / s, (r[0, 2] + r[2, 0]) / s, (r[2, 1] - r[1, 2]) / s]
    elif r[1, 1] > r[2, 2]:
        s = np.sqrt(1.0 + r[1, 1] - r[0, 0] - r[2, 2]) * 2
        q = [(r[0, 1] + r[1, 0]) / s, 0.25 * s, (r[1, 2] + r[2, 1]) / s, (r[0, 2] - r[2, 0]) / s]
    else:
        s = np.sqrt(1.0 + r[2, 2] - r[0, 0] - r[1, 1]) * 2
        q = [(r[0, 2] + r[2, 0]) / s, (r[1, 2] + r[2, 1]) / s, 0.25 * s, (r[1, 0] - r[0, 1]) / s]
    q = np.array(q)
    return q / np.linalg.norm(q)


class Rig:
    """One file's skeleton: parents, bind (world) rotations and hips position."""

    def __init__(self, doc, binary):
        self.doc, self.bin = doc, binary
        self.names = {nd.get("name"): i for i, nd in enumerate(doc["nodes"])}
        self.parent = {}
        for i, nd in enumerate(doc["nodes"]):
            for c in nd.get("children", []):
                self.parent[c] = i
        skin = doc["skins"][0]
        ibm = read_acc(doc, binary, skin["inverseBindMatrices"])
        self.joints = skin["joints"]
        self.bind_q = {}
        self.bind_p = {}
        for k, j in enumerate(self.joints):
            m = np.linalg.inv(ibm[k].reshape(4, 4).T)  # glTF matrices are column-major
            self.bind_q[j] = mat_to_quat(m)
            self.bind_p[j] = m[:3, 3]

    def name(self, i):
        return self.doc["nodes"][i].get("name")


def sample(times, values, t):
    if t <= times[0]:
        return values[0]
    if t >= times[-1]:
        return values[-1]
    k = np.searchsorted(times, t) - 1
    f = (t - times[k]) / (times[k + 1] - times[k])
    if values.shape[1] == 4:
        return qslerp(values[k], values[k + 1], f)
    return values[k] + f * (values[k + 1] - values[k])


FACE_Q = np.array([0.0, 0.0, 0.0, 1.0])


def retarget(src, anim, dst):
    """Returns {dst joint: (times, quats)} and hips (times, positions)."""
    rot = {}
    hips_tr = None
    for ch in anim["channels"]:
        s = anim["samplers"][ch["sampler"]]
        times = read_acc(src.doc, src.bin, s["input"])[:, 0]
        vals = read_acc(src.doc, src.bin, s["output"])
        node = ch["target"]["node"]
        if ch["target"]["path"] == "rotation":
            rot[node] = (times, vals)
        elif ch["target"]["path"] == "translation" and src.name(node) == "Hips":
            hips_tr = (times, vals)
    all_t = sorted({float(t) for tv in rot.values() for t in tv[0]})
    jset = set(src.joints)

    def local(node, t):
        if node in rot:
            return sample(rot[node][0], rot[node][1], t)
        r = src.doc["nodes"][node].get("rotation", [0, 0, 0, 1])
        return np.array(r, float)

    out = {}
    for t in all_t:
        glob_src = {}
        glob_dst = {}

        def g_src(n):
            if n in glob_src:
                return glob_src[n]
            p = src.parent.get(n)
            q = local(n, t)
            if p is not None and p in jset:
                q = qmul(g_src(p), q)
            glob_src[n] = q
            return q

        for j in src.joints:
            name = src.name(j)
            if name not in dst.names:
                continue
            dj = dst.names[name]
            if dj not in dst.bind_q:
                continue
            # the same turn away from the bind pose, on the other skeleton
            turn = qmul(g_src(j), qinv(src.bind_q[j]))
            # the clips walk along +Z; the model may face another way (Tripo
            # models face +X): turn the motion so the steps go where it looks
            turn = qmul(qmul(FACE_Q, turn), qinv(FACE_Q))
            if name in ("Hips", "Spine02", "Spine01", "Spine", "neck", "Head"):
                # the game turns the character itself: drop the clip's turn
                # around the vertical axis (idles look around, attacks twist)
                twist = np.array([0.0, turn[1], 0.0, turn[3]])
                nt = np.linalg.norm(twist)
                if nt > 1e-6:
                    turn = qmul(turn, qinv(twist / nt))
            glob_dst[dj] = qmul(turn, dst.bind_q[dj])
        for dj, gq in glob_dst.items():
            p = dst.parent.get(dj)
            lq = qmul(qinv(glob_dst[p]), gq) if p in glob_dst else gq
            out.setdefault(dj, []).append(lq / np.linalg.norm(lq))
    res = {dj: (np.array(all_t, np.float32), np.array(qs, np.float32)) for dj, qs in out.items()}
    hips = None
    if hips_tr is not None:
        sh = src.names["Hips"]
        dh = dst.names["Hips"]
        ps, pd = src.bind_p[sh], dst.bind_p[dh]
        k = pd[1] / ps[1] if abs(ps[1]) > 1e-6 else 1.0
        # node translations are in the parent's units (often an armature
        # scaled 0.01): measure each side's unit against its bind height
        ts = np.array(src.doc["nodes"][sh].get("translation", [0, ps[1], 0]), float)
        td = np.array(dst.doc["nodes"][dh].get("translation", [0, pd[1], 0]), float)
        us = ps[1] / ts[1] if abs(ts[1]) > 1e-9 else 1.0
        ud = pd[1] / td[1] if abs(td[1]) > 1e-9 else 1.0
        vals = []
        for v in hips_tr[1]:
            up = (v[1] * us - ps[1]) * k / ud
            vals.append([td[0], td[1] + up, td[2]])
        hips = (hips_tr[0], np.array(vals, np.float32))
    return res, hips


def main():
    global FACE_Q
    out = sys.argv[1]
    args = sys.argv[2:]
    for a in list(args):
        if a.startswith("--face="):
            # degrees around Y from the clips' forward (+Z) to the model's
            # forward, e.g. --face=90 for a model that faces +X
            ang = np.radians(float(a.split("=", 1)[1]))
            FACE_Q = np.array([0.0, np.sin(ang / 2), 0.0, np.cos(ang / 2)])
            args.remove(a)
    pairs = [a.split("=", 1) for a in args]
    base_doc, base_bin = read_glb(pairs[0][1])
    dst = Rig(base_doc, base_bin)
    new_anims = []
    for key, path in pairs:
        doc, binary = read_glb(path)
        src = Rig(doc, binary)
        for anim in doc.get("animations", []):
            rot, hips = retarget(src, anim, dst)
            samplers, channels = [], []
            for dj, (times, quats) in rot.items():
                samplers.append({"input": add_acc(base_doc, base_bin, times[:, None], "SCALAR"),
                                 "output": add_acc(base_doc, base_bin, quats, "VEC4"),
                                 "interpolation": "LINEAR"})
                channels.append({"sampler": len(samplers) - 1, "target": {"node": dj, "path": "rotation"}})
            if hips is not None:
                samplers.append({"input": add_acc(base_doc, base_bin, hips[0][:, None], "SCALAR"),
                                 "output": add_acc(base_doc, base_bin, hips[1], "VEC3"),
                                 "interpolation": "LINEAR"})
                channels.append({"sampler": len(samplers) - 1,
                                 "target": {"node": dst.names["Hips"], "path": "translation"}})
            new_anims.append({"name": key, "samplers": samplers, "channels": channels})
            print(key, len(channels), "channels,", len(next(iter(rot.values()))[0]), "frames")
    base_doc["animations"] = new_anims
    base_doc["buffers"][0]["byteLength"] = len(base_bin)
    write_glb(out, base_doc, base_bin)


if __name__ == "__main__":
    main()
