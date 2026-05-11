from pathlib import Path
from typing import Any, Dict, Optional

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel

from app.services.analysis_service import run_full_analysis_from_metadata
from app.services.attempt_store import (
    AttemptNotFoundError,
    create_attempt,
    get_attempt,
    get_attempt_audio_dir,
    get_phoneme_analysis,
    get_pitch_analysis,
    save_analysis_result,
    update_attempt,
)
from app.services.metadata_loader import MetadataError, load_utterance_metadata


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


@router.post("/start")
def start_attempt(payload: StartAttemptRequest) -> Dict[str, Any]:
    try:
        load_utterance_metadata(payload.utterance_id)
    except MetadataError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return create_attempt(payload.user_id, payload.utterance_id)


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
        return save_analysis_result(attempt_id, analysis_result)
    except MetadataError as exc:
        failed_attempt = update_attempt(
            attempt_id,
            {
                "status": "failed",
                "error": str(exc),
            },
        )
        raise HTTPException(status_code=400, detail=failed_attempt["error"])
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
    attempt = _load_attempt_or_404(attempt_id)
    return {
        "attempt_id": attempt["attempt_id"],
        "user_id": attempt["user_id"],
        "utterance_id": attempt["utterance_id"],
        "status": attempt["status"],
        "score": attempt.get("score"),
        "overall_score": attempt.get("overall_score") or attempt.get("score"),
        "pronunciation_score": attempt.get("pronunciation_score")
        or attempt.get("score"),
        "pitch_score": attempt.get("pitch_score") or 0,
        "transcript": attempt.get("transcript") or "",
        "feedback_type": attempt.get("feedback_type"),
        "feedback_message": attempt.get("feedback_message"),
        "clip_filename": attempt.get("clip_filename"),
        "clip_start_sec": attempt.get("clip_start_sec"),
        "clip_end_sec": attempt.get("clip_end_sec"),
        "pause_sec": attempt.get("pause_sec"),
        "subtitle_text": attempt.get("subtitle_text"),
        "practice_text": attempt.get("practice_text"),
        "normalized_text": attempt.get("normalized_text"),
        "difficulty": attempt.get("difficulty"),
        "lesson_id": attempt.get("lesson_id"),
        "lesson_name": attempt.get("lesson_name"),
        "scene_id": attempt.get("scene_id"),
        "scene_name": attempt.get("scene_name"),
        "target_phoneme_group": attempt.get("target_phoneme_group"),
        "target_phoneme_group_raw": attempt.get("target_phoneme_group_raw"),
        "target_prosody_type": attempt.get("target_prosody_type"),
        "error": attempt.get("error"),
    }


@router.get("/{attempt_id}/phoneme")
def get_attempt_phoneme(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    _raise_if_not_ready(attempt)
    phoneme_analysis = get_phoneme_analysis(attempt_id)
    if phoneme_analysis is None:
        raise HTTPException(status_code=404, detail="phoneme analysis not found")
    mismatches = phoneme_analysis.get("comparison", {}).get("target_mismatched_items")
    if mismatches is None:
        mismatches = phoneme_analysis.get("comparison", {}).get("mismatched_items", [])
    phoneme_analysis["phonemes"] = [
        {
            "symbol": item.get("expected") or item.get("actual") or "",
            "expected": item.get("expected") or "",
            "actual": item.get("actual") or "",
            "score": 0,
            "note": "expected {0}, heard {1}".format(
                item.get("expected") or "",
                item.get("actual") or "",
            ),
        }
        for item in mismatches
    ]
    return phoneme_analysis


@router.get("/{attempt_id}/pitch")
def get_attempt_pitch(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    _raise_if_not_ready(attempt)
    pitch_analysis = get_pitch_analysis(attempt_id)
    if pitch_analysis is None:
        raise HTTPException(status_code=404, detail="pitch analysis not found")
    prosody = pitch_analysis.get("prosody", {})
    pitch_analysis["score"] = prosody.get("pitch_similarity") or 0
    pitch_analysis["summary"] = prosody.get("reason") or "prosody scoring completed"
    return pitch_analysis


@router.get("/{attempt_id}/feedback")
def get_attempt_feedback(attempt_id: str) -> Dict[str, Any]:
    attempt = _load_attempt_or_404(attempt_id)
    _raise_if_not_ready(attempt)
    return {
        "attempt_id": attempt["attempt_id"],
        "feedback_type": attempt.get("feedback_type"),
        "feedback_message": attempt.get("feedback_message"),
        "praise": "분석이 완료됐어요.",
        "improvement": attempt.get("feedback_message"),
        "tip": "메타데이터의 기준 문장을 들은 뒤 같은 속도로 다시 말해보세요.",
        "top_mismatch": attempt.get("top_mismatch"),
        "score": attempt.get("score"),
    }
