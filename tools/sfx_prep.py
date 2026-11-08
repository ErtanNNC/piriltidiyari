#!/usr/bin/env python3
"""Prepare a generated sound effect for the game.

  python3 tools/sfx_prep.py in.mp3 assets/audio/sfx/<name>.wav [--max 1.2] [--peak 0.8]

Mono 32 kHz 16-bit WAV (like tools/make_audio.py writes), leading silence
cut, length capped with a short fade-out, peak normalized. Needs ffmpeg.
Sounds made this way are listed in tools/make_audio.py REAL so a rerun of
the synthesizer does not overwrite them.
"""
import argparse
import subprocess
import wave

import numpy as np

SR = 32000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--max", type=float, default=1.2)
    ap.add_argument("--peak", type=float, default=0.8)
    a = ap.parse_args()
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", a.src, "-ar", str(SR), "-ac", "1", "-f", "f32le", "-"],
                         check=True, capture_output=True).stdout
    x = np.frombuffer(raw, np.float32).copy()
    peak = np.abs(x).max() + 1e-9
    on = np.where(np.abs(x) > peak * 0.05)[0]
    if len(on):
        start = max(0, on[0] - int(0.005 * SR))
        end = on[-1] + int(0.05 * SR)
        x = x[start:end]
    x = x[: int(a.max * SR)]
    fade = min(len(x), int(0.06 * SR))
    x[-fade:] *= np.linspace(1.0, 0.0, fade)
    x *= a.peak / (np.abs(x).max() + 1e-9)
    with wave.open(a.dst, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
    print(a.dst, round(len(x) / SR, 2), "s")


if __name__ == "__main__":
    main()
