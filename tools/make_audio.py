#!/usr/bin/env python3
"""Synthesizes every sound of Pırıltı Diyarı (no samples, no downloads).

  python3 tools/make_audio.py            # all
  python3 tools/make_audio.py sfx        # only effects
  python3 tools/make_audio.py music      # only music

Writes assets/audio/sfx/<name>.wav (16-bit mono 32 kHz) and
assets/audio/music/<track>.ogg (Vorbis, loops seamlessly). Deterministic:
the same script always gives the same files. Replace any file with a real
recording of the same name and the game uses that instead.
"""
import os
import subprocess
import sys
import wave

import numpy as np

SR = 32000
# sounds now made with tools/sfx_prep.py from generated audio: keep them
REAL = {"jump", "jump2", "land", "swish", "hit", "hurt", "roll", "fall", "splash", "wind", "whoosh", "door",
        "chest", "boing", "crystal", "lantern", "skill", "levelup"}
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")

# --- basics -------------------------------------------------------------------


def t_axis(sec):
    return np.arange(int(sec * SR)) / SR


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def env_adsr(n, a=0.005, d=0.05, s=0.6, r=0.1, hold=None):
    """ADSR over n samples. `hold` = seconds before release starts."""
    out = np.zeros(n)
    A, D, R = int(a * SR), int(d * SR), int(r * SR)
    H = n - R if hold is None else min(n, int(hold * SR))
    i = 0
    seg = min(A, n)
    out[:seg] = np.linspace(0, 1, seg, endpoint=False)
    i = seg
    seg = max(0, min(D, H - i))
    out[i:i + seg] = np.linspace(1, s, seg, endpoint=False)
    i += seg
    if H > i:
        out[i:H] = s
        i = H
    rel = n - i
    if rel > 0:
        out[i:] = np.linspace(out[i - 1] if i > 0 else s, 0, rel)
    return out


def env_exp(n, decay):
    return np.exp(-np.arange(n) / SR / decay)


