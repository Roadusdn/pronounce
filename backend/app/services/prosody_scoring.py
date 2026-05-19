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
MIN_RMS = 120.0
RELATIVE_RMS_RATIO = 0.08
ENDING_FRAME_COUNT = 5
ENDING_SLOPE_TOLERANCE = 8.0
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


def _estimate_pitch(
        frame: List[int],
        sample_rate: int,
        min_rms: float = MIN_RMS,
) -> Optional[float]:
    if len(frame) < FRAME_SIZE or _calculate_rms(frame) < min_rms:
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


def _frame_rms_values(samples: List[int]) -> List[float]:
    values: List[float] = []
    for start in range(0, max(0, len(samples) - FRAME_SIZE + 1), HOP_SIZE):
        frame = samples[start: start + FRAME_SIZE]
        values.append(_calculate_rms(frame))
    return values


def _adaptive_rms_threshold(samples: List[int]) -> float:
    values = _frame_rms_values(samples)
    if not values:
        return MIN_RMS

    peak = max(values)
    if peak <= 0:
        return MIN_RMS

    return max(MIN_RMS, peak * RELATIVE_RMS_RATIO)


def _extract_pitch_contour(samples: List[int], sample_rate: int) -> List[float]:
    pitches: List[float] = []
    min_rms = _adaptive_rms_threshold(samples)

    for start in range(0, max(0, len(samples) - FRAME_SIZE + 1), HOP_SIZE):
        frame = samples[start: start + FRAME_SIZE]
        pitch = _estimate_pitch(frame, sample_rate, min_rms)
        if pitch is not None:
            pitches.append(pitch)

    if not pitches and min_rms > 40:
        relaxed_rms = max(40.0, min_rms * 0.45)
        for start in range(0, max(0, len(samples) - FRAME_SIZE + 1), HOP_SIZE):
            frame = samples[start: start + FRAME_SIZE]
            pitch = _estimate_pitch(frame, sample_rate, relaxed_rms)
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


def _slope_pattern(slope: Optional[float]) -> str:
    if slope is None:
        return "unknown"
    if slope > ENDING_SLOPE_TOLERANCE:
        return "rising"
    if slope < -ENDING_SLOPE_TOLERANCE:
        return "falling"
    return "flat"


def _resample(values: List[float], target_length: int) -> List[float]:
    if not values or target_length <= 0:
        return []
    if len(values) == target_length:
        return values
    if len(values) == 1:
        return [values[0]] * target_length

    resampled: List[float] = []
    source_last = len(values) - 1
    target_last = max(1, target_length - 1)
    for index in range(target_length):
        source_position = index * source_last / target_last
        left = int(math.floor(source_position))
        right = min(source_last, left + 1)
        ratio = source_position - left
        value = values[left] + ((values[right] - values[left]) * ratio)
        resampled.append(value)
    return resampled


def _normalize(values: List[float]) -> List[float]:
    if not values:
        return []
    min_value = min(values)
    max_value = max(values)
    value_range = max_value - min_value
    if abs(value_range) < 0.0001:
        return [0.5 for _ in values]
    return [(value - min_value) / value_range for value in values]


def _calculate_dtw_distance(
        reference_pitches: List[float],
        uploaded_pitches: List[float],
) -> Optional[float]:
    if not reference_pitches or not uploaded_pitches:
        return None

    target_length = min(40, max(len(reference_pitches), len(uploaded_pitches)))
    reference = _normalize(_resample(reference_pitches, target_length))
    uploaded = _normalize(_resample(uploaded_pitches, target_length))

    previous = [math.inf] * (target_length + 1)
    previous[0] = 0.0

    for i in range(1, target_length + 1):
        current = [math.inf] * (target_length + 1)
        for j in range(1, target_length + 1):
            cost = abs(reference[i - 1] - uploaded[j - 1])
            current[j] = cost + min(
                current[j - 1],
                previous[j],
                previous[j - 1],
            )
        previous = current

    return round(previous[target_length] / target_length, 4)


def _score_from_distance(distance: Optional[float]) -> int:
    if distance is None:
        return 0
    return max(0, min(100, round(100 - (distance * 100))))


