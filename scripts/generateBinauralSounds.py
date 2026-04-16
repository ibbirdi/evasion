"""
Generates the 4 binaural tracks used by the Oasis app.

Each track is a seamless 15-minute stereo WAV that layers:
  - A pure binaural carrier (L and R at slightly different frequencies). This
    produces the "beat" the brain reconstructs in the target bandwidth.
  - A mono harmonic pad (3rd and 5th overtones of the carrier average), slowly
    amplitude-modulated to create a breathing feel. Kept mono so it does NOT
    introduce a competing binaural beat that would shift the entrainment.
  - A slow stereo pan applied only to the pad, which gives the track a sense of
    width and motion without disturbing the pure carrier reaching each ear.

All LFO frequencies are chosen so they complete an integer number of cycles
over the 15-minute duration, so the track loops seamlessly.

Output files are converted to HE-AAC m4a (40 kbps) with `afconvert` to match
the encoding used for the ambient sounds, then copied into the app bundle
resources directory.
"""

import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy.io import wavfile

DURATION_SECONDS = 900  # 15 minutes
SAMPLE_RATE = 44100

# Choosing carrier frequencies: the binaural beat sits in the target band
# (R - L), while the average frequency stays low enough to feel grounded.
TRACKS = [
    {
        "name": "1_binaural_sleep_delta",
        "f_left": 60,
        "f_right": 63,         # 3 Hz beat (delta: deep sleep)
        "carrier_amp": 0.30,
        "pad_amp": (0.18, 0.10),
    },
    {
        "name": "2_binaural_meditation_theta",
        "f_left": 70,
        "f_right": 76,         # 6 Hz beat (theta: meditation)
        "carrier_amp": 0.30,
        "pad_amp": (0.18, 0.10),
    },
    {
        "name": "3_binaural_relax_alpha",
        "f_left": 80,
        "f_right": 90,         # 10 Hz beat (alpha: relaxation)
        "carrier_amp": 0.28,
        "pad_amp": (0.17, 0.09),
    },
    {
        "name": "4_binaural_focus_beta",
        "f_left": 90,
        "f_right": 105,        # 15 Hz beat (beta: focus)
        "carrier_amp": 0.28,
        "pad_amp": (0.16, 0.09),
    },
]

# LFOs chosen so N_cycles = f * DURATION_SECONDS is an integer: perfect loop.
BREATH_RATE_HZ = 0.12   # 108 cycles over 900 s, ~7.2 breaths / minute (calm rate)
BREATH_MIN = 0.55       # envelope floor (pad never fully silent)
BREATH_MAX = 1.00       # envelope ceiling

PAN_RATE_HZ = 0.02      # 18 cycles over 900 s, one sweep every 50 s
PAN_DEPTH = 0.60        # -0.6 to +0.6 (0 = centre, ±1 = hard pan)

ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "ios-native/OasisNative/Resources/Audio"


def generate_track(spec: dict) -> np.ndarray:
    t = np.linspace(0, DURATION_SECONDS, int(SAMPLE_RATE * DURATION_SECONDS), endpoint=False)

    f_L = spec["f_left"]
    f_R = spec["f_right"]
    carrier_amp = spec["carrier_amp"]
    pad_amp_h3, pad_amp_h5 = spec["pad_amp"]

    # Layer 1 — binaural carrier. Each ear receives its own pure sine; the
    # brain interprets the (R - L) difference as a beat at the target rate.
    beat_left = carrier_amp * np.sin(2 * np.pi * f_L * t)
    beat_right = carrier_amp * np.sin(2 * np.pi * f_R * t)

    # Layer 2 — mono harmonic pad built on the 3rd and 5th harmonics of the
    # carrier average. Rounding to integer Hz keeps the loop seamless and
    # avoids any drift between instances of the pad across loops.
    f_avg = (f_L + f_R) / 2.0
    h3 = int(round(f_avg * 3))
    h5 = int(round(f_avg * 5))

    pad = pad_amp_h3 * np.sin(2 * np.pi * h3 * t) + pad_amp_h5 * np.sin(2 * np.pi * h5 * t)

    # Breath modulation — slow AM so the pad rises and falls like a calm breath.
    breath = BREATH_MIN + (BREATH_MAX - BREATH_MIN) * (0.5 + 0.5 * np.sin(2 * np.pi * BREATH_RATE_HZ * t))
    pad = pad * breath

    # Layer 3 — slow equal-power pan on the pad. The binaural carrier is NOT
    # panned so the beat stays intact; the pad provides the spatial impression.
    pan_lfo = PAN_DEPTH * np.sin(2 * np.pi * PAN_RATE_HZ * t)    # -0.6 … +0.6
    angle = (pan_lfo + 1.0) * (np.pi / 4.0)                      # 0 … π/2
    pad_left = pad * np.cos(angle)
    pad_right = pad * np.sin(angle)

    signal_left = beat_left + pad_left
    signal_right = beat_right + pad_right

    # Normalize if we somehow exceeded headroom, leaving a small safety margin.
    peak = max(np.max(np.abs(signal_left)), np.max(np.abs(signal_right)))
    if peak > 0.94:
        scale = 0.94 / peak
        signal_left *= scale
        signal_right *= scale

    stereo = np.vstack((signal_left, signal_right)).T
    return np.int16(stereo * 32767)


def convert_to_m4a(wav_path: Path, m4a_path: Path) -> None:
    subprocess.run(
        [
            "afconvert",
            "-f", "m4af",
            "-d", "aach@22050",
            "-b", "40000",
            "-s", "0",
            str(wav_path),
            str(m4a_path),
        ],
        check=True,
    )


def main() -> int:
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    tmp_dir = ROOT / "scripts" / "_binaural_tmp"
    tmp_dir.mkdir(exist_ok=True)

    for spec in TRACKS:
        name = spec["name"]
        beat = spec["f_right"] - spec["f_left"]
        print(f"[..] {name}  (beat = {beat} Hz, pad on {int(round((spec['f_left']+spec['f_right'])/2*3))}/{int(round((spec['f_left']+spec['f_right'])/2*5))} Hz)")

        stereo = generate_track(spec)
        wav_path = tmp_dir / f"{name}.wav"
        wavfile.write(str(wav_path), SAMPLE_RATE, stereo)

        m4a_path = AUDIO_DIR / f"{name}.m4a"
        convert_to_m4a(wav_path, m4a_path)

        size_kb = m4a_path.stat().st_size / 1024
        print(f"[ok] {m4a_path.name} — {size_kb:.0f} KB")

    # Clean up WAV intermediates.
    for wav in tmp_dir.glob("*.wav"):
        wav.unlink()
    tmp_dir.rmdir()

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
