"""Generate SFX untuk intro CPNS Journey (sintesis sendiri, bebas lisensi).
Jalankan: python tools/make_sfx.py  -> public/sfx/*.wav + tools/mix-preview.wav"""
import numpy as np, os
from scipy.io import wavfile

SR = 44100
rng = np.random.default_rng(7)
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'public', 'sfx')
os.makedirs(OUT, exist_ok=True)

def tt(d): return np.arange(int(d * SR)) / SR

def whoosh(dur, f0, f1, q=1.5, amp=0.3, peak=0.5):
    n = int(dur * SR); t = np.arange(n) / SR
    x = rng.standard_normal(n)
    p = np.clip(t / dur, 0, 1)
    env = np.where(p < peak, np.sin(p / peak * np.pi / 2), np.cos((p - peak) / (1 - peak) * np.pi / 2)) ** 2
    fc = f0 * (f1 / f0) ** p
    f = 2 * np.sin(np.pi * np.minimum(fc, SR / 6) / SR); damp = 1 / q
    low = band = 0.0; y = np.empty(n)
    for i in range(n):
        low += f[i] * band
        high = x[i] - low - damp * band
        band += f[i] * high
        y[i] = band
    y *= env
    return y / (np.max(np.abs(y)) + 1e-9) * amp

def bell(freq, dur, amp=0.3, decay=3.0):
    t = tt(dur); y = np.zeros_like(t)
    for k, (r, a) in enumerate([(1, 1), (2.01, .35), (2.76, .22), (4.2, .08)]):
        y += a * np.sin(2 * np.pi * freq * r * t) * np.exp(-t * decay * (1 + .9 * k))
    y *= np.minimum(1, t / 0.003)
    return y / (np.max(np.abs(y)) + 1e-9) * amp

def pop(f0, f1, dur, amp=0.5):
    t = tt(dur); p = t / dur
    ph = 2 * np.pi * np.cumsum(f0 * (f1 / f0) ** p) / SR
    y = np.sin(ph) * np.exp(-t * 14)
    y[:int(.004 * SR)] += rng.standard_normal(int(.004 * SR)) * .25
    return y / (np.max(np.abs(y)) + 1e-9) * amp

def pad(dur, freqs, amp=0.12, fin=0.8, fout=1.2):
    t = tt(dur); y = np.zeros_like(t)
    for f in freqs:
        for d in (-.6, 0, .6):
            y += np.sin(2 * np.pi * (f + d) * t)
    e = np.minimum(1, t / fin) * np.minimum(1, (dur - t) / fout)
    y *= e ** 1.5
    return y / (np.max(np.abs(y)) + 1e-9) * amp

def place(buf, y, start):
    i = int(start * SR); j = min(len(buf), i + len(y)); buf[i:j] += y[:j - i]

def mix(parts, dur):
    b = np.zeros(int(dur * SR))
    for start, y in parts: place(b, y, start)
    return b

stems = {}
# 1. buku tertutup muncul
stems['book-appear'] = (6, mix([(0, whoosh(.7, 300, 2500, 1.2, .35, .6)), (.42, pop(160, 70, .25, .5))], .9))
# 2. buku terbuka: swish halaman + kilau
stems['page-open'] = (52, mix([
    (0, whoosh(1.2, 900, 6000, 2, .4, .55)), (.45, whoosh(.5, 1500, 5000, 2.5, .22, .5)),
    (.85, bell(523.25, 1.0, .2, 2.5)),
    (.9, bell(1046.5, .6, .18, 4)), (.97, bell(1318.5, .6, .18, 4)),
    (1.04, bell(1568, .6, .18, 4)), (1.11, bell(2093, .6, .15, 4))], 1.7))
# 3. jalan tergambar
stems['road-draw'] = (90, whoosh(1.1, 400, 2200, .9, .16, .6))
# 4. bendera muncul
stems['flag-pop'] = (116, mix([(0, pop(500, 180, .18, .5)), (.02, bell(1318.5, 1.0, .33, 4)),
                               (0, whoosh(.18, 1200, 4000, 1.5, .15, .5))], 1.0))
# 5. judul
stems['title-chime'] = (126, mix([(0, whoosh(.35, 800, 3500, 1.5, .22, .5)), (.25, bell(784, 1.3, .3, 2.5)),
                                  (.42, bell(1046.5, 1.2, .3, 2.5)), (.6, bell(1318.5, 1.0, .2, 3))], 1.6))
# 6. garis emas
stems['sparkle-end'] = (150, mix([(0, bell(2093, .5, .12, 6)), (.09, bell(2637, .5, .12, 6)), (.18, bell(3136, .6, .12, 5))], 1.0))
# 7. pad lembut
stems['pad'] = (100, pad(3.3, [261.63, 329.63, 392.0, 493.88]))

FPS, TOTAL = 30, 200
m = mix([(f / FPS, y) for f, y in stems.values()], TOTAL / FPS)
G = 0.85 / np.max(np.abs(m))  # gain global agar tidak clip
def save(path, y): wavfile.write(path, SR, (np.clip(y * G, -1, 1) * 32767).astype(np.int16))
for name, (f, y) in stems.items(): save(os.path.join(OUT, name + '.wav'), y)
save(os.path.join(HERE, 'mix-preview.wav'), m)
print('gain', round(G, 2))
