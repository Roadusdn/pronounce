from functools import lru_cache
from pathlib import Path

import whisper


@lru_cache
def get_model() -> whisper.Whisper:
    return whisper.load_model("tiny")


def transcribe_audio(audio_path: Path) -> str:
    result = get_model().transcribe(str(audio_path))
    return result["text"].strip()
