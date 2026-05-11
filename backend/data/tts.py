"""
Local development utility for generating temporary reference audio.

This is not production TTS logic. It reads the metadata CSV, uses practice_text
for each utterance, saves MP3 files, and converts them to WAV files for local
pronunciation-analysis testing.
"""

import argparse
import asyncio
import csv
import subprocess
from pathlib import Path
from typing import Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_METADATA_PATH = PROJECT_ROOT / "data" / "metadata" / "utterance_metadata_v1.csv"
DEFAULT_MP3_DIR = PROJECT_ROOT / "data" / "audio" / "reference_mp3"
DEFAULT_WAV_DIR = PROJECT_ROOT / "data" / "audio" / "reference"
DEFAULT_VOICE = "ko-KR-SunHiNeural"
TARGET_SAMPLE_RATE = "16000"


def _read_metadata_rows(metadata_path: Path) -> Iterable[dict[str, str]]:
    with metadata_path.open(newline="", encoding="utf-8-sig") as metadata_file:
        reader = csv.DictReader(metadata_file)
        required_fields = {"utterance_id", "practice_text"}
        fieldnames = set(reader.fieldnames or [])
        missing_fields = sorted(required_fields - fieldnames)
        if missing_fields:
            raise ValueError(
                "metadata CSV is missing required columns: {0}".format(
                    ", ".join(missing_fields)
                )
            )

        for row in reader:
            utterance_id = row["utterance_id"].strip()
            practice_text = row["practice_text"].strip()
            if not utterance_id or not practice_text:
                continue
            yield {
                "utterance_id": utterance_id,
                "practice_text": practice_text,
            }


async def _save_tts_mp3(text: str, mp3_path: Path, voice: str) -> None:
    try:
        import edge_tts
    except ImportError as exc:
        raise RuntimeError(
            "edge-tts is required for local reference generation. "
            "Install it in your local dev environment with: pip install edge-tts"
        ) from exc

    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(str(mp3_path))


def _convert_mp3_to_wav(mp3_path: Path, wav_path: Path) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(mp3_path),
            "-ar",
            TARGET_SAMPLE_RATE,
            "-ac",
            "1",
            str(wav_path),
        ],
        check=True,
    )


async def generate_reference_audio(
    metadata_path: Path = DEFAULT_METADATA_PATH,
    mp3_dir: Path = DEFAULT_MP3_DIR,
    wav_dir: Path = DEFAULT_WAV_DIR,
    voice: str = DEFAULT_VOICE,
) -> None:
    mp3_dir.mkdir(parents=True, exist_ok=True)
    wav_dir.mkdir(parents=True, exist_ok=True)

    for row in _read_metadata_rows(metadata_path):
        utterance_id = row["utterance_id"]
        practice_text = row["practice_text"]

        mp3_path = mp3_dir / "{0}_reference.mp3".format(utterance_id)
        wav_path = wav_dir / "{0}_reference.wav".format(utterance_id)

        print("Generating local reference audio: {0}".format(utterance_id))
        await _save_tts_mp3(practice_text, mp3_path, voice)
        _convert_mp3_to_wav(mp3_path, wav_path)

    print("Done generating local reference audio.")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate temporary local reference audio from metadata CSV."
    )
    parser.add_argument(
        "--metadata",
        type=Path,
        default=DEFAULT_METADATA_PATH,
        help="Path to utterance metadata CSV.",
    )
    parser.add_argument(
        "--mp3-dir",
        type=Path,
        default=DEFAULT_MP3_DIR,
        help="Output directory for generated MP3 files.",
    )
    parser.add_argument(
        "--wav-dir",
        type=Path,
        default=DEFAULT_WAV_DIR,
        help="Output directory for converted WAV files.",
    )
    parser.add_argument(
        "--voice",
        default=DEFAULT_VOICE,
        help="edge-tts voice name.",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    asyncio.run(
        generate_reference_audio(
            metadata_path=args.metadata,
            mp3_dir=args.mp3_dir,
            wav_dir=args.wav_dir,
            voice=args.voice,
        )
    )


if __name__ == "__main__":
    main()