def _calculate_speech_rate(
        voiced_frame_count: int,
        duration_sec: float,
) -> Optional[float]:
    if duration_sec <= 0 or voiced_frame_count <= 0:
        return None
    return round(voiced_frame_count / duration_sec, 2)


def _calculate_rhythm_score(
        reference_rate: Optional[float],
        uploaded_rate: Optional[float],
) -> int:
    if reference_rate is None or uploaded_rate is None or reference_rate <= 0:
        return 0
    difference_ratio = abs(reference_rate - uploaded_rate) / reference_rate
    return max(0, min(100, round(100 - (difference_ratio * 100))))


def _calculate_pitch_similarity(
        reference_pitches: List[float],
        uploaded_pitches: List[float],
) -> Optional[float]:
    reference_average = _calculate_average(reference_pitches)
    uploaded_average = _calculate_average(uploaded_pitches)

    if reference_average is None or uploaded_average is None or reference_average <= 0:
        return None

    difference_ratio = abs(reference_average - uploaded_average) / reference_average
    similarity = max(0.0, 100.0 - (difference_ratio * 100.0))
    return round(similarity, 2)


def _calculate_ending_slope_difference(
        reference_pitches: List[float],
        uploaded_pitches: List[float],
) -> Optional[float]:
    reference_slope = _calculate_ending_slope(reference_pitches)
    uploaded_slope = _calculate_ending_slope(uploaded_pitches)

    if reference_slope is None or uploaded_slope is None:
        return None

    return round(abs(reference_slope - uploaded_slope), 2)


def _diagnosis_message(
        *,
        reason: Optional[str],
        ending_pattern_match: bool,
        rhythm_score: int,
        pitch_similarity: Optional[float],
) -> str:
    if reason:
        return reason
    if ending_pattern_match and rhythm_score >= 80:
        return "기준 발음과 끝 억양 방향, 전체 리듬이 안정적으로 비슷해요."
    if ending_pattern_match:
        return "끝 억양 방향은 잘 맞았어요. 전체 리듬과 속도를 조금 더 맞춰보세요."
    if pitch_similarity is not None and pitch_similarity >= 75:
        return "전체 높낮이는 비슷하지만 문장 끝 억양 방향을 기준 발음처럼 다시 맞춰보세요."
    return "기준 발음을 들으며 문장 끝 높낮이와 전체 리듬을 천천히 다시 따라 해보세요."


def _diagnosis_title(score: int, reason: Optional[str]) -> str:
    if reason:
        return "억양을 다시 확인해보세요"
    if score >= 90:
        return "억양이 안정적이에요"
    if score >= 75:
        return "억양 흐름이 괜찮아요"
    return "억양 연습이 필요해요"


def _score(value: Optional[float]) -> int:
    if value is None:
        return 0
    return max(0, min(100, round(value)))


def _clean_diagnosis_title(score: int, reason: Optional[str]) -> str:
    if reason:
        return "억양을 다시 확인해보세요"
    if score >= 90:
        return "억양이 안정적이에요"
    if score >= 75:
        return "억양 흐름은 괜찮아요"
    return "억양 연습이 필요해요"


def _clean_diagnosis_message(
        *,
        reason: Optional[str],
        ending_pattern_match: bool,
        rhythm_score: int,
        pitch_similarity: Optional[float],
) -> str:
    if reason:
        return reason
    if ending_pattern_match and rhythm_score >= 80:
        return "기준 발음과 끝 억양 방향, 전체 리듬이 안정적으로 비슷해요."
    if ending_pattern_match:
        return "끝 억양 방향은 잘 맞아요. 전체 리듬과 속도를 조금 더 맞춰보세요."
    if pitch_similarity is not None and pitch_similarity >= 75:
        return "전체 높낮이는 비슷하지만 문장 끝 억양 방향을 기준 발음처럼 다시 맞춰보세요."
    return "기준 발음을 들으며 문장 끝 높낮이와 전체 리듬을 천천히 다시 따라 해보세요."