def sweep(f0, f1, sec, curve=1.0):
    n = int(sec * SR)
    k = np.linspace(0, 1, n) ** curve
    f = f0 + (f1 - f0) * k
    return 2 * np.pi * np.cumsum(f) / SR


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be an array (per sample)."""
    c = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1.0 - np.exp(-2 * np.pi * c / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def lowpass_fast(x, cutoff):
    """Static-cutoff low-pass via FFT (fast for long buffers)."""
    n = len(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    h = 1.0 / np.sqrt(1.0 + (f / cutoff) ** 4)
    return np.fft.irfft(np.fft.rfft(x) * h, n)


def highpass_fast(x, cutoff):
    return x - lowpass_fast(x, cutoff)


rng_noise = np.random.default_rng(7)


def noise(sec):
    return rng_noise.uniform(-1, 1, int(sec * SR))


def reverb(x, sec=1.2, mix=0.25, seed=3, wrap=False):
    """Convolution with decaying stereo-ish noise; wrap=True folds the tail
    to the start (for loops)."""
    r = np.random.default_rng(seed)
    n = int(sec * SR)
    ir = r.normal(0, 1, n) * np.exp(-np.arange(n) / SR / (sec / 5.0))
    ir = lowpass_fast(ir, 5000)
    ir[0] = 0
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    L = len(x) + n
    size = 1 << (L - 1).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[:L]
    if wrap:
        out = wet[:len(x)].copy()
        tail = wet[len(x):]
        out[:len(tail)] += tail[:len(x)]
        wet = out
    else:
        x = np.concatenate([x, np.zeros(n)])
    return x * (1 - mix) + wet * mix * 0.6


def norm(x, peak=0.85):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def write_wav(path, x):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def fade_edges(x, a=0.002, r=0.01):
    n = len(x)
    A, R = int(a * SR), int(r * SR)
    x = x.copy()
    x[:A] *= np.linspace(0, 1, A)
    x[n - R:] *= np.linspace(1, 0, R)
    return x


def mixdown(parts, length=None):
    n = length or max(len(p[0]) + p[1] for p in parts)
    out = np.zeros(n)
    for sig, at in parts:
        end = min(n, at + len(sig))
        out[at:end] += sig[:end - at]
    return out


# --- instruments --------------------------------------------------------------


def glock(freq, sec=0.6, vel=1.0):
    t = t_axis(sec)
    x = (np.sin(2 * np.pi * freq * t) * env_exp(len(t), sec * 0.35)
         + 0.35 * np.sin(2 * np.pi * freq * 2.76 * t) * env_exp(len(t), sec * 0.12)
         + 0.15 * np.sin(2 * np.pi * freq * 5.4 * t) * env_exp(len(t), sec * 0.05))
    return fade_edges(x * vel, 0.001, 0.01)


def bell(freq, sec=1.5, vel=1.0, index=2.0):
    t = t_axis(sec)
    # keep the FM sidebands well under Nyquist (no harsh aliasing on high notes)
    index = index * float(np.clip(700.0 / freq, 0.25, 1.0))
    mod = np.sin(2 * np.pi * freq * 3.5 * t) * index * env_exp(len(t), sec * 0.25)
    x = np.sin(2 * np.pi * freq * t + mod) * env_exp(len(t), sec * 0.4)
    return fade_edges(x * vel, 0.001, 0.02)


def pluck(freq, sec=0.8, vel=1.0, bright=0.5, seed=0):
    """Karplus-Strong (marimba/harp-ish)."""
    n = int(sec * SR)
    period = max(2, int(SR / freq))
    r = np.random.default_rng(seed + int(freq))
    buf = r.uniform(-1, 1, period)
    buf = lowpass(buf, 2000 + 6000 * bright)
    out = np.empty(n)
    damp = 0.996 - (1 - bright) * 0.01
    for i in range(n):
        v = buf[i % period]
        nxt = buf[(i + 1) % period]
        buf[i % period] = damp * 0.5 * (v + nxt)
        out[i] = v
    return fade_edges(out * vel * env_adsr(n, 0.002, 0.1, 0.8, 0.08), 0.001, 0.02)


def marimba(freq, sec=0.5, vel=1.0):
    t = t_axis(sec)
    x = (np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * freq * 4 * t) * env_exp(len(t), 0.03))
    return fade_edges(x * env_exp(len(t), sec * 0.3) * vel, 0.001, 0.01)


def flute(freq, sec, vel=1.0):
    t = t_axis(sec)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.0 * t) * np.clip(t * 3, 0, 1)
    ph = 2 * np.pi * np.cumsum(freq * vib) / SR
    x = np.sin(ph) + 0.12 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
    breath = lowpass_fast(noise(sec), 3000) * 0.05
    return fade_edges((x + breath) * env_adsr(len(t), 0.06, 0.1, 0.85, 0.12) * vel)


def pad(freqs, sec, vel=1.0, bright=1200.0):
    t = t_axis(sec)
    x = np.zeros(len(t))
    for f in freqs:
        for det in (-0.12, 0.0, 0.11):
            ph = 2 * np.pi * f * (1 + det / 100) * t + det * 10
            x += ((ph / np.pi) % 2 - 1)  # saw
    x = lowpass_fast(x / (3 * len(freqs)), bright)
    return x * env_adsr(len(t), 0.4, 0.3, 0.9, 0.6) * vel


def soft_square(freq, sec, vel=1.0):
    t = t_axis(sec)
    ph = 2 * np.pi * freq * t
    x = np.sin(ph) + np.sin(3 * ph) / 3 + np.sin(5 * ph) / 5 * 0.5
    return fade_edges(lowpass_fast(x, 2600) * env_adsr(len(t), 0.005, 0.08, 0.6, 0.06) * vel)


def bass(freq, sec, vel=1.0):
    t = t_axis(sec)
    x = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(4 * np.pi * freq * t)
    return fade_edges(x * env_adsr(len(t), 0.005, 0.1, 0.7, 0.08) * vel)


def kick(vel=1.0):
    ph = sweep(150, 45, 0.25, 0.4)
    return np.sin(ph) * env_exp(len(ph), 0.08) * vel


def shaker(vel=1.0):
    x = highpass_fast(noise(0.06), 5000)
    return x * env_exp(len(x), 0.015) * vel


def snare(vel=1.0):
    n = highpass_fast(noise(0.18), 1500) * env_exp(int(0.18 * SR), 0.05)
    t = t_axis(0.18)
    tone = np.sin(2 * np.pi * 190 * t) * env_exp(len(t), 0.04)
    return (n * 0.7 + tone * 0.5) * vel


def clap(vel=1.0):
    x = np.zeros(int(0.2 * SR))
    for k, d in enumerate((0.0, 0.012, 0.024)):
        b = highpass_fast(noise(0.15), 1000) * env_exp(int(0.15 * SR), 0.03 if k < 2 else 0.06)
        i = int(d * SR)
        x[i:i + len(b)] += b[:len(x) - i]
    return x * vel


# --- sound effects ------------------------------------------------------------


def sfx_all():
    S = {}
    # player
    ph = sweep(320, 720, 0.16, 0.7)
    S["jump"] = np.sin(ph) * env_adsr(len(ph), 0.004, 0.05, 0.6, 0.06) * 0.8 + 0.2 * np.sin(2 * ph) * env_exp(len(ph), 0.05)
    ph = sweep(520, 1150, 0.16, 0.7)
    S["jump2"] = mixdown([(np.sin(ph) * env_adsr(len(ph), 0.004, 0.05, 0.6, 0.06) * 0.7, 0), (glock(1760, 0.3, 0.3), int(0.05 * SR))])
    x = lowpass_fast(noise(0.1), 500) * env_exp(int(0.1 * SR), 0.025)
    S["land"] = x + np.sin(sweep(120, 60, 0.1)) * env_exp(int(0.1 * SR), 0.03) * 0.6
    n = noise(0.2)
    cut = np.linspace(800, 4000, len(n)) ** 1.0
    S["swish"] = lowpass(n, cut) * np.sin(np.linspace(0, np.pi, len(n))) ** 2 * 1.2
    ph = sweep(700, 240, 0.14, 0.5)
    S["hit"] = mixdown([(np.sin(ph) * env_exp(len(ph), 0.06), 0), (highpass_fast(noise(0.02), 2000) * 0.4, 0)])
    ph = sweep(260, 150, 0.25)
    wob = np.sin(ph + 0.3 * np.sin(2 * np.pi * 18 * t_axis(0.25)))
    S["hurt"] = (wob + 0.3 * np.sign(wob) * 0.3) * env_adsr(len(ph), 0.005, 0.08, 0.5, 0.1) * 0.8
    n = noise(0.35)
    S["roll"] = lowpass(n, np.linspace(400, 2500, len(n)) ** 1.0 * np.sin(np.linspace(0.2, np.pi, len(n)))) * 1.5
    spin = lowpass(noise(0.45), 1800 + 1500 * np.sin(np.linspace(0, 6 * np.pi, int(0.45 * SR))) ** 2) * 1.2
    arp = mixdown([(glock(midi_hz(m), 0.4, 0.5), int(i * 0.06 * SR)) for i, m in enumerate([76, 79, 83, 88])])
    S["skill"] = mixdown([(spin * np.sin(np.linspace(0, np.pi, len(spin))), 0), (arp, int(0.08 * SR))])
    S["sleep"] = mixdown([(flute(midi_hz(m), 0.45, 0.6), int(i * 0.35 * SR)) for i, m in enumerate([76, 72, 67])])
    S["wake"] = mixdown([(glock(midi_hz(m), 0.5, 0.6), int(i * 0.12 * SR)) for i, m in enumerate([67, 72, 76, 79])])
    ph = sweep(900, 200, 0.6, 0.6)
    S["fall"] = np.sin(ph) * env_adsr(len(ph), 0.01, 0.1, 0.6, 0.2) * 0.5 + lowpass_fast(noise(0.6), 900) * np.linspace(0, 1, int(0.6 * SR)) * 0.4
    # pickups and rewards
    S["coin"] = mixdown([(glock(midi_hz(83), 0.25, 0.7), 0), (glock(midi_hz(88), 0.45, 0.8), int(0.07 * SR))])
    S["heal"] = mixdown([(np.sin(sweep(400 + i * 120, 700 + i * 150, 0.07)) * env_exp(int(0.07 * SR), 0.03) * 0.6, int(i * 0.06 * SR)) for i in range(5)])
    S["levelup"] = mixdown([(glock(midi_hz(m), 0.6, 0.7), int(i * 0.08 * SR)) for i, m in enumerate([72, 76, 79, 84, 88])]
                           + [(bell(midi_hz(84), 1.2, 0.4), int(0.42 * SR))])
    S["quest"] = mixdown([(marimba(midi_hz(m), 0.4, 0.8), int(t * SR)) for m, t in [(72, 0), (76, 0.12), (79, 0.24), (84, 0.38)]]
                         + [(glock(midi_hz(88), 0.8, 0.5), int(0.38 * SR))])
    S["fanfare"] = mixdown([(glock(midi_hz(m), 0.8, 0.6), int(i * 0.1 * SR)) for i, m in enumerate([67, 72, 76, 79, 84])]
                           + [(bell(midi_hz(f), 2.2, 0.35), int(0.55 * SR)) for f in (72, 76, 79)]
                           + [(pad([midi_hz(60), midi_hz(64), midi_hz(67)], 1.8, 0.35, 2500), int(0.5 * SR))])
    S["lantern"] = mixdown([(pad([midi_hz(55), midi_hz(64)], 1.4, 0.3, 1500), 0)]
                           + [(bell(midi_hz(m), 1.3, 0.45, 1.2), int((0.1 + i * 0.13) * SR)) for i, m in enumerate([72, 76, 79, 84])])
    S["crystal"] = mixdown([(glock(midi_hz(91), 0.7, 0.6), 0), (glock(midi_hz(96), 0.9, 0.5), int(0.09 * SR))])
    S["stone"] = mixdown([(bell(midi_hz(m), 2.0, 0.4, 1.0), int(i * 0.18 * SR)) for i, m in enumerate([60, 67, 74])])
    S["memory"] = mixdown([(glock(midi_hz(m), 0.9, 0.55), int(i * 0.22 * SR)) for i, m in enumerate([79, 76, 72, 74, 79])])
    S["calm"] = mixdown([(glock(midi_hz(m), 0.35, 0.45), int(i * 0.045 * SR)) for i, m in enumerate([84, 88, 91, 96])]
                        + [(highpass_fast(noise(0.25), 4000) * env_exp(int(0.25 * SR), 0.08) * 0.25, 0)])
    S["boss_calm"] = mixdown([(S["fanfare"], 0), (S["calm"], 0)])
    S["chest"] = mixdown([(np.sin(sweep(180, 90, 0.08)) * env_exp(int(0.08 * SR), 0.03), 0),
                          (np.sin(sweep(160, 80, 0.08)) * env_exp(int(0.08 * SR), 0.03), int(0.09 * SR)),
                          (S["coin"] * 0.8, int(0.2 * SR))])
    # world
    n = noise(0.9)
    S["door"] = mixdown([(lowpass(n, np.linspace(300, 1400, len(n))) * np.sin(np.linspace(0, np.pi, len(n))) * 1.2, 0),
                         (bell(midi_hz(79), 1.2, 0.35), int(0.5 * SR))])
    S["bell"] = bell(520, 2.4, 0.9, 2.5)
    ph = sweep(180, 420, 0.35, 0.5)
    S["boing"] = np.sin(ph + 2.0 * np.sin(2 * np.pi * 14 * t_axis(0.35))) * env_exp(len(ph), 0.15)
    n = noise(1.6)
    S["wind"] = lowpass(n, 300 + 700 * np.sin(np.linspace(0, np.pi, len(n)))) * np.sin(np.linspace(0, np.pi, len(n))) ** 1.5 * 2.0
    n = noise(0.7)
    S["whoosh"] = lowpass(n, np.linspace(2500, 400, len(n))) * np.sin(np.linspace(0, np.pi, len(n))) * 1.3
    S["splash"] = mixdown([(lowpass(noise(0.3), 1600) * env_exp(int(0.3 * SR), 0.08), 0),
                           (np.sin(sweep(500, 900, 0.1)) * env_exp(int(0.1 * SR), 0.04) * 0.4, 0)])
    # attacks are announced: a soft "ding-ding"
    S["warn"] = mixdown([(glock(midi_hz(81), 0.25, 0.45), 0), (glock(midi_hz(76), 0.3, 0.4), int(0.14 * SR))])
    # UI
    t = t_axis(0.035)
    S["click"] = np.sin(2 * np.pi * 1300 * t) * env_exp(len(t), 0.008)
    ph = sweep(380, 900, 0.07, 0.5)
    S["pop"] = np.sin(ph) * env_adsr(len(ph), 0.002, 0.02, 0.5, 0.03)
    t = t_axis(0.05)
    S["blip"] = (np.sin(2 * np.pi * 820 * t) + 0.2 * np.sin(2 * np.pi * 1640 * t)) * env_adsr(len(t), 0.003, 0.02, 0.4, 0.02) * 0.6
    S["card"] = mixdown([(bell(midi_hz(m), 1.4, 0.35, 0.8), int(i * 0.09 * SR)) for i, m in enumerate([76, 83, 88])])
    S["shop"] = mixdown([(marimba(midi_hz(m), 0.3, 0.7), int(i * 0.08 * SR)) for i, m in enumerate([79, 83, 86])])
    os.makedirs(SFX_DIR, exist_ok=True)
    for name, x in S.items():
        x = fade_edges(norm(reverb(x, 0.5, 0.12), 0.8), 0.001, 0.015)
        if name in REAL:
            continue  # a recorded/generated sound replaced it (tools/sfx_prep.py)
        write_wav(os.path.join(SFX_DIR, name + ".wav"), x)
    print("sfx: %d" % len(S))


# --- music --------------------------------------------------------------------

SCALES = {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10]}


def chord_notes(root, kind, degree):
    sc = SCALES[kind]
    return [root + sc[(degree + k) % 7] + 12 * ((degree + k) // 7) for k in (0, 2, 4)]


def melody(rng, root, kind, prog, bars, beats, pent=True):
    """Motif-based melody: a 2-bar motif, repeated with small changes (A A' B A'')."""
    sc = SCALES[kind]
    allowed = [0, 2, 4, 7, 9] if (pent and kind == "major") else ([0, 3, 5, 7, 10] if pent else sc)
    pool = [root + 12 + o + 12 * k for k in range(2) for o in allowed]
    rhythms = [[1, 1, 1, 1], [1.5, 0.5, 1, 1], [1, 0.5, 0.5, 2], [0.5, 0.5, 1, 0.5, 0.5, 1], [2, 1, 1], [1, 1, 2]]
    if beats == 3:
        rhythms = [[1, 1, 1], [2, 1], [1.5, 0.5, 1], [1, 0.5, 0.5, 1], [3]]

    def make_bar(chord, prev):
        rh = rhythms[rng.integers(len(rhythms))]
        notes = []
        cur = prev
        for i, d in enumerate(rh):
            if i == 0:
                # land on a chord tone on the downbeat
                targets = [p for p in pool if (p - chord[0]) % 12 in [(c - chord[0]) % 12 for c in chord]]
                cur = min(targets, key=lambda p: abs(p - cur) + rng.uniform(0, 3))
            else:
                idx = pool.index(min(pool, key=lambda p: abs(p - cur)))
                idx = int(np.clip(idx + rng.choice([-2, -1, -1, 1, 1, 2, 0]), 0, len(pool) - 1))
                cur = pool[idx]
            notes.append((cur, d))
        return notes, cur

    out = []
    prev = root + 19
    motif = []
    for b in range(2):
        bar, prev = make_bar(chord_notes(root, kind, prog[b % len(prog)]), prev)
        motif.append(bar)
    for b in range(bars):
        chord = chord_notes(root, kind, prog[b % len(prog)])
        section = (b // 2) % 4
        if section in (0, 1, 3) and b % 2 < 2:
            bar = [list(n) for n in motif[b % 2]]
            if section == 1 and b % 2 == 1:
                bar[-1][0] = chord[0] + 12  # answer phrase ends on the root
            if section == 3 and b % 2 == 1:
                bar[-1][0] = root + 12
        else:
            bar, prev = make_bar(chord, prev)
        out.append([tuple(n) for n in bar])
    return out


def render_track(spec):
    name = spec["name"]
    rng = np.random.default_rng(spec["seed"])
    bpm, beats, bars = spec["bpm"], spec.get("beats", 4), spec.get("bars", 16)
    beat = 60.0 / bpm
    bar_len = beat * beats
    total = int(bars * bar_len * SR)
    root, kind, prog = spec["root"], spec["scale"], spec["prog"]
    parts = []
    mel = melody(rng, root, kind, prog, bars, beats, spec.get("pent", True))
    lead = spec["lead"]
    for b in range(bars):
        t0 = b * bar_len
        chord = chord_notes(root, kind, prog[b % len(prog)])
        # pad / chords
        if spec.get("pad", 0) > 0:
            parts.append((pad([midi_hz(n) for n in chord], bar_len + 0.3, spec["pad"], spec.get("pad_bright", 1100)), int(t0 * SR)))
        # bass
        if spec.get("bass", 0) > 0:
            pat = spec.get("bass_pat", [0, 2] if beats == 4 else [0])
            for k in pat:
                note = chord[0] - 12 if k % 2 == 0 else chord[2] - 24
                parts.append((bass(midi_hz(note), beat * 0.9, spec["bass"]), int((t0 + k * beat) * SR)))
        # arpeggio
        if spec.get("arp", 0) > 0:
            steps = beats * 2
            seq = chord + [chord[1] + 12, chord[0] + 12, chord[2]]
            for k in range(steps):
                n = seq[k % len(seq)] + 12
                inst = spec.get("arp_inst", "glock")
                v = spec["arp"] * (1.0 if k % 2 == 0 else 0.7)
                sig = glock(midi_hz(n), 0.5, v) if inst == "glock" else (pluck(midi_hz(n), 0.6, v, 0.6, k) if inst == "pluck" else marimba(midi_hz(n), 0.4, v))
                parts.append((sig, int((t0 + k * beat / 2) * SR)))
        # melody (skip some bars for breathing room)
        if b % 8 != 7 or spec.get("always_lead"):
            t = t0
            for note, d in mel[b]:
                dur = d * beat
                v = spec.get("lead_vol", 0.6)
                if lead == "flute":
                    sig = flute(midi_hz(note), dur * 0.95, v)
                elif lead == "pluck":
                    sig = pluck(midi_hz(note), max(dur, 0.5), v, 0.7, int(note))
                elif lead == "marimba":
                    sig = marimba(midi_hz(note), max(dur, 0.4), v)
                elif lead == "bell":
                    sig = bell(midi_hz(note), max(dur * 1.5, 0.8), v * 0.7, 1.2)
                elif lead == "square":
                    sig = soft_square(midi_hz(note), dur * 0.9, v * 0.6)
                else:
                    sig = glock(midi_hz(note), max(dur, 0.5), v)
                parts.append((sig, int(t * SR)))
                t += dur
        # drums
        dr = spec.get("drums", "")
        for k in range(beats):
            at = int((t0 + k * beat) * SR)
            if dr in ("soft", "festive", "boss", "march"):
                if k == 0 or (dr in ("boss", "festive") and k == 2):
                    parts.append((kick(0.7 if dr != "boss" else 0.9), at))
                if dr in ("festive",) and k in (1, 3):
                    parts.append((clap(0.35), at))
                if dr in ("boss", "march") and k in (1, 3):
                    parts.append((snare(0.45 if dr == "boss" else 0.3), at))
                parts.append((shaker(0.25), at + int(beat / 2 * SR)))
                if dr == "boss":
                    parts.append((shaker(0.18), at))
            elif dr == "shaker":
                parts.append((shaker(0.2), at + int(beat / 2 * SR)))
    mix = np.zeros(total + SR * 3)
    for sig, at in parts:
        end = min(len(mix), at + len(sig))
        mix[at:end] += sig[:end - at]
    # fold everything past the loop end back to the start, then reverb with wrap
    loop = mix[:total].copy()
    tail = mix[total:]
    loop[:len(tail)] += tail[:total]
    loop = reverb(loop, spec.get("verb", 1.6), spec.get("verb_mix", 0.3), wrap=True)
    loop = norm(lowpass_fast(loop, 9000), 0.7)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    wav = os.path.join(MUSIC_DIR, name + ".tmp.wav")
    write_wav(wav, loop)
    out = os.path.join(MUSIC_DIR, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "3", out], check=True)
    os.remove(wav)
    print("music: %s %.1fs" % (name, len(loop) / SR))


TRACKS = [
    # cheerful village and the title (C major, marimba + glock)
    {"name": "title", "seed": 11, "bpm": 100, "root": 60, "scale": "major", "prog": [0, 4, 5, 3],
     "lead": "marimba", "pad": 0.25, "bass": 0.35, "arp": 0.18, "drums": "shaker"},
    {"name": "village", "seed": 21, "bpm": 96, "root": 65, "scale": "major", "prog": [0, 3, 4, 0, 5, 3, 1, 4],
     "lead": "marimba", "pad": 0.22, "bass": 0.4, "arp": 0.15, "arp_inst": "pluck", "drums": "soft"},
    # festival night (Sahne 1) and the ending
    {"name": "festival", "seed": 31, "bpm": 116, "root": 67, "scale": "major", "prog": [0, 3, 4, 0],
     "lead": "glock", "pad": 0.2, "bass": 0.45, "bass_pat": [0, 1, 2, 3], "arp": 0.16, "arp_inst": "marimba", "drums": "festive"},
    # the grey Pus: slow, curious, a little lonely
    {"name": "pus", "seed": 41, "bpm": 72, "root": 57, "scale": "minor", "prog": [0, 5, 3, 4],
     "lead": "glock", "lead_vol": 0.45, "pad": 0.35, "pad_bright": 800, "bass": 0.3, "verb": 2.4, "verb_mix": 0.45},
    {"name": "tower", "seed": 45, "bpm": 92, "root": 57, "scale": "dorian", "prog": [0, 6, 5, 6],
     "lead": "pluck", "pad": 0.3, "pad_bright": 900, "bass": 0.4, "bass_pat": [0, 1, 2, 3], "arp": 0.12, "drums": "march"},
    # chapters
    {"name": "forest", "seed": 51, "bpm": 84, "beats": 3, "root": 62, "scale": "major", "prog": [0, 4, 5, 3],
     "lead": "flute", "pad": 0.2, "bass": 0.35, "arp": 0.14, "arp_inst": "pluck", "verb": 1.8},
    {"name": "cave", "seed": 61, "bpm": 80, "root": 64, "scale": "minor", "prog": [0, 3, 5, 4],
     "lead": "glock", "lead_vol": 0.5, "pad": 0.3, "pad_bright": 900, "bass": 0.3, "arp": 0.1, "verb": 2.6, "verb_mix": 0.45},
    {"name": "harbor", "seed": 71, "bpm": 108, "root": 70, "scale": "major", "prog": [0, 3, 4, 0],
     "lead": "pluck", "pad": 0.2, "bass": 0.5, "bass_pat": [0, 1, 2, 3], "arp": 0.12, "arp_inst": "marimba", "drums": "soft"},
    {"name": "mountain", "seed": 81, "bpm": 70, "beats": 3, "root": 63, "scale": "major", "prog": [0, 3, 4, 0],
     "lead": "bell", "pad": 0.3, "pad_bright": 1000, "bass": 0.25, "verb": 2.4, "verb_mix": 0.4},
    {"name": "castle", "seed": 91, "bpm": 76, "root": 60, "scale": "minor", "prog": [0, 5, 3, 4],
     "lead": "pluck", "pad": 0.32, "pad_bright": 850, "bass": 0.35, "arp": 0.14, "arp_inst": "pluck", "verb": 2.2, "verb_mix": 0.4},
    # bosses: energetic, never scary
    {"name": "boss", "seed": 101, "bpm": 132, "root": 57, "scale": "minor", "prog": [0, 5, 6, 4], "pent": True,
     "lead": "square", "lead_vol": 0.55, "pad": 0.2, "bass": 0.55, "bass_pat": [0, 1, 2, 3], "arp": 0.12, "drums": "boss", "verb": 1.0, "verb_mix": 0.2},
]


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("all", "sfx"):
        sfx_all()
    if what in ("all", "music"):
        only = sys.argv[2:] if len(sys.argv) > 2 else None
        for spec in TRACKS:
            if only and spec["name"] not in only:
                continue
            render_track(spec)
