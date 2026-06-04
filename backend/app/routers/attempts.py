from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel

from app.services.analysis_service import run_full_analysis_from_metadata
from app.services.attemp_store import (
    AttemptNotFoundError,
    clear_attempts,
    clear_temp_files,
    create_attempt,
    get_all_attempts,
    get_attempt,
    get_attempt_audio_dir,
    get_phoneme_analysis,
    get_pitch_analysis,
    save_analysis_result,
    update_attempt,
)
from app.services.metadata_loader import MetadataError, load_utterance_metadata
from app.services.transcription import TranscriptionDependencyError


router = APIRouter(prefix="/api/attempts", tags=["attempts"])


class StartAttemptRequest(BaseModel):
    user_id: str = "local_user"
    utterance_id: str
    lesson_id: Optional[str] = None
    scene_id: Optional[str] = None


def _load_attempt_or_404(attempt_id: str) -> Dict[str, Any]:
    try:
        return get_attempt(attempt_id)
    except AttemptNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc))


def _raise_if_not_ready(attempt: Dict[str, Any]) -> None:
    if attempt["status"] != "completed":
        raise HTTPException(
            status_code=409,
            detail="analysis is not completed for attempt_id: {0}".format(
                attempt["attempt_id"]
            ),
        )


def _score(value: Any) -> int:
    if value is None:
        return 0
    try:
        return int(round(float(value)))
    except (TypeError, ValueError):
        return 0


def _date_only(value: Any) -> str:
    text = str(value or "")
    if len(text) >= 10:
        return text[:10]
    return text


def _attempt_result_payload(attempt: Dict[str, Any]) -> Dict[str, Any]:
    pronunciation_score = _score(
        attempt.get("pronunciation_score") or attempt.get("score")
    )
    pitch_score = _score(attempt.get("pitch_score"))
    overall_score = _score(attempt.get("overall_score") or attempt.get("score"))
    practice_text = attempt.get("practice_text") or attempt.get("subtitle_text") or ""

    return {
        "id": attempt["attempt_id"],
        "attempt_id": attempt["attempt_id"],
        "user_id": attempt["user_id"],
        "utterance_id": attempt["utterance_id"],
        "status": attempt["status"],
        "score": overall_score,
        "overall_score": overall_score,
        "pronunciation_score": pronunciation_score,
        "consonant_score": _score(attempt.get("consonant_score") or pronunciation_score),
        "vowel_score": _score(attempt.get("vowel_score") or pronunciation_score),
        "pitch_score": pitch_score,
        "intonation_score": pitch_score,
        "transcript": attempt.get("transcript") or "",
        "feedback_type": attempt.get("feedback_type"),
        "feedback_message": attempt.get("feedback_message"),
        "summary_feedback": attempt.get("summary_feedback"),
        "pronunciation_feedback": attempt.get("pronunciation_feedback"),
        "prosody_feedback": attempt.get("prosody_feedback"),
        "practice_direction": attempt.get("practice_direction"),
        "clip_filename": attempt.get("clip_filename"),
        "clip_start_sec": attempt.get("clip_start_sec"),
        "clip_end_sec": attempt.get("clip_end_sec"),
        "pause_sec": attempt.get("pause_sec"),
        "subtitle_text": attempt.get("subtitle_text"),
        "sentence_text": practice_text,
        "sentenceText": practice_text,
        "practice_text": practice_text,
        "normalized_text": attempt.get("normalized_text"),
        "difficulty": attempt.get("difficulty"),
        "lesson_id": attempt.get("lesson_id"),
        "lesson_name": attempt.get("lesson_name"),
        "scene_id": attempt.get("scene_id"),
        "scene_name": attempt.get("scene_name"),
        "target_phoneme_group": attempt.get("target_phoneme_group"),
        "target_phoneme_group_raw": attempt.get("target_phoneme_group_raw"),
        "target_prosody_type": attempt.get("target_prosody_type"),
        "created_at": attempt.get("created_at"),
        "updated_at": attempt.get("updated_at"),
        "date": _date_only(attempt.get("created_at")),
        "error": attempt.get("error"),
    }


def _phoneme_payload(attempt_id: str) -> Dict[str, Any]:
    phoneme_analysis = get_phoneme_analysis(attempt_id)
    if phoneme_analysis is None:
        return {
            "attempt_id": attempt_id,
            "phonemes": [],
            "error_ranges": [],
        }

    mismatches = phoneme_analysis.get("comparison", {}).get("target_mismatched_items")
    if mismatches is None:
        mismatches = phoneme_analysis.get("comparison", {}).get("mismatched_items", [])

    phonemes = []
    error_ranges = []
    for item in mismatches:
        expected = item.get("expected") or ""
        actual = item.get("actual") or ""
        note = "expected {0}, heard {1}".format(expected, actual)
        phonemes.append(
            {
                "symbol": expected or actual,
                "expected": expected,
                "actual": actual,
                "score": 0,
                "note": note,
            }
        )
        error_ranges.append(
            {
                "start": item.get("start", 0),
                "end": item.get("end", 0),
                "label": expected or actual,
                "message": note,
                "severity": "warning",
            }
        )

    phoneme_analysis["phonemes"] = phonemes
    phoneme_analysis["error_ranges"] = error_ranges
    return phoneme_analysis