def _missing_reference_payload() -> dict[str, object]:
    message = "억양 비교에 필요한 기준 음성이 아직 준비되지 않았습니다."
    return {
        "pitch_similarity": None,
        "ending_slope_difference": None,
        "ending_pattern_match": False,
        "dtw_distance": None,
        "speech_rate": None,
        "reference_speech_rate": None,
        "learner_speech_rate": None,
        "rhythm_score": 0,
        "prosody_score": 0,
        "reference_pitch_json": [],
        "learner_pitch_json": [],
        "expected_pattern": "unknown",
        "ending_pattern": "unknown",
        "diagnosis_title": "기준 음성이 없습니다",
        "diagnosis_message": message,
        "hint_json": ["기준 음성이 준비된 문장으로 다시 연습해보세요."],
        "reason": message,
    }

    message = "억양 비교에 필요한 기준 음성이 아직 준비되지 않았습니다."
    return {
        "pitch_similarity": None,
        "ending_slope_difference": None,
        "ending_pattern_match": False,
        "dtw_distance": None,
        "speech_rate": None,
        "reference_speech_rate": None,
        "learner_speech_rate": None,
        "rhythm_score": 0,
        "prosody_score": 0,
        "reference_pitch_json": [],
        "learner_pitch_json": [],
        "expected_pattern": "unknown",
        "ending_pattern": "unknown",
        "diagnosis_title": "기준 음성이 없습니다",
        "diagnosis_message": message,
        "hint_json": ["기준 음성이 준비된 문장으로 다시 연습해보세요."],
        "reason": message,
    }


def _decode_failure_payload() -> dict[str, object]:
    message = "오디오를 억양 분석용 형식으로 변환하지 못했습니다."
    return {
        "pitch_similarity": None,
        "ending_slope_difference": None,
        "ending_pattern_match": False,
        "dtw_distance": None,
        "speech_rate": None,
        "reference_speech_rate": None,
        "learner_speech_rate": None,
        "rhythm_score": 0,
        "prosody_score": 0,
        "reference_pitch_json": [],
        "learner_pitch_json": [],
        "expected_pattern": "unknown",
        "ending_pattern": "unknown",
        "diagnosis_title": "억양 분석 실패",
        "diagnosis_message": message,
        "hint_json": ["녹음 파일을 다시 만들고 분석을 시도해보세요."],
        "reason": message,
    }

    message = "오디오를 억양 분석용 형식으로 변환하지 못했습니다."
    return {
        "pitch_similarity": None,
        "ending_slope_difference": None,
        "ending_pattern_match": False,
        "dtw_distance": None,
        "speech_rate": None,
        "reference_speech_rate": None,
        "learner_speech_rate": None,
        "rhythm_score": 0,
        "prosody_score": 0,
        "reference_pitch_json": [],
        "learner_pitch_json": [],
        "expected_pattern": "unknown",
        "ending_pattern": "unknown",
        "diagnosis_title": "억양 분석 실패",
        "diagnosis_message": message,
        "hint_json": ["녹음 파일을 다시 만들고 분석을 시도해보세요."],
        "reason": message,
    }


