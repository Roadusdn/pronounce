from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException

from app.services.metadata_loader import MetadataError, load_all_utterance_metadata


router = APIRouter(prefix="/api", tags=["catalog"])


@router.get("/lessons")
def get_lessons() -> List[Dict[str, Any]]:
    try:
        utterances = load_all_utterance_metadata()
    except MetadataError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    lessons_by_id: Dict[str, Dict[str, Any]] = {}
    for utterance in utterances:
        lesson_id = utterance.lesson_id or "default_lesson"
        scene_id = utterance.scene_id or "default_scene"
        lesson = lessons_by_id.setdefault(
            lesson_id,
            {
                "id": lesson_id,
                "lesson_id": lesson_id,
                "title": utterance.lesson_name or lesson_id,
                "lesson_name": utterance.lesson_name,
                "description": utterance.scene_name or utterance.lesson_name,
                "difficulty": utterance.difficulty,
                "scene_id": scene_id,
                "default_scene_id": scene_id,
                "utterance_count": 0,
                "scene_ids": [],
            },
        )
        lesson["utterance_count"] += 1
        if scene_id not in lesson["scene_ids"]:
            lesson["scene_ids"].append(scene_id)

    return list(lessons_by_id.values())


@router.get("/scenes/{scene_id}/utterances")
def get_scene_utterances(scene_id: str) -> List[Dict[str, Any]]:
    try:
        utterances = load_all_utterance_metadata()
    except MetadataError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    scene_utterances = []
    for utterance in utterances:
        utterance_scene_id = utterance.scene_id or "default_scene"
        if utterance_scene_id != scene_id:
            continue

        scene_utterances.append(
            {
                "id": utterance.utterance_id,
                "utterance_id": utterance.utterance_id,
                "lesson_id": utterance.lesson_id,
                "lesson_name": utterance.lesson_name,
                "scene_id": utterance_scene_id,
                "scene_name": utterance.scene_name,
                "clip_filename": utterance.clip_filename,
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
        )

    if not scene_utterances:
        raise HTTPException(
            status_code=404,
            detail="scene_id not found or has no utterances: {0}".format(scene_id),
        )

    return scene_utterances
