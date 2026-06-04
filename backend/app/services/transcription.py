from functools import lru_cache
from pathlib import Path
import re
from typing import Mapping, Optional, cast

import whisper


class TranscriptionDependencyError(RuntimeError):
    pass


KOREAN_TRANSCRIPTION_PROMPT = (
    "다음 음성은 한국어 학습자가 말한 한국어 녹음입니다. "
    "들리는 단어를 그대로 한글로 받아쓰기하세요. "
    "문법, 발음, 단어를 목표 문장처럼 고치지 마세요."
)
KOREAN_TEXT_PATTERN = re.compile(r"[^0-9A-Za-z가-힣ㄱ-ㅎㅏ-ㅣ\s.,!?~'\"()-]")


@lru_cache
def get_model() -> whisper.Whisper:
    return whisper.load_model("tiny")


def _clean_korean_transcript(text: str) -> str:
    cleaned = KOREAN_TEXT_PATTERN.sub("", text)
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned.strip()


def _prompt_for(expected_text: Optional[str] = None) -> str:
    return KOREAN_TRANSCRIPTION_PROMPT


def transcribe_audio(audio_path: Path, expected_text: Optional[str] = None) -> str:
    try:
        result = cast(
            Mapping[str, object],
            get_model().transcribe(
                str(audio_path),
                language="ko",
                task="transcribe",
                fp16=False,
                condition_on_previous_text=False,
                initial_prompt=_prompt_for(expected_text),
            ),
        )
    except FileNotFoundError as exc:
        raise TranscriptionDependencyError(
            "ffmpeg is required for audio transcription but was not found"
        ) from exc

    return _clean_korean_transcript(str(result.get("text", "")))
