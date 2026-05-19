from pathlib import Path
import re
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException

from app.services.metadata_loader import MetadataError, load_all_utterance_metadata


router = APIRouter(prefix="/api", tags=["catalog"])
BACKEND_ROOT = Path(__file__).resolve().parents[2]
CLIPS_DIR = BACKEND_ROOT / "data" / "clips"


def _format_duration(seconds: float) -> str:
    safe_seconds = max(0, int(round(seconds)))
    minutes = safe_seconds // 60
    remaining_seconds = safe_seconds % 60
    return "{0:02d}:{1:02d}".format(minutes, remaining_seconds)


def _is_placeholder_lesson_name(value: str) -> bool:
    return re.fullmatch(r"레슨\s*\d+", value.strip()) is not None


def _lesson_display_title(lesson_name: str, scene_name: str, lesson_id: str) -> str:
    if lesson_name and not _is_placeholder_lesson_name(lesson_name):
        return lesson_name
    return scene_name or lesson_name or lesson_id


def _lesson_description(lesson: Dict[str, Any]) -> str:
    scene_names = lesson.get("scene_names") or []
    if scene_names:
        return ", ".join(scene_names)
    return lesson.get("lesson_name") or lesson.get("title") or ""


def _clip_url(clip_filename: str) -> Optional[str]:
    if not clip_filename:
        return None
    if not (CLIPS_DIR / clip_filename).is_file():
        return None
    return "/api/clips/{0}".format(clip_filename)


def _utterance_duration(utterance: Any) -> float:
    if utterance.clip_end_sec <= utterance.clip_start_sec:
        return 0.0
    return utterance.clip_end_sec - utterance.clip_start_sec


def _scene_payload(scene_id: str, scene_utterances: List[Any]) -> Dict[str, Any]:
    first = scene_utterances[0]
    duration_sec = sum(_utterance_duration(utterance) for utterance in scene_utterances)
    pronunciation_focus = (
        first.target_phoneme_group_raw
        or first.target_phoneme_group
        or first.target_prosody_type
        or "pronunciation practice"
    )

    return {
        "id": scene_id,
        "scene_id": scene_id,
        "title": first.scene_name or scene_id,
        "scene_name": first.scene_name,
        "lesson_id": first.lesson_id,
        "lesson_name": first.lesson_name,
        "difficulty": first.difficulty,
        "pronunciation_focus": pronunciation_focus,
        "utterance_count": len(scene_utterances),
        "sentence_count": len(scene_utterances),
        "duration_sec": duration_sec,
        "duration": _format_duration(duration_sec),
        "completed": False,
    }


def _utterance_payload(utterance: Any) -> Dict[str, Any]:
    clip_url = _clip_url(utterance.clip_filename)
    return {
        "id": utterance.utterance_id,
        "utterance_id": utterance.utterance_id,
        "lesson_id": utterance.lesson_id,
        "lesson_name": utterance.lesson_name,
        "scene_id": utterance.scene_id or "default_scene",
        "scene_name": utterance.scene_name,
        "clip_filename": utterance.clip_filename,
        "clip_url": clip_url,
        "video_url": clip_url,
        "clip_start_sec": utterance.clip_start_sec,
        "clip_end_sec": utterance.clip_end_sec,
        "pause_sec": utterance.pause_sec,
        "subtitle_text": utterance.subtitle_text,
        "practice_text": utterance.practice_text,
        "normalized_text": utterance.normalized_text,
        "difficulty": utterance.difficulty,
        "target_phoneme_group": utterance.target_phoneme_group,
        "target_phoneme_group_raw": utterance.target_phoneme_group_raw,
        "target_prosody_type": utterance.target_prosody_type,
    }


def _load_metadata_or_500() -> List[Any]:
    try:
        return load_all_utterance_metadata()
    except MetadataError as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@router.get("/lessons")
def get_lessons() -> List[Dict[str, Any]]:
    utterances = _load_metadata_or_500()

    lessons_by_id: Dict[str, Dict[str, Any]] = {}
    for utterance in utterances:
        lesson_id = utterance.lesson_id or "default_lesson"
        scene_id = utterance.scene_id or "default_scene"
        lesson = lessons_by_id.setdefault(
            lesson_id,
            {
                "id": lesson_id,
                "lesson_id": lesson_id,
                "title": _lesson_display_title(
                    utterance.lesson_name,
                    utterance.scene_name,
                    lesson_id,
                ),
                "lesson_name": utterance.lesson_name,
                "description": "",
                "difficulty": utterance.difficulty,
                "scene_id": scene_id,
                "default_scene_id": scene_id,
                "utterance_count": 0,
                "scene_count": 0,
                "scene_ids": [],
                "scene_names": [],
            },
        )
        lesson["utterance_count"] += 1
        if scene_id not in lesson["scene_ids"]:
            lesson["scene_ids"].append(scene_id)
            lesson["scene_count"] = len(lesson["scene_ids"])
        if utterance.scene_name and utterance.scene_name not in lesson["scene_names"]:
            lesson["scene_names"].append(utterance.scene_name)

    lessons = list(lessons_by_id.values())
    for lesson in lessons:
        lesson["description"] = _lesson_description(lesson)
    return lessons


@router.get("/lessons/{lesson_id}")
def get_lesson(lesson_id: str) -> Dict[str, Any]:
    for lesson in get_lessons():
        if lesson["id"] == lesson_id:
            return lesson
    raise HTTPException(status_code=404, detail=f"Lesson {lesson_id} not found")


@router.get("/lessons/{lesson_id}/scenes")
def get_lesson_scenes(lesson_id: str) -> List[Dict[str, Any]]:
    utterances = _load_metadata_or_500()
    scenes_by_id: Dict[str, List[Any]] = {}

    for utterance in utterances:
        if (utterance.lesson_id or "default_lesson") != lesson_id:
            continue
        scene_id = utterance.scene_id or "default_scene"
        scenes_by_id.setdefault(scene_id, []).append(utterance)

    if not scenes_by_id:
        raise HTTPException(status_code=404, detail=f"Lesson {lesson_id} not found")

    return [
        _scene_payload(scene_id, scene_utterances)
        for scene_id, scene_utterances in scenes_by_id.items()
    ]


@router.get("/scenes/{scene_id}")
def get_scene(scene_id: str) -> Dict[str, Any]:
    utterances = _load_metadata_or_500()
    scene_utterances = [
        utterance
        for utterance in utterances
        if (utterance.scene_id or "default_scene") == scene_id
    ]

    if not scene_utterances:
        raise HTTPException(status_code=404, detail=f"Scene {scene_id} not found")

    return _scene_payload(scene_id, scene_utterances)


@router.get("/scenes/{scene_id}/utterances")
def get_scene_utterances(scene_id: str) -> List[Dict[str, Any]]:
    utterances = _load_metadata_or_500()
    scene_utterances = [
        _utterance_payload(utterance)
        for utterance in utterances
        if (utterance.scene_id or "default_scene") == scene_id
    ]

    if not scene_utterances:
        raise HTTPException(
            status_code=404,
            detail="scene_id not found or has no utterances: {0}".format(scene_id),
        )

    return scene_utterances
