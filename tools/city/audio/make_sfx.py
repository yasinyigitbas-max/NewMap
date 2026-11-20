"""The street's warning sounds, made here (the repo had none: Yasin's GTA IV list, 20 Nov: car alarms, police and
ambulance sirens, horns). Synthesised, mono 22,050 Hz 16-bit WAV, written to audio/sfx/:

  car_alarm.wav        6 s loop: whoops up, a warble, beeps, a fast sweep (the common four-part car alarm)
  siren_police.wav     4 s loop: the wail, 650 -> 1400 -> 650 Hz
  siren_yelp.wav       1 s loop: the fast yelp of a chase, 650 -> 1400 Hz four times a second
  siren_ambulance.wav  2 s loop: hi-lo, 960 / 770 Hz, half a second each
  horn.wav             0.6 s: a car horn, two notes a third apart (415 + 520 Hz)

A loop's frequencies are scaled a hair so the whole loop holds a whole number of cycles: it loops without a click.
Run:  python -I tools/city/audio/make_sfx.py   (from the project's root)
"""
import os
import sys
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "audio", "sfx")


def tone(freq, harmonics=(1.0, 0.0, 0.33, 0.0, 0.2, 0.0, 0.14), loop=True):
    """A tone that follows freq (Hz per sample), its harmonics with these weights, phase-continuous."""
    f = np.asarray(freq, dtype=np.float64)
    if loop:
        cycles = f.sum() / SR
        f = f * (round(cycles) / cycles)
    ph = 2.0 * np.pi * np.cumsum(f) / SR
    out = np.zeros_like(ph)
    for n, w in enumerate(harmonics, start=1):
        if w:
            out += w * np.sin(n * ph)
    return out / np.max(np.abs(out))


def gate(n, on_s, off_s, ramp_s=0.004):
    """1 for on_s, 0 for off_s, repeated, with short ramps (no clicks)."""
    t = np.arange(n) / SR
    period = on_s + off_s
    x = np.mod(t, period)
    g = np.clip(np.minimum(x / ramp_s, (on_s - x) / ramp_s), 0.0, 1.0)
    return g


def soft(x, drive=1.6):
    return np.tanh(drive * x) / np.tanh(drive)


def write(name, x, gain=0.55):
    x = np.clip(x * gain, -1.0, 1.0)
    data = (x * 32767.0).astype("<i2").tobytes()
    path = os.path.normpath(os.path.join(OUT, name))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print("SFX %s: %.2f s, peak %.2f -> %s" % (name, len(x) / SR, float(np.max(np.abs(x))), path))


def car_alarm():
    n4 = int(1.5 * SR)
    t = np.arange(n4) / SR
    a = 800.0 + 800.0 * np.mod(t, 0.3) / 0.3                                  # five whoops up
    b = np.where(np.mod(t, 0.125) < 0.0625, 1000.0, 1400.0)                   # a warble, 8 a second
    c = np.full(n4, 1250.0)                                                   # beeps
    d = 1100.0 + 400.0 * np.sin(2.0 * np.pi * 4.0 * t)                        # a fast sweep
    f = np.concatenate([a, b, c, d])
    x = soft(tone(f))
    g = np.ones_like(x)
    g[2 * n4:3 * n4] = gate(n4, 0.15, 0.10)
    return x * g


def siren_wail():
    t = np.arange(int(4.0 * SR)) / SR
    f = 650.0 + 750.0 * (0.5 - 0.5 * np.cos(2.0 * np.pi * t / 4.0))
    return soft(tone(f, (1.0, 0.5, 0.33, 0.25, 0.2, 0.16)), 1.3)


def siren_yelp():
    t = np.arange(int(1.0 * SR)) / SR
    f = 650.0 + 750.0 * (0.5 - 0.5 * np.cos(2.0 * np.pi * t / 0.25))
    return soft(tone(f, (1.0, 0.5, 0.33, 0.25, 0.2, 0.16)), 1.3)


def siren_hilo():
    t = np.arange(int(2.0 * SR)) / SR
    f = np.where(np.mod(t, 1.0) < 0.5, 960.0, 770.0)
    # (a few milliseconds of glide between the notes: no click at the change)
    k = int(0.006 * SR)
    f = np.convolve(np.concatenate([f[-k:], f, f[:k]]), np.ones(k) / k, mode="same")[k:-k]
    return soft(tone(f, (1.0, 0.0, 0.4, 0.0, 0.25, 0.0, 0.15)), 1.2)


def horn():
    n = int(0.6 * SR)
    t = np.arange(n) / SR
    x = tone(np.full(n, 415.0), (1.0, 0.6, 0.45, 0.3, 0.2), loop=False) + tone(np.full(n, 520.0), (1.0, 0.6, 0.45, 0.3, 0.2), loop=False)
    env = np.clip(np.minimum(t / 0.012, (0.6 - t) / 0.05), 0.0, 1.0)
    return soft(x / 2.0, 2.2) * env


def main():
    if not os.path.isdir(OUT):
        print("SFX ERROR no audio/sfx folder at", OUT)
        return 1
    write("car_alarm.wav", car_alarm())
    write("siren_police.wav", siren_wail(), 0.6)
    write("siren_yelp.wav", siren_yelp(), 0.6)
    write("siren_ambulance.wav", siren_hilo(), 0.6)
    write("horn.wav", horn(), 0.7)
    return 0


if __name__ == "__main__":
    sys.exit(main())
