#!/usr/bin/env python3
"""Turn a generated music file into a seamless game loop (.ogg).

  python3 tools/music_loop.py in.mp3 assets/audio/music/<track>.ogg [--xfade 3]

The last seconds are crossfaded into the first ones (so the end flows into
the start), the level is brought to a common loudness, and the result is
encoded as Ogg Vorbis. Needs ffmpeg.
"""
import argparse
import subprocess

import numpy as np

RATE = 44100


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--xfade", type=float, default=3.0)
    ap.add_argument("--rms_db", type=float, default=-20.0)
    a = ap.parse_args()
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", a.src, "-ar", str(RATE), "-ac", "2", "-f", "f32le", "-"],
                         check=True, capture_output=True).stdout
    x = np.frombuffer(raw, np.float32).reshape(-1, 2).copy()
    n = int(a.xfade * RATE)
    # trim silence at the very end, then crossfade the tail over the head
    loud = np.where(np.abs(x).max(axis=1) > 1e-3)[0]
    x = x[: loud[-1] + 1] if len(loud) else x
    head, tail = x[:n], x[-n:]
    t = np.linspace(0.0, 1.0, n, dtype=np.float32)[:, None]
    # equal-power crossfade
    blend = tail * np.cos(t * np.pi / 2) + head * np.sin(t * np.pi / 2)
    out = np.concatenate([x[n:-n], blend])
    rms = np.sqrt(np.mean(out ** 2)) + 1e-9
    out *= 10 ** (a.rms_db / 20) / rms
    peak = np.abs(out).max()
    if peak > 0.97:
        out *= 0.97 / peak
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "4", a.dst], input=out.astype(np.float32).tobytes(), check=True)
    print(a.dst, round(len(out) / RATE, 1), "s")


if __name__ == "__main__":
    main()
