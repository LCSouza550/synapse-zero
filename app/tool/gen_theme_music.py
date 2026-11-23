"""Gera assets/audio/theme.wav: laço de música ambiente (Pulso Ambiente).

Baseado na descrição do protótipo (analise-prototipo.md): pad grave (110,
164,8 e 220 Hz) com brilho que varia lentamente (0,0625 Hz, perto dos 0,07 Hz
do protótipo) e notas esparsas da escala 329,6 a 659,3 Hz.

O arquivo é um laço sem emenda: todas as frequências do pad e da modulação
completam ciclos inteiros dentro da duração, e as notas que passam do fim
voltam ao começo (soma circular).

Uso (dentro da pasta app):  python tool/gen_theme_music.py
Requer: Python 3 + numpy.
"""
import pathlib
import wave

import numpy as np

SR = 22050
DUR = 32.0  # segundos; múltiplo do período da modulação (16 s)
N = int(SR * DUR)
SEED = 7
t = np.arange(N) / SR

# Pad: fundamentais com ciclos inteiros em DUR (freq * DUR deve ser inteiro).
PAD = [(110.0, 0.20), (165.0, 0.14), (220.0, 0.12)]
LFO_HZ = 1 / 16
lfo = 0.5 + 0.5 * np.sin(2 * np.pi * LFO_HZ * t - np.pi / 2)  # 0..1, suave
lfo2 = 0.5 + 0.5 * np.sin(2 * np.pi * (1 / 32) * t)

pad = np.zeros(N)
for freq, gain in PAD:
    assert abs(freq * DUR - round(freq * DUR)) < 1e-9, freq
    base = np.sin(2 * np.pi * freq * t)
    # "Brilho": harmônicos que entram e saem com a modulação (no lugar do filtro).
    shine = (0.55 * lfo * np.sin(2 * np.pi * 2 * freq * t)
             + 0.30 * lfo2 * np.sin(2 * np.pi * 3 * freq * t)
             + 0.12 * lfo * np.sin(2 * np.pi * 4 * freq * t))
    pad += gain * (base + shine)
pad *= 0.65 + 0.35 * lfo  # respiração do volume

# Notas: escala pentatônica menor de lá (E4 a E5), uma chance a cada 2 s.
SCALE = [329.63, 392.00, 440.00, 493.88, 587.33, 659.25]
rng = np.random.default_rng(SEED)
tail = int(SR * 4.0)
buf = np.zeros(N + tail)
tb = np.arange(N + tail) / SR
last = -1
for k in range(int(DUR / 2.0)):
    if rng.random() < 0.28:  # algumas pausas
        continue
    idx = int(rng.integers(0, len(SCALE)))
    if idx == last:
        idx = (idx + 2) % len(SCALE)
    last = idx
    start = k * 2.0 + float(rng.uniform(0.0, 0.5))
    f = SCALE[idx]
    age = tb - start
    m = age >= 0
    env = np.zeros_like(tb)
    env[m] = np.minimum(age[m] / 0.04, 1.0) * np.exp(-age[m] / 0.9)
    buf += 0.10 * env * (np.sin(2 * np.pi * f * tb) + 0.25 * np.sin(2 * np.pi * 2 * f * tb))

notes = buf[:N].copy()
notes[: len(buf) - N] += buf[N:]  # a cauda volta ao início

mix = pad + notes
# Remove deslocamento de nível e normaliza com folga.
mix -= mix.mean()
peak = float(np.max(np.abs(mix)))
mix *= 0.55 / peak

# Diagnóstico da emenda: o salto entre o último e o primeiro amostra deve ser
# parecido com a diferença típica entre amostras vizinhas.
seam = abs(float(mix[0] - mix[-1]))
typical = float(np.mean(np.abs(np.diff(mix))))
print(f"pico {np.max(np.abs(mix)):.3f} | salto na emenda {seam:.5f} | diferença típica {typical:.5f}")

out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "audio" / "theme.wav"
out.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(out), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((mix * 32767).astype("<i2").tobytes())
print("gerado:", out, f"({out.stat().st_size / 1024:.0f} KB, {DUR:.0f} s)")
