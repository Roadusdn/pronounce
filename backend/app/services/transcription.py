from functools import lru_cache
from pathlib import Path
import re

import whisper


class TranscriptionDependencyError(RuntimeError):
    pass


KOREAN_TRANSCRIPTION_PROMPT = (
    "다음 음성은 한국어 학습자가 한국어 문장을 읽는 녹음입니다. "
    "반드시 한국어 한글 문장으로 받아쓰기하세요."
)
KOREAN_TEXT_PATTERN = re.compile(r"[^0-9A-Za-z가-힣ㄱ-ㅎㅏ-ㅣ\s.,!?~'\"()-]")


@lru_cache
def get_model() -> whisper.Whisper:
    return whisper.load_model("tiny")


def _clean_korean_transcript(text: str) -> str:
    cleaned = KOREAN_TEXT_PATTERN.sub("", text)
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned.strip()


def _prompt_for(expected_text: str | None = None) -> str:
    if expected_text is None or not expected_text.strip():
        return KOREAN_TRANSCRIPTION_PROMPT

    return (
        f"{KOREAN_TRANSCRIPTION_PROMPT} "
        f"학습자가 읽는 목표 문장은 '{expected_text.strip()}'입니다."
    )


def transcribe_audio(audio_path: Path, expected_text: str | None = None) -> str:
    try:
        result = get_model().transcribe(
            str(audio_path),
            language="ko",
            task="transcribe",
            fp16=False,
            condition_on_previous_text=False,
            initial_prompt=_prompt_for(expected_text),
        )
    except FileNotFoundError as exc:
        raise TranscriptionDependencyError(
            "ffmpeg is required for audio transcription but was not found"
        ) from exc

    return _clean_korean_transcript(result["text"])
