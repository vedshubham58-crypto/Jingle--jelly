"""Renders the game's music and sound effects into godot/audio/*.wav.

Everything is synthesised here, so there are no third-party recordings to
license. Songs come from godot/data/songs.json (public-domain nursery rhymes).
Run: python3 tools/make_audio.py
"""
import json
import pathlib
import subprocess
import wave

import numpy as np

RATE = 22050
ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "godot" / "audio"
rng = np.random.default_rng(7)

# Song keys (pitch class of the tonic) for the automatic chords.
KEYS = {"twinkle": 0, "bus": 5, "farm": 7}


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def env(n, attack=0.005, decay=0.5):
    t = np.arange(n) / RATE
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-t / decay)


def bell(midi, dur, vol=0.5):
    """Bright marimba/glockenspiel-like tone for the melody."""
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    f = hz(midi)
    s = np.sin(2 * np.pi * f * t) * env(n, 0.004, 0.55)
    s += 0.35 * np.sin(2 * np.pi * 2 * f * t) * env(n, 0.002, 0.25)
    s += 0.12 * np.sin(2 * np.pi * 4.0 * f * t) * env(n, 0.001, 0.06)
    # Soft sustained "ooh" layer so the tune is easy to sing along with.
    s += 0.30 * np.sin(2 * np.pi * f * t + 0.3 * np.sin(2 * np.pi * 5 * t)) * np.clip(t / 0.05, 0, 1) * np.clip((dur - t) / 0.08, 0, 1)
    return vol * s


def pluck(midi, dur, vol=0.18):
    """Karplus-Strong ukulele pluck."""
    n = int(dur * RATE)
    period = max(2, int(RATE / hz(midi)))
    buf = rng.uniform(-1, 1, period)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = 0.5 * (buf[i % period] + buf[(i + 1) % period]) * 0.996
    return vol * out


def bass(midi, dur, vol=0.35):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    f = hz(midi)
    return vol * (np.sin(2 * np.pi * f * t) + 0.2 * np.sin(4 * np.pi * f * t)) * env(n, 0.01, 0.4)


def kick(vol=0.45):
    n = int(0.18 * RATE)
    t = np.arange(n) / RATE
    f = 110 * np.exp(-t * 18) + 45
    return vol * np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t * 14)


def shaker(vol=0.08):
    n = int(0.06 * RATE)
    s = rng.uniform(-1, 1, n)
    s = np.diff(s, prepend=0)  # brighter
    return vol * s * np.exp(-np.arange(n) / RATE * 60)


def add(track, sound, at):
    i = int(at * RATE)
    if i >= len(track):
        return
    j = min(len(track), i + len(sound))
    track[i:j] += sound[: j - i]


CHORDS = {"I": [0, 4, 7], "IV": [5, 9, 0], "V": [7, 11, 2], "vi": [9, 0, 4]}


def pick_chord(pcs, key):
    best, score = "I", -1
    for name in ["I", "V", "IV", "vi"]:
        tones = {(key + x) % 12 for x in CHORDS[name]}
        s = sum(2 if p in tones else -1 for p in pcs) + (0.5 if name == "I" else 0)
        if s > score:
            best, score = name, s
    return best


def render_song(song):
    key = KEYS[song["id"]]
    beat = 60.0 / song["bpm"]
    lead = song["lead_beats"] * beat
    notes = []  # (start_beat, midi, beats)
    b = 0.0
    for line in song["lines"]:
        for midi, beats, _ in line:
            notes.append((b, midi, beats))
            b += beats
    total_beats = b
    length = lead + total_beats * beat + 2.5
    track = np.zeros(int(length * RATE))

    # Count-in: four soft clicks so kids know it is starting.
    clicks = int(round(song["lead_beats"]))
    for k in range(clicks):
        add(track, bell(96 if k == 0 else 91, 0.15, 0.18), lead - (clicks - k) * beat)

    for start, midi, beats in notes:
        if midi:
            add(track, bell(midi, beats * beat + 0.25), lead + start * beat)

    # Chords every two beats, chosen to fit the melody.
    w = 0.0
    while w < total_beats:
        pcs = [m % 12 for s, m, d in notes if m and s < w + 2 and s + d > w]
        name = pick_chord(pcs, key)
        root = 48 + (key + CHORDS[name][0]) % 12
        add(track, bass(root - 12, 2 * beat), lead + w * beat)
        for k, iv in enumerate(CHORDS[name]):
            add(track, pluck(60 + (key + iv) % 12, 2 * beat), lead + w * beat + 0.012 * k)
            add(track, pluck(60 + (key + iv) % 12, beat, 0.1), lead + (w + 1) * beat + 0.012 * k)
        w += 2
    for k in range(int(total_beats)):
        if k % 2 == 0:
            add(track, kick(), lead + k * beat)
        add(track, shaker(), lead + (k + 0.5) * beat)
        add(track, shaker(0.05), lead + k * beat)

    # Little "ta-da" at the end.
    end = lead + total_beats * beat + 0.1
    for k, m in enumerate([key + 72, key + 76, key + 79, key + 84]):
        add(track, bell(m, 0.9, 0.35), end + 0.09 * k)
    return track


