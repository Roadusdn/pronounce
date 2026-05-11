import math
import subprocess
import wave
from array import array
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import List, Optional, Tuple


TARGET_SAMPLE_RATE = 16000
FRAME_SIZE = 480
HOP_SIZE = 160
MIN_PITCH_HZ = 80
MAX_PITCH_HZ = 400
MIN_RMS = 500.0
ENDING_FRAME_COUNT = 5
REFERENCE_AUDIO_DIR = Path("data/audio/reference")
REFERENCE_AUDIO_MAP: dict[str, Path] = {}


def _decode_to_wav(source_path: Path, output_path: Path) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(source_path),
            "-ac",
            "1",
            "-ar",
            str(TARGET_SAMPLE_RATE),
            "-f",
            "wav",
            str(output_path),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def resolve_reference_audio(
    expected_text: str,
    uploaded_reference_audio_path: Optional[Path] = None,
) -> Tuple[Optional[Path], Optional[str]]:
    if uploaded_reference_audio_path is not None:
        if uploaded_reference_audio_path.exists():
            return uploaded_reference_audio_path, None
        return None, "reference audio upload was provided but could not be saved"

    reference_audio_path = REFERENCE_AUDIO_MAP.get(expected_text.strip())
    if reference_audio_path is None:
        return None, "no reference audio mapping found for expected_text in data/audio/reference"

    if not reference_audio_path.exists():
        return None, "mapped reference audio file is missing in data/audio/reference"

    return reference_audio_path, None


def _load_wav_samples(audio_path: Path) -> Tuple[int, List[int]]:
    with wave.open(str(audio_path), "rb") as wav_file:
        sample_rate = wav_file.getframerate()
        frames = wav_file.readframes(wav_file.getnframes())

    samples = array("h")
    samples.frombytes(frames)
    return sample_rate, samples.tolist()


def _calculate_rms(frame: List[int]) -> float:
    if not frame:
        return 0.0

    square_sum = 0.0
    for sample in frame:
        square_sum += float(sample * sample)

    return math.sqrt(square_sum / len(frame))


def _estimate_pitch(frame: List[int], sample_rate: int) -> Optional[float]:
    if len(frame) < FRAME_SIZE or _calculate_rms(frame) < MIN_RMS:
        return None

    min_lag = max(1, int(sample_rate / MAX_PITCH_HZ))
    max_lag = max(min_lag, int(sample_rate / MIN_PITCH_HZ))

    best_lag = 0
    best_score = 0.0

    for lag in range(min_lag, max_lag + 1):
        score = 0.0
        for index in range(len(frame) - lag):
            score += frame[index] * frame[index + lag]

        if score > best_score:
            best_score = score
            best_lag = lag

    if best_lag == 0:
        return None

    return round(sample_rate / best_lag, 2)


def _extract_pitch_contour(samples: List[int], sample_rate: int) -> List[float]:
    pitches: List[float] = []

    for start in range(0, max(0, len(samples) - FRAME_SIZE + 1), HOP_SIZE):
        frame = samples[start : start + FRAME_SIZE]
        pitch = _estimate_pitch(frame, sample_rate)
        if pitch is not None:
            pitches.append(pitch)

    return pitches


def _calculate_average(values: List[float]) -> Optional[float]:
    if not values:
        return None
    return sum(values) / len(values)


def _calculate_ending_slope(values: List[float]) -> Optional[float]:
    if len(values) < 2:
        return None

    ending_values = values[-ENDING_FRAME_COUNT:]
    if len(ending_values) < 2:
        return None

    return (ending_values[-1] - ending_values[0]) / (len(ending_values) - 1)


def _calculate_pitch_similarity(
    reference_pitches: List[float], uploaded_pitches: List[float]
) -> Optional[float]:
    reference_average = _calculate_average(reference_pitches)
    uploaded_average = _calculate_average(uploaded_pitches)

    if reference_average is None or uploaded_average is None or reference_average <= 0:
        return None

    difference_ratio = abs(reference_average - uploaded_average) / reference_average
    similarity = max(0.0, 100.0 - (difference_ratio * 100.0))
    return round(similarity, 2)


def _calculate_ending_slope_difference(
    reference_pitches: List[float], uploaded_pitches: List[float]
) -> Optional[float]:
    reference_slope = _calculate_ending_slope(reference_pitches)
    uploaded_slope = _calculate_ending_slope(uploaded_pitches)

    if reference_slope is None or uploaded_slope is None:
        return None

    return round(abs(reference_slope - uploaded_slope), 2)


def score_prosody(
    reference_audio_path: Optional[Path], uploaded_audio_path: Path
) -> dict[str, object]:
    if reference_audio_path is None:
        return {
            "pitch_similarity": None,
            "ending_slope_difference": None,
            "reason": "reference audio is missing",
        }

    try:
        with TemporaryDirectory() as temp_dir:
            temp_dir_path = Path(temp_dir)
            reference_wav_path = temp_dir_path / "reference.wav"
            uploaded_wav_path = temp_dir_path / "uploaded.wav"

            _decode_to_wav(reference_audio_path, reference_wav_path)
            _decode_to_wav(uploaded_audio_path, uploaded_wav_path)

            reference_sample_rate, reference_samples = _load_wav_samples(reference_wav_path)
            uploaded_sample_rate, uploaded_samples = _load_wav_samples(uploaded_wav_path)

            reference_pitches = _extract_pitch_contour(
                reference_samples, reference_sample_rate
            )
            uploaded_pitches = _extract_pitch_contour(
                uploaded_samples, uploaded_sample_rate
            )
    except (OSError, subprocess.SubprocessError, wave.Error):
        return {
            "pitch_similarity": None,
            "ending_slope_difference": None,
            "reason": "failed to decode audio for prosody scoring",
        }

    pitch_similarity = _calculate_pitch_similarity(
        reference_pitches, uploaded_pitches
    )
    ending_slope_difference = _calculate_ending_slope_difference(
        reference_pitches, uploaded_pitches
    )

    reason = None
    if not reference_pitches:
        reason = "reference audio did not contain enough voiced frames"
    elif not uploaded_pitches:
        reason = "uploaded audio did not contain enough voiced frames"
    elif pitch_similarity is None or ending_slope_difference is None:
        reason = "prosody features could not be calculated from the audio"

    return {
        "pitch_similarity": pitch_similarity,
        "ending_slope_difference": ending_slope_difference,
        "reason": reason,
    }
