"""Gera assets/audio/splash.wav, sincronizado com a SplashTimeline (conexão do conector).

Uso (dentro da pasta app):  python tool/gen_splash_audio.py
Requer: Python 3 + numpy.
"""
import wave
import pathlib
import numpy as np

SR = 44100
DUR = 4.3
MASTER = 0.9
N = int(SR * DUR)
t_axis = np.arange(N) / SR
mix = np.zeros(N)


def exp_env(points, t):
    """Envoltória com rampas exponenciais entre pontos (tempo, valor)."""
    out = np.zeros_like(t)
    for (t0, v0), (t1, v1) in zip(points, points[1:]):
        m = (t >= t0) & (t < t1)
        u = (t[m] - t0) / (t1 - t0)
        out[m] = v0 * (v1 / v0) ** u
    return out


def lin_env(points, t):
    return np.interp(t, [p[0] for p in points], [p[1] for p in points], left=0.0, right=0.0)


def wave_of(kind, phase):
    s = np.sin(phase)
    if kind == "sine":
        return s
    if kind == "square":
        return np.sign(s)
    if kind == "triangle":
        return (2 / np.pi) * np.arcsin(s)
    raise ValueError(kind)


def add(start, stop, kind, freq_fn, gain_fn):
    i0, i1 = int(start * SR), min(int(stop * SR), N)
    t = t_axis[i0:i1]
    f = freq_fn(t)
    phase = 2 * np.pi * np.cumsum(f) / SR
    mix[i0:i1] += wave_of(kind, phase) * gain_fn(t)


def note(freq, start, dur, kind, vol):
    pts = [(start, 0.0001), (start + 0.012, vol), (start + dur, 0.0001)]
    add(start, start + dur + 0.05, kind, lambda t: np.full_like(t, freq), lambda t: exp_env(pts, t))


def sweep(f0, f1, start, dur, kind, vol):
    pts = [
        (start, 0.0001),
        (start + dur * 0.15, vol),
        (start + dur * 0.85, vol * 0.6),
        (start + dur + 0.08, 0.0001),
    ]

    def freq(t):
        u = np.clip((t - start) / dur, 0, 1)
        return f0 * (f1 / f0) ** u

    add(start, start + dur + 0.12, kind, freq, lambda t: exp_env(pts, t))


def hum(freq, start, end, vol):
    pts = [(start, 0.0001), (start + 0.35, vol), (max(start + 0.36, end - 0.7), vol), (end, 0.0001)]
    add(start, end + 0.05, "sine", lambda t: np.full_like(t, freq), lambda t: lin_env(pts, t))


# --- partitura sincronizada com SplashTimeline (app/lib/presentation/splash/splash_timeline.dart) ---
# Mantenha estas constantes iguais às da timeline (fração de t x 4,2 s).
TOTAL = 4.2
START_FRAC, END_FRAC, RADIUS_FRAC, CENTER_FRAC = 0.08, 0.92, 0.104, 0.5
APPROACH_START, BEAM_END, SPIN_SPAN, GLOW_SWELL = 0.04, 0.88, 0.16, 0.03
entry_at = (CENTER_FRAC - RADIUS_FRAC - START_FRAC) / (END_FRAC - START_FRAC)
exit_at = (CENTER_FRAC + RADIUS_FRAC - START_FRAC) / (END_FRAC - START_FRAC)
move_span = BEAM_END - APPROACH_START - SPIN_SPAN
contact = (APPROACH_START + entry_at * move_span) * TOTAL
connected = (APPROACH_START + entry_at * move_span + SPIN_SPAN) * TOTAL
beam_start = APPROACH_START * TOTAL
beam_end = BEAM_END * TOTAL
exit_time = (APPROACH_START + entry_at * move_span + SPIN_SPAN + (exit_at - entry_at) * move_span) * TOTAL
print(f"contato {contact:.3f}s | conexão {connected:.3f}s | saída do conector {exit_time:.3f}s | fim do feixe {beam_end:.3f}s")

# 1) Feixe parte (estalo curto) e se aproxima: varredura ascendente até o contato.
# Frequências acima de ~500 Hz: o alto-falante do celular quase não reproduz o
# que está abaixo de 300 Hz, e a abertura parecia só começar no contato.
note(1320, beam_start, 0.08, "triangle", 0.10)
sweep(560, 1120, beam_start, contact - beam_start, "sine", 0.10)

# 2) Contato: toque seco; giro do conector: varredura que sobe (carga).
note(330, contact, 0.2, "triangle", 0.12)
note(495, contact, 0.2, "sine", 0.06)
sweep(500, 1400, contact, connected - contact, "triangle", 0.09)

# 3) Conexão: estalo + acorde + batida grave.
note(1500, connected, 0.03, "square", 0.05)
for i, f in enumerate([523.25, 784, 1046.5, 1568]):
    note(f, connected, 1.0 - i * 0.1, "sine", 0.15 - i * 0.015)
note(98, connected, 0.45, "sine", 0.12)

# 4) Feixe atravessa e segue até o fim; zumbido de energia.
sweep(420, 1000, connected, beam_end - connected, "sine", 0.06)
hum(261.63, connected, beam_end + 0.25, 0.05)
hum(392, connected, beam_end + 0.25, 0.032)

# 5) Nome completo: arpejo final junto com o fim do feixe.
for i, f in enumerate([784, 1047, 1319, 1568]):
    note(f, beam_end - 0.25 + i * 0.08, 0.6, "triangle", 0.1)

mix *= MASTER
peak = float(np.max(np.abs(mix)))
print(f"pico antes do limitador: {peak:.3f}")
if peak > 0.98:
    mix *= 0.98 / peak

out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "audio" / "splash.wav"
out.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(out), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((mix * 32767).astype("<i2").tobytes())
print("gerado:", out, f"({out.stat().st_size/1024:.0f} KB)")
