"""Gera os efeitos sonoros curtos do jogo (originais, sintetizados).

Uso (na pasta app):  python tool/gen_sfx.py
Saída: assets/audio/tap.wav e assets/audio/advance.wav (mono, 16 bits, 22050 Hz).
Requer numpy.
"""
import wave
from pathlib import Path

import numpy as np

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def write(name: str, data: np.ndarray, peak: float) -> None:
    data = data / max(1e-9, np.max(np.abs(data))) * peak
    pcm = (data * 32767).astype("<i2")
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print(f"{name}: {len(data) / SR:.2f} s, {len(pcm) * 2} bytes")


def tap() -> np.ndarray:
    """Toque curto e limpo: dois parciais com queda rápida."""
    dur = 0.11
    t = np.arange(int(SR * dur)) / SR
    env = np.exp(-t * 38) * np.minimum(1, t / 0.002)
    sig = np.sin(2 * np.pi * 1320 * t) + 0.4 * np.sin(2 * np.pi * 1980 * t)
    return sig * env


def advance() -> np.ndarray:
    """Varredura ascendente de 1,0 s (a duração da viagem do avatar), que
    termina num pequeno brilho. Dura exatamente como a animação."""
    dur = 1.0
    n = int(SR * dur)
    t = np.arange(n) / SR
    u = t / dur
    freq = 260 * (4.0 ** (u ** 1.6))          # 260 Hz -> ~1040 Hz
    phase = 2 * np.pi * np.cumsum(freq) / SR
    sweep = np.sin(phase) + 0.35 * np.sin(2 * phase)
    sweep *= np.sin(np.pi * np.minimum(1, u * 1.15)) ** 0.8 * (0.35 + 0.65 * u)
    # brilho final (chegada)
    chime_t = np.clip(t - 0.82, 0, None)
    chime = (np.sin(2 * np.pi * 1568 * chime_t) + 0.5 * np.sin(2 * np.pi * 2352 * chime_t))
    chime *= np.exp(-chime_t * 14) * (t >= 0.82) * 0.9
    sig = sweep * 0.7 + chime
    fade = np.minimum(1, (dur - t) / 0.03)
    return sig * fade


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    write("tap.wav", tap(), 0.5)
    write("advance.wav", advance(), 0.45)
