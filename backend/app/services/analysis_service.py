from pathlib import Path
from typing import Mapping, Optional, Sequence, Union

from app.services.feedback_generator import generate_feedback, get_top_mismatch
from app.services.korean_text import decompose_to_jamo, text_to_pronunciation
from app.services.metadata_loader import UtteranceMetadata, load_utterance_metadata
from app.services.pronunciation_compare import compare_pronunciation
from app.services.prosody_scoring import score_prosody
from app.services.transcription import transcribe_audio


def _resolve_reference_audio(
    metadata: UtteranceMetadata,
) -> tuple[Optional[Path], Optional[str]]:
    reference_audio_path = metadata.reference_audio_path
    if reference_audio_path is None:
        return None, "reference_audio_path is empty in metadata"

    if not reference_audio_path.exists():
        return (
            None,
            "reference audio from metadata is missing: {0}".format(
                metadata.reference_audio_path_raw
            ),
        )

    return reference_audio_path, None


def _target_group_matches(
    target_group_matches: Mapping[str, Mapping[str, int]],
    target_phoneme_group: str,
) -> dict[str, Mapping[str, int]]:
    if target_phoneme_group in target_group_matches:
        return {
            target_phoneme_group: target_group_matches[target_phoneme_group],
        }

    return dict(target_group_matches)


def _target_mismatches(
    mismatched_items: Sequence[Mapping[str, object]],
    target_phoneme_group: str,
) -> list[Mapping[str, object]]:
    filtered_items = [
        item
        for item in mismatched_items
        if item.get("target_group") == target_phoneme_group
    ]
    if filtered_items:
        return filtered_items

    return list(mismatched_items)


def run_full_analysis_from_metadata(
    utterance_id: str,
    audio_path: Union[str, Path],
) -> dict[str, object]:
    metadata = load_utterance_metadata(utterance_id)
    uploaded_audio_path = Path(audio_path)

    reference_audio_path, reference_reason = _resolve_reference_audio(metadata)

    transcript = transcribe_audio(uploaded_audio_path)
    expected_text = metadata.normalized_text or metadata.practice_text
    expected_pronunciation = text_to_pronunciation(expected_text)
    transcript_pronunciation = text_to_pronunciation(transcript)
    expected_jamo = decompose_to_jamo(expected_pronunciation)
    transcript_jamo = decompose_to_jamo(transcript_pronunciation)
    comparison_result = compare_pronunciation(expected_jamo, transcript_jamo)

    target_group_matches = _target_group_matches(
        comparison_result["target_group_matches"],
        metadata.target_phoneme_group,
    )
    target_mismatched_items = _target_mismatches(
        comparison_result["mismatched_items"],
        metadata.target_phoneme_group,
    )

    prosody_result = score_prosody(reference_audio_path, uploaded_audio_path)
    if reference_reason:
        prosody_result["reason"] = reference_reason
    prosody_result["target_prosody_type"] = metadata.target_prosody_type

    feedback = generate_feedback(
        target_mismatched_items,
        target_group_matches,
        comparison_result["simple_score"],
    )
    top_mismatch = get_top_mismatch(target_mismatched_items)

    result = {
        "utterance": {
            "utterance_id": metadata.utterance_id,
            "lesson_id": metadata.lesson_id,
            "lesson_name": metadata.lesson_name,
            "scene_id": metadata.scene_id,
            "scene_name": metadata.scene_name,
            "clip_filename": metadata.clip_filename,
            "clip_start_sec": metadata.clip_start_sec,
            "clip_end_sec": metadata.clip_end_sec,
            "pause_sec": metadata.pause_sec,
            "subtitle_text": metadata.subtitle_text,
            "difficulty": metadata.difficulty,
            "memo": metadata.memo,
            "practice_text": metadata.practice_text,
            "normalized_text": metadata.normalized_text,
            "target_phoneme_group": metadata.target_phoneme_group,
            "target_phoneme_group_raw": metadata.target_phoneme_group_raw,
            "target_prosody_type": metadata.target_prosody_type,
            "reference_audio_path": metadata.reference_audio_path_raw,
            "reference_audio_available": reference_audio_path is not None,
        },
        "audio": {
            "uploaded_audio_path": str(uploaded_audio_path),
        },
        "transcription": {
            "text": transcript,
        },
        "pronunciation": {
            "expected_text": expected_text,
            "expected_pronunciation": expected_pronunciation,
            "transcript_pronunciation": transcript_pronunciation,
            "expected_jamo": expected_jamo,
            "transcript_jamo": transcript_jamo,
        },
        "comparison": {
            "simple_score": comparison_result["simple_score"],
            "mismatched_items": comparison_result["mismatched_items"],
            "target_group_matches": comparison_result["target_group_matches"],
            "target_phoneme_group": metadata.target_phoneme_group,
            "target_group_result": target_group_matches,
            "target_mismatched_items": target_mismatched_items,
        },
        "prosody": prosody_result,
        "feedback": {
            "type": feedback["feedback_type"],
            "message": feedback["feedback_message"],
            "top_mismatch": top_mismatch,
        },
    }
    result.update(
        {
            "transcript": transcript,
            "simple_score": comparison_result["simple_score"],
            "prosody_result": prosody_result,
            "feedback_message": feedback["feedback_message"],
        }
    )
    return result
