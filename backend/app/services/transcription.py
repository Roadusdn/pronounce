from functools import lru_cache
from pathlib import Path

import whisper


class TranscriptionDependencyError(RuntimeError):
    pass


@lru_cache
def get_model() -> whisper.Whisper:
    return whisper.load_model("tiny")


def transcribe_audio(audio_path: Path) -> str:
    try:
        result = get_model().transcribe(str(audio_path))
    except FileNotFoundError as exc:
        raise TranscriptionDependencyError(
            "ffmpeg is required for audio transcription but was not found"
        ) from exc

    return result["text"].strip()