def home_loop():
    """An original 8-bar loop for the home screen."""
    bpm = 100
    beat = 60.0 / bpm
    tune = [76, 79, 81, 79, 76, 72, 74, 76, 74, 72, 69, 72, 74, 76, 74, 0,
            76, 79, 81, 84, 81, 79, 76, 79, 77, 76, 74, 72, 74, 72, 72, 0]
    chords = ["I", "I", "vi", "vi", "IV", "IV", "V", "V", "I", "I", "vi", "vi", "IV", "V", "I", "I"]
    length = len(tune) * beat
    track = np.zeros(int(length * RATE) + RATE)
    for k, m in enumerate(tune):
        if m:
            add(track, bell(m, beat * 0.9, 0.3), k * beat)
    for k, name in enumerate(chords):
        root = 48 + CHORDS[name][0] % 12
        add(track, bass(root - 12, 2 * beat, 0.25), k * 2 * beat)
        for j, iv in enumerate(CHORDS[name]):
            add(track, pluck(60 + iv % 12, 2 * beat, 0.12), k * 2 * beat + 0.012 * j)
    for k in range(len(tune)):
        add(track, shaker(0.05), (k + 0.5) * beat)
    # Fold the tail into the start so the loop is seamless.
    n = int(length * RATE)
    tail = track[n:]
    track = track[:n]
    track[: len(tail)] += tail
    return track


def sweep(f0, f1, dur, vol=0.5, shape="sine", decay=None):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    f = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / RATE
    s = np.sin(ph) if shape == "sine" else np.sign(np.sin(ph)) * 0.6
    e = np.exp(-t / decay) if decay else np.clip((dur - t) / (dur * 0.3), 0, 1)
    return vol * s * e * np.clip(t / 0.004, 0, 1)


def noise(dur, vol, decay, lowpass=0.0):
    n = int(dur * RATE)
    s = rng.uniform(-1, 1, n)
    if lowpass:
        for i in range(1, n):
            s[i] = s[i - 1] * lowpass + s[i] * (1 - lowpass)
        s /= max(1e-6, np.abs(s).max())
    return vol * s * np.exp(-np.arange(n) / RATE / decay)


def effects():
    fx = {}
    s = sweep(500, 1400, 0.09, 0.6, decay=0.03)
    add(s, noise(0.03, 0.15, 0.008), 0)
    fx["pop"] = s
    fx["boing"] = sweep(180, 420, 0.35, 0.5, decay=0.15) * (1 + 0.5 * np.sin(np.arange(int(0.35 * RATE)) / RATE * 2 * np.pi * 18))
    fx["tap"] = bell(84, 0.25, 0.4)
    s = np.zeros(int(1.2 * RATE))
    for k, m in enumerate([72, 76, 79, 84, 88]):
        add(s, bell(m, 0.6, 0.35), 0.08 * k)
    fx["chime"] = s
    s = np.zeros(int(1.8 * RATE))
    for k, m in enumerate([72, 76, 79, 84, 79, 84, 88, 91]):
        add(s, bell(m, 0.7, 0.3), 0.1 * k)
    for k in range(10):
        add(s, bell(96 + int(rng.integers(0, 7)), 0.3, 0.12), 0.6 + 0.08 * k)
    fx["yay"] = s
    s = np.zeros(int(0.9 * RATE))
    for k, m in enumerate([96, 100, 103, 108]):
        add(s, bell(m, 0.4, 0.2), 0.06 * k)
    fx["twinkle"] = s
    s = np.zeros(int(0.7 * RATE))
    for k in range(2):
        b = sweep(440, 440, 0.18, 0.35, shape="square") + sweep(554, 554, 0.18, 0.25, shape="square")
        add(s, b, 0.25 * k)
    fx["horn"] = s
    fx["swish"] = noise(0.35, 0.35, 0.12, lowpass=0.6) * np.sin(np.linspace(0, np.pi, int(0.35 * RATE)))
    s = np.zeros(int(0.5 * RATE))
    for k in range(6):
        add(s, sweep(700 + 150 * k, 1500 + 200 * k, 0.05, 0.25, decay=0.02), 0.07 * k + rng.uniform(0, 0.02))
    fx["scrub"] = s
    s = noise(1.2, 0.35, 0.6, lowpass=0.5)
    s = np.concatenate([s, np.zeros(int(0.2 * RATE))])
    for k in range(14):
        add(s, sweep(900, 2200, 0.04, 0.15, decay=0.015), rng.uniform(0, 1.0))
    fx["splash"] = s
    fx["wrong"] = sweep(330, 220, 0.3, 0.35, decay=0.15)
    return fx


def save(name, data):
    data = np.asarray(data, dtype=np.float64)
    peak = np.abs(data).max()
    if peak > 0.95:
        data = data * (0.95 / peak)
    pcm = (data * 32767).astype("<i2")
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    print(f"{name}.wav {len(data) / RATE:.1f}s")


def save_ogg(name, data):
    """Long music goes out as Ogg Vorbis to keep the APK small."""
    save(name, data)
    wav = OUT / f"{name}.wav"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4", str(OUT / f"{name}.ogg")], check=True)
    wav.unlink()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    songs = json.loads((ROOT / "godot" / "data" / "songs.json").read_text())["songs"]
    for song in songs:
        save_ogg(f"song_{song['id']}", render_song(song))
    save_ogg("home_loop", home_loop())
    for name, data in effects().items():
        save(f"sfx_{name}", data)


if __name__ == "__main__":
    main()