def _pitch_payload(attempt_id: str) -> Dict[str, Any]:
    pitch_analysis = get_pitch_analysis(attempt_id)
    if pitch_analysis is None:
        return {
            "attempt_id": attempt_id,
            "score": 0,
            "summary": "",
            "reference_contour": [],
            "user_contour": [],
        }

    prosody = pitch_analysis.get("prosody", {})
    pitch_analysis["score"] = _score(
        prosody.get("prosody_score") or prosody.get("pitch_similarity")
    )
    pitch_analysis["summary"] = (
        prosody.get("diagnosis_message")
        or prosody.get("reason")
        or "억양 분석이 완료되었습니다."
    )
    pitch_analysis["reference_contour"] = (
        prosody.get("reference_pitch_json")
        or prosody.get("reference_contour")
        or []
    )
    pitch_analysis["user_contour"] = (
        prosody.get("learner_pitch_json")
        or prosody.get("user_contour")
        or []
    )
    pitch_analysis["expected_pattern"] = prosody.get("expected_pattern") or ""
    pitch_analysis["ending_pattern"] = prosody.get("ending_pattern") or ""
    pitch_analysis["ending_pattern_match"] = bool(
        prosody.get("ending_pattern_match")
    )
    pitch_analysis["dtw_distance"] = prosody.get("dtw_distance") or 0
    pitch_analysis["speech_rate"] = prosody.get("speech_rate") or 0
    pitch_analysis["rhythm_score"] = _score(prosody.get("rhythm_score"))
    pitch_analysis["prosody_score"] = _score(
        prosody.get("prosody_score") or prosody.get("pitch_similarity")
    )
    pitch_analysis["diagnosis_title"] = (
        prosody.get("diagnosis_title") or "억양 분석"
    )
    pitch_analysis["diagnosis_message"] = (
        prosody.get("diagnosis_message") or pitch_analysis["summary"]
    )
    pitch_analysis["practice_tips"] = prosody.get("hint_json") or []
    return pitch_analysis


def _feedback_payload(attempt: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "attempt_id": attempt["attempt_id"],
        "feedback_type": attempt.get("feedback_type"),
        "feedback_message": attempt.get("feedback_message"),
        "praise": "분석이 완료되었습니다.",
        "improvement": attempt.get("feedback_message") or "",
        "tip": "예문을 들은 뒤 같은 속도와 리듬으로 다시 따라 말해보세요.",
        "top_mismatch": attempt.get("top_mismatch"),
        "score": attempt.get("score"),
        "summary_feedback": attempt.get("summary_feedback"),
        "pronunciation_feedback": attempt.get("pronunciation_feedback"),
        "prosody_feedback": attempt.get("prosody_feedback"),
        "practice_direction": attempt.get("practice_direction"),
    }


@router.get("")
def list_attempts(user_id: Optional[str] = None) -> List[Dict[str, Any]]:
    return [
        _attempt_result_payload(attempt)
        for attempt in get_all_attempts(user_id=user_id)
    ]


@router.delete("")
def delete_attempts(user_id: Optional[str] = None) -> Dict[str, Any]:
    removed_count = clear_attempts(user_id=user_id)
    removed_temp_count = clear_temp_files()
    return {
        "deleted": removed_count,
        "temp_deleted": removed_temp_count,
        "user_id": user_id,
    }


@router.post("/start")
def start_attempt(payload: StartAttemptRequest) -> Dict[str, Any]:
    try:
        metadata = load_utterance_metadata(payload.utterance_id)
    except MetadataError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    attempt = create_attempt(payload.user_id, payload.utterance_id)
    return update_attempt(
        attempt["attempt_id"],
        {
            "lesson_id": payload.lesson_id or metadata.lesson_id,
            "scene_id": payload.scene_id or metadata.scene_id,
            "practice_text": metadata.practice_text,
            "normalized_text": metadata.normalized_text,
            "subtitle_text": metadata.subtitle_text,
        },
    )