def score_prosody(
        reference_audio_path: Optional[Path],
        uploaded_audio_path: Path,
) -> dict[str, object]:
    if reference_audio_path is None:
        return _missing_reference_payload()

    try:
        with TemporaryDirectory() as temp_dir:
            temp_dir_path = Path(temp_dir)
            reference_wav_path = temp_dir_path / "reference.wav"
            uploaded_wav_path = temp_dir_path / "uploaded.wav"

            _decode_to_wav(reference_audio_path, reference_wav_path)
            _decode_to_wav(uploaded_audio_path, uploaded_wav_path)

            reference_sample_rate, reference_samples = _load_wav_samples(
                reference_wav_path
            )
            uploaded_sample_rate, uploaded_samples = _load_wav_samples(
                uploaded_wav_path
            )

            reference_pitches = _extract_pitch_contour(
                reference_samples,
                reference_sample_rate,
            )
            uploaded_pitches = _extract_pitch_contour(
                uploaded_samples,
                uploaded_sample_rate,
            )
            reference_duration_sec = len(reference_samples) / reference_sample_rate
            uploaded_duration_sec = len(uploaded_samples) / uploaded_sample_rate
    except (OSError, subprocess.SubprocessError, wave.Error):
        return _decode_failure_payload()

    pitch_similarity = _calculate_pitch_similarity(
        reference_pitches,
        uploaded_pitches,
    )
    reference_slope = _calculate_ending_slope(reference_pitches)
    uploaded_slope = _calculate_ending_slope(uploaded_pitches)
    ending_slope_difference = _calculate_ending_slope_difference(
        reference_pitches,
        uploaded_pitches,
    )
    expected_pattern = _slope_pattern(reference_slope)
    ending_pattern = _slope_pattern(uploaded_slope)
    ending_pattern_match = (
        expected_pattern != "unknown"
        and ending_pattern != "unknown"
        and expected_pattern == ending_pattern
        and (
            ending_slope_difference is None
            or ending_slope_difference <= ENDING_SLOPE_TOLERANCE * 2
        )
    )
    dtw_distance = _calculate_dtw_distance(reference_pitches, uploaded_pitches)
    contour_score = _score_from_distance(dtw_distance)
    reference_speech_rate = _calculate_speech_rate(
        len(reference_pitches),
        reference_duration_sec,
    )
    learner_speech_rate = _calculate_speech_rate(
        len(uploaded_pitches),
        uploaded_duration_sec,
    )
    rhythm_score = _calculate_rhythm_score(reference_speech_rate, learner_speech_rate)
    speech_rate = learner_speech_rate

    reason = None
    if not reference_pitches:
        reason = "기준 음성에서 억양을 비교할 만큼 충분한 유성 구간을 찾지 못했습니다."
    elif not uploaded_pitches:
        reason = "녹음 음성에서 억양을 비교할 만큼 충분한 유성 구간을 찾지 못했습니다."
    elif pitch_similarity is None or ending_slope_difference is None:
        reason = "오디오에서 억양 특징을 충분히 계산하지 못했습니다."

    if not reference_pitches:
        reason = "기준 음성에서 억양을 비교할 만큼 충분한 유성 구간을 찾지 못했습니다."
    elif not uploaded_pitches:
        reason = "녹음 음성에서 억양을 비교할 만큼 충분한 유성 구간을 찾지 못했습니다."
    elif pitch_similarity is None or ending_slope_difference is None:
        reason = "오디오에서 억양 특징을 충분히 계산하지 못했습니다."

    prosody_score = _score(pitch_similarity)
    if prosody_score == 0 and dtw_distance is not None:
        prosody_score = contour_score
    if reason:
        prosody_score = 0

    diagnosis_title = _diagnosis_title(prosody_score, reason)
    diagnosis_message = _diagnosis_message(
        reason=reason,
        ending_pattern_match=ending_pattern_match,
        rhythm_score=rhythm_score,
        pitch_similarity=pitch_similarity,
    )
    diagnosis_title = _clean_diagnosis_title(prosody_score, reason)
    diagnosis_message = _clean_diagnosis_message(
        reason=reason,
        ending_pattern_match=ending_pattern_match,
        rhythm_score=rhythm_score,
        pitch_similarity=pitch_similarity,
    )

    return {
        "pitch_similarity": pitch_similarity,
        "ending_slope_difference": ending_slope_difference,
        "ending_pattern_match": ending_pattern_match,
        "dtw_distance": dtw_distance,
        "speech_rate": speech_rate,
        "reference_speech_rate": reference_speech_rate,
        "learner_speech_rate": learner_speech_rate,
        "rhythm_score": rhythm_score,
        "contour_score": contour_score,
        "prosody_score": prosody_score,
        "reference_pitch_json": reference_pitches,
        "learner_pitch_json": uploaded_pitches,
        "expected_pattern": expected_pattern,
        "ending_pattern": ending_pattern,
        "diagnosis_title": diagnosis_title,
        "diagnosis_message": diagnosis_message,
        "hint_json": [
            "기준 음성을 한 번 들은 뒤 같은 속도와 리듬으로 다시 따라 말해보세요."
        ],
        "reason": reason,
    }
