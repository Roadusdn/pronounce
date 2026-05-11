import csv
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_METADATA_PATH = PROJECT_ROOT / "data" / "metadata" / "utterance_metadata_v1.csv"
CANONICAL_REFERENCE_AUDIO_DIR = PROJECT_ROOT / "data" / "audio" / "reference"

REQUIRED_FIELDS = (
    "utterance_id",
    "lesson_id",
    "lesson_name",
    "scene_id",
    "scene_name",
    "clip_filename",
    "clip_start_sec",
    "clip_end_sec",
    "pause_sec",
    "subtitle_text",
    "practice_text",
    "normalized_text",
    "target_phoneme_group",
    "target_prosody_type",
    "reference_audio_path",
    "difficulty",
    "memo",
)

TARGET_PHONEME_GROUP_ALIASES = {
    "ㅓ-ㅗ-ㅜ": "vowel_group",
    "ㅐ-ㅔ": "ae_e_group",
    "ㅅ-ㅆ": "siot_group",
    "ㄱ-ㄲ-ㅋ": "giyeok_group",
    "ㄷ-ㄸ-ㅌ": "digeut_group",
    "ㅂ-ㅃ-ㅍ": "bieup_group",
}


@dataclass(frozen=True)
class UtteranceMetadata:
    utterance_id: str
    practice_text: str
    normalized_text: str
    target_phoneme_group: str
    target_phoneme_group_raw: str
    target_prosody_type: str
    reference_audio_path: Optional[Path]
    reference_audio_path_raw: str
    lesson_id: str = ""
    lesson_name: str = ""
    scene_id: str = ""
    scene_name: str = ""
    clip_filename: str = ""
    clip_start_sec: float = 0.0
    clip_end_sec: float = 0.0
    pause_sec: float = 0.0
    subtitle_text: str = ""
    difficulty: str = ""
    memo: str = ""

    @property
    def lesson_title(self) -> str:
        return self.lesson_name

    @property
    def scene_title(self) -> str:
        return self.scene_name


class MetadataError(ValueError):
    pass


class UtteranceNotFoundError(MetadataError):
    pass


def _resolve_project_path(path_value: str) -> Optional[Path]:
    stripped_path = path_value.strip()
    if not stripped_path:
        return None

    path = Path(stripped_path)
    if path.is_absolute():
        return path

    return PROJECT_ROOT / path


def _normalize_reference_audio_path(path_value: str) -> str:
    stripped_path = path_value.strip()
    if not stripped_path:
        return ""

    path = Path(stripped_path)
    if path.is_absolute():
        return stripped_path

    path_parts = path.parts
    if len(path_parts) >= 2 and path_parts[0] == "data" and path_parts[1] == "reference":
        return str(Path("data") / "audio" / "reference" / Path(*path_parts[2:]))

    return stripped_path


def _parse_float(value: str) -> float:
    stripped_value = value.strip()
    if not stripped_value:
        return 0.0

    try:
        return float(stripped_value)
    except ValueError:
        return 0.0


def _validate_fieldnames(fieldnames: Optional[list[str]], metadata_path: Path) -> None:
    if fieldnames is None:
        raise MetadataError(
            "metadata file has no header row: {0}".format(metadata_path)
        )

    missing_fields = [
        field_name for field_name in REQUIRED_FIELDS if field_name not in fieldnames
    ]
    if missing_fields:
        raise MetadataError(
            "metadata file is missing required columns: {0}".format(
                ", ".join(missing_fields)
            )
        )


def _row_to_metadata(row: Dict[str, str]) -> UtteranceMetadata:
    reference_audio_path_raw = _normalize_reference_audio_path(
        row["reference_audio_path"]
    )
    target_phoneme_group_raw = row["target_phoneme_group"].strip()
    clip_start_sec = _parse_float(row.get("clip_start_sec", ""))
    clip_end_sec = _parse_float(row.get("clip_end_sec", ""))
    pause_sec = _parse_float(row.get("pause_sec", ""))

    return UtteranceMetadata(
        utterance_id=row["utterance_id"].strip(),
        practice_text=row["practice_text"].strip(),
        normalized_text=row["normalized_text"].strip(),
        target_phoneme_group=TARGET_PHONEME_GROUP_ALIASES.get(
            target_phoneme_group_raw,
            target_phoneme_group_raw,
        ),
        target_phoneme_group_raw=target_phoneme_group_raw,
        target_prosody_type=row["target_prosody_type"].strip(),
        reference_audio_path=_resolve_project_path(reference_audio_path_raw),
        reference_audio_path_raw=reference_audio_path_raw,
        lesson_id=row.get("lesson_id", "").strip(),
        lesson_name=row.get("lesson_name", "").strip(),
        scene_id=row.get("scene_id", "").strip(),
        scene_name=row.get("scene_name", "").strip(),
        clip_filename=row.get("clip_filename", "").strip(),
        clip_start_sec=clip_start_sec,
        clip_end_sec=clip_end_sec,
        pause_sec=pause_sec,
        subtitle_text=row.get("subtitle_text", "").strip(),
        difficulty=row.get("difficulty", "").strip(),
        memo=row.get("memo", "").strip(),
    )


def load_utterance_metadata(
    utterance_id: str,
    metadata_path: Path = DEFAULT_METADATA_PATH,
) -> UtteranceMetadata:
    if not metadata_path.exists():
        raise MetadataError(
            "metadata file does not exist: {0}".format(metadata_path)
        )

    normalized_utterance_id = utterance_id.strip()
    with metadata_path.open(newline="", encoding="utf-8-sig") as metadata_file:
        reader = csv.DictReader(metadata_file)
        _validate_fieldnames(reader.fieldnames, metadata_path)

        for row in reader:
            metadata = _row_to_metadata(row)
            if metadata.utterance_id == normalized_utterance_id:
                return metadata

    raise UtteranceNotFoundError(
        "utterance_id not found in metadata: {0}".format(normalized_utterance_id)
    )


def load_all_utterance_metadata(
    metadata_path: Path = DEFAULT_METADATA_PATH,
) -> list[UtteranceMetadata]:
    if not metadata_path.exists():
        raise MetadataError(
            "metadata file does not exist: {0}".format(metadata_path)
        )

    utterances = []
    with metadata_path.open(newline="", encoding="utf-8-sig") as metadata_file:
        reader = csv.DictReader(metadata_file)
        _validate_fieldnames(reader.fieldnames, metadata_path)
        for row in reader:
            utterances.append(_row_to_metadata(row))

    return utterances
