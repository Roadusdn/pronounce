import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional
from uuid import uuid4


PROJECT_ROOT = Path(__file__).resolve().parents[2]
ATTEMPTS_DIR = PROJECT_ROOT / "data" / "audio" / "attempts"


class AttemptNotFoundError(ValueError):
    pass


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _attempt_dir(attempt_id: str) -> Path:
    return ATTEMPTS_DIR / attempt_id


def _summary_path(attempt_id: str) -> Path:
    return _attempt_dir(attempt_id) / "attempt.json"


def _phoneme_path(attempt_id: str) -> Path:
    return _attempt_dir(attempt_id) / "phoneme_analysis.json"


def _pitch_path(attempt_id: str) -> Path:
    return _attempt_dir(attempt_id) / "pitch_analysis.json"


def _write_json(path: Path, payload: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def _read_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def create_attempt(user_id: str, utterance_id: str) -> Dict[str, Any]:
    attempt_id = uuid4().hex
    timestamp = _now()
    attempt = {
        "attempt_id": attempt_id,
        "user_id": user_id,
        "utterance_id": utterance_id,
        "status": "started",
        "created_at": timestamp,
        "updated_at": timestamp,
        "audio_path": None,
        "score": None,
        "feedback_type": None,
        "feedback_message": None,
        "error": None,
    }
    _write_json(_summary_path(attempt_id), attempt)
    return attempt


def get_attempt(attempt_id: str) -> Dict[str, Any]:
    path = _summary_path(attempt_id)
    if not path.exists():
        raise AttemptNotFoundError("attempt_id not found: {0}".format(attempt_id))
    return _read_json(path)


def update_attempt(attempt_id: str, fields: Dict[str, Any]) -> Dict[str, Any]:
    attempt = get_attempt(attempt_id)
    attempt.update(fields)
    attempt["updated_at"] = _now()
    _write_json(_summary_path(attempt_id), attempt)
    return attempt


def get_attempt_audio_dir(attempt_id: str) -> Path:
    return _attempt_dir(attempt_id) / "audio"


def save_analysis_result(
    attempt_id: str,
    analysis_result: Dict[str, Any],
) -> Dict[str, Any]:
    feedback = analysis_result["feedback"]
    comparison = analysis_result["comparison"]
    prosody = analysis_result["prosody"]
    utterance = analysis_result["utterance"]

    phoneme_analysis = {
        "attempt_id": attempt_id,
        "utterance": utterance,
        "transcription": analysis_result["transcription"],
        "pronunciation": analysis_result["pronunciation"],
        "comparison": comparison,
    }
    pitch_analysis = {
        "attempt_id": attempt_id,
        "utterance": utterance,
        "prosody": analysis_result["prosody"],
    }

    _write_json(_phoneme_path(attempt_id), phoneme_analysis)
    _write_json(_pitch_path(attempt_id), pitch_analysis)

    return update_attempt(
        attempt_id,
        {
            "status": "completed",
            "score": comparison["simple_score"],
            "overall_score": comparison["simple_score"],
            "pronunciation_score": comparison["simple_score"],
            "pitch_score": prosody.get("pitch_similarity"),
            "transcript": analysis_result["transcription"]["text"],
            "feedback_type": feedback["type"],
            "feedback_message": feedback["message"],
            "top_mismatch": feedback["top_mismatch"],
            "practice_text": utterance["practice_text"],
            "normalized_text": utterance["normalized_text"],
            "clip_filename": utterance.get("clip_filename"),
            "clip_start_sec": utterance.get("clip_start_sec"),
            "clip_end_sec": utterance.get("clip_end_sec"),
            "pause_sec": utterance.get("pause_sec"),
            "subtitle_text": utterance.get("subtitle_text"),
            "difficulty": utterance.get("difficulty"),
            "lesson_id": utterance.get("lesson_id"),
            "lesson_name": utterance.get("lesson_name"),
            "scene_id": utterance.get("scene_id"),
            "scene_name": utterance.get("scene_name"),
            "target_phoneme_group": utterance["target_phoneme_group"],
            "target_phoneme_group_raw": utterance.get("target_phoneme_group_raw"),
            "target_prosody_type": utterance["target_prosody_type"],
            "reference_audio_available": utterance["reference_audio_available"],
            "error": None,
        },
    )


def get_phoneme_analysis(attempt_id: str) -> Optional[Dict[str, Any]]:
    path = _phoneme_path(attempt_id)
    if not path.exists():
        return None
    return _read_json(path)


def get_pitch_analysis(attempt_id: str) -> Optional[Dict[str, Any]]:
    path = _pitch_path(attempt_id)
    if not path.exists():
        return None
    return _read_json(path)