@router.post("/{attempt_id}/audio")
async def upload_attempt_audio(
    attempt_id: str,
    audio_file: Optional[UploadFile] = File(None),
    audio: Optional[UploadFile] = File(None),
) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    uploaded_audio = audio_file or audio
    if uploaded_audio is None:
        raise HTTPException(status_code=400, detail="audio file is required")

    audio_dir = get_attempt_audio_dir(attempt_id)
    audio_dir.mkdir(parents=True, exist_ok=True)
    uploaded_filename = Path(uploaded_audio.filename or "uploaded_audio").name
    audio_path = audio_dir / uploaded_filename
    audio_path.write_bytes(await uploaded_audio.read())

    update_attempt(
        attempt_id,
        {
            "status": "processing",
            "audio_path": str(audio_path),
            "error": None,
        },
    )

    try:
        analysis_result = run_full_analysis_from_metadata(
            attempt["utterance_id"],
            audio_path,
        )
        saved_attempt = save_analysis_result(attempt_id, analysis_result)
        return _attempt_result_payload(saved_attempt)
    except MetadataError as exc:
        failed_attempt = update_attempt(
            attempt_id,
            {
                "status": "failed",
                "error": str(exc),
            },
        )
        raise HTTPException(status_code=400, detail=failed_attempt["error"])
    except TranscriptionDependencyError as exc:
        failed_attempt = update_attempt(
            attempt_id,
            {
                "status": "failed",
                "error": str(exc),
            },
        )
        raise HTTPException(status_code=503, detail=failed_attempt["error"])
    except Exception as exc:
        failed_attempt = update_attempt(
            attempt_id,
            {
                "status": "failed",
                "error": "analysis failed: {0}".format(exc),
            },
        )
        raise HTTPException(status_code=500, detail=failed_attempt["error"])


@router.get("/{attempt_id}/status")
def get_attempt_status(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    return {
        "attempt_id": attempt["attempt_id"],
        "user_id": attempt["user_id"],
        "utterance_id": attempt["utterance_id"],
        "status": attempt["status"],
        "message": attempt.get("error") or attempt["status"],
        "created_at": attempt["created_at"],
        "updated_at": attempt["updated_at"],
        "error": attempt.get("error"),
    }


@router.get("/{attempt_id}/result")
def get_attempt_result(attempt_id: str) -> Dict[str, Any]:
    return _attempt_result_payload(_load_attempt_or_404(attempt_id))


@router.get("/{attempt_id}/phoneme")
def get_attempt_phoneme(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    _raise_if_not_ready(attempt)
    phoneme_analysis = _phoneme_payload(attempt_id)
    if not phoneme_analysis.get("phonemes") and get_phoneme_analysis(attempt_id) is None:
        raise HTTPException(status_code=404, detail="phoneme analysis not found")
    return phoneme_analysis


@router.get("/{attempt_id}/pitch")
def get_attempt_pitch(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    _raise_if_not_ready(attempt)
    pitch_analysis = _pitch_payload(attempt_id)
    if get_pitch_analysis(attempt_id) is None:
        raise HTTPException(status_code=404, detail="pitch analysis not found")
    return pitch_analysis


@router.get("/{attempt_id}/feedback")
def get_attempt_feedback(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    _raise_if_not_ready(attempt)
    return _feedback_payload(attempt)


@router.get("/{attempt_id}/analysis")
def get_attempt_analysis(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    _raise_if_not_ready(attempt)
    result = _attempt_result_payload(attempt)
    phoneme = _phoneme_payload(attempt_id)
    pitch = _pitch_payload(attempt_id)
    feedback = _feedback_payload(attempt)

    return {
        "attempt_id": result["attempt_id"],
        "sentence_id": result["utterance_id"],
        "target_text": result["practice_text"],
        "predicted_text": result["transcript"],
        "overall_score": result["overall_score"],
        "consonant_score": result["consonant_score"],
        "vowel_score": result["vowel_score"],
        "intonation_score": result["intonation_score"],
        "summary_title": feedback.get("feedback_type") or "분석 완료",
        "summary_message": feedback.get("feedback_message") or "",
        "error_ranges": phoneme.get("error_ranges", []),
        "pitch_analysis": {
            "reference_pitch_json": pitch.get("reference_contour", []),
            "learner_pitch_json": pitch.get("user_contour", []),
            "expected_pattern": pitch.get("expected_pattern", ""),
            "ending_pattern": pitch.get("ending_pattern", ""),
            "ending_pattern_match": pitch.get("ending_pattern_match", False),
            "dtw_distance": pitch.get("dtw_distance", 0),
            "speech_rate": pitch.get("speech_rate", 0),
            "rhythm_score": pitch.get("rhythm_score", 0),
            "prosody_score": pitch.get("prosody_score", pitch.get("score", 0)),
            "diagnosis_title": pitch.get("diagnosis_title", ""),
            "diagnosis_message": pitch.get("diagnosis_message", ""),
            "hint_json": pitch.get("practice_tips")
            or ([feedback["tip"]] if feedback.get("tip") else []),
        },
        "praise_feedback": feedback.get("praise") or "",
        "correction_feedback": feedback.get("improvement") or "",
        "practice_feedback": feedback.get("tip") or "",
        "result": result,
        "phoneme": phoneme,
        "pitch": pitch,
        "feedback": feedback,
    }
