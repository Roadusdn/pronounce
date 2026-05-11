from pathlib import Path

from fastapi import APIRouter, File, Form, UploadFile

from app.services.analysis_service import run_full_analysis_from_metadata
from app.services.feedback_generator import generate_feedback, get_top_mismatch
from app.services.korean_text import decompose_to_jamo, text_to_pronunciation
from app.services.pronunciation_compare import compare_pronunciation
from app.services.prosody_scoring import resolve_reference_audio, score_prosody
from app.services.transcription import transcribe_audio


router = APIRouter()
TEMP_DIR = Path("data/temp")


@router.post("/analyze")
async def analyze(
    expected_text: str = Form(...),
    audio_file: UploadFile = File(...),
    reference_audio_file: UploadFile = File(None),
) -> dict[str, object]:
    TEMP_DIR.mkdir(parents=True, exist_ok=True)

    uploaded_filename = Path(audio_file.filename or "uploaded_audio").name
    saved_path = TEMP_DIR / uploaded_filename
    saved_path.write_bytes(await audio_file.read())

    reference_saved_path = None
    if reference_audio_file is not None:
        reference_filename = Path(
            reference_audio_file.filename or "reference_audio"
        ).name
        reference_saved_path = TEMP_DIR / reference_filename
        reference_saved_path.write_bytes(await reference_audio_file.read())

    reference_audio_path, reference_reason = resolve_reference_audio(
        expected_text, reference_saved_path
    )

    transcript = transcribe_audio(saved_path)
    expected_pronunciation = text_to_pronunciation(expected_text)
    transcript_pronunciation = text_to_pronunciation(transcript)
    expected_jamo = decompose_to_jamo(expected_pronunciation)
    transcript_jamo = decompose_to_jamo(transcript_pronunciation)
    comparison_result = compare_pronunciation(expected_jamo, transcript_jamo)
    prosody_result = score_prosody(reference_audio_path, saved_path)
    if reference_reason and prosody_result["reason"] is None:
        prosody_result["reason"] = reference_reason
    feedback = generate_feedback(
        comparison_result["mismatched_items"],
        comparison_result["target_group_matches"],
        comparison_result["simple_score"],
    )
    top_mismatch = get_top_mismatch(comparison_result["mismatched_items"])

    return {
        "expected_text": expected_text,
        "uploaded_filename": uploaded_filename,
        "saved_path": str(saved_path),
        "transcript": transcript,
        "expected_pronunciation": expected_pronunciation,
        "transcript_pronunciation": transcript_pronunciation,
        "simple_score": comparison_result["simple_score"],
        "top_mismatch": top_mismatch,
        "feedback_type": feedback["feedback_type"],
        "feedback_message": feedback["feedback_message"],
        "comparison": {
            "expected_jamo": expected_jamo,
            "transcript_jamo": transcript_jamo,
            "mismatched_items": comparison_result["mismatched_items"],
            "target_group_matches": comparison_result["target_group_matches"],
            "simple_score": comparison_result["simple_score"],
        },
        "prosody_result": prosody_result,
        "message": "upload success",
    }


@router.post("/analyze/metadata")
async def analyze_from_metadata(
    utterance_id: str = Form(...),
    audio_file: UploadFile = File(...),
) -> dict[str, object]:
    TEMP_DIR.mkdir(parents=True, exist_ok=True)

    uploaded_filename = Path(audio_file.filename or "uploaded_audio").name
    saved_path = TEMP_DIR / uploaded_filename
    saved_path.write_bytes(await audio_file.read())

    return run_full_analysis_from_metadata(utterance_id, saved_path)
