TARGET_GROUPS = {
    "giyeok_group": {"ㄱ", "ㄲ", "ㅋ"},
    "digeut_group": {"ㄷ", "ㄸ", "ㅌ"},
    "bieup_group": {"ㅂ", "ㅃ", "ㅍ"},
    "siot_group": {"ㅅ", "ㅆ"},
    "vowel_group": {"ㅓ", "ㅗ", "ㅜ"},
    "ae_e_group": {"ㅐ", "ㅔ"},
}


import unicodedata
from typing import Optional


JAMO_TO_COMPATIBILITY_JAMO = {
    "ᄀ": "ㄱ",
    "ᄁ": "ㄲ",
    "ᄃ": "ㄷ",
    "ᄄ": "ㄸ",
    "ᄇ": "ㅂ",
    "ᄈ": "ㅃ",
    "ᄉ": "ㅅ",
    "ᄊ": "ㅆ",
    "ᄏ": "ㅋ",
    "ᄐ": "ㅌ",
    "ᄑ": "ㅍ",
    "ᅥ": "ㅓ",
    "ᅩ": "ㅗ",
    "ᅮ": "ㅜ",
    "ᅢ": "ㅐ",
    "ᅦ": "ㅔ",
    "ᆨ": "ㄱ",
    "ᆮ": "ㄷ",
    "ᆸ": "ㅂ",
    "ᆺ": "ㅅ",
    "ᆻ": "ㅆ",
    "ᆿ": "ㅋ",
    "ᇀ": "ㅌ",
    "ᇁ": "ㅍ",
}


def _normalize_jamo_sequence(value: str) -> str:
    normalized = unicodedata.normalize("NFD", value)
    normalized_chars = []

    for char in normalized:
        if char.isspace():
            continue
        if unicodedata.category(char).startswith("P"):
            continue
        normalized_chars.append(JAMO_TO_COMPATIBILITY_JAMO.get(char, char))

    return "".join(normalized_chars)


def _find_group(char: str) -> Optional[str]:
    for group_name, chars in TARGET_GROUPS.items():
        if char in chars:
            return group_name
    return None


def compare_pronunciation(expected_jamo: str, transcript_jamo: str) -> dict[str, object]:
    expected_jamo = _normalize_jamo_sequence(expected_jamo)
    transcript_jamo = _normalize_jamo_sequence(transcript_jamo)

    mismatched_items: list[dict[str, object]] = []
    target_group_matches = {
        group_name: {"matches": 0, "mismatches": 0}
        for group_name in TARGET_GROUPS
    }

    max_length = max(len(expected_jamo), len(transcript_jamo))
    compared_count = 0
    matched_count = 0

    for index in range(max_length):
        expected_char = expected_jamo[index] if index < len(expected_jamo) else ""
        transcript_char = transcript_jamo[index] if index < len(transcript_jamo) else ""

        if not expected_char and not transcript_char:
            continue

        compared_count += 1
        if expected_char == transcript_char:
            matched_count += 1

        group_name = _find_group(expected_char) or _find_group(transcript_char)
        if group_name:
            if expected_char == transcript_char:
                target_group_matches[group_name]["matches"] += 1
            else:
                target_group_matches[group_name]["mismatches"] += 1

        if expected_char != transcript_char:
            mismatched_items.append(
                {
                    "index": index,
                    "expected": expected_char,
                    "actual": transcript_char,
                    "target_group": group_name,
                }
            )

    simple_score = 0
    if compared_count:
        simple_score = round((matched_count / compared_count) * 100, 2)

    return {
        "mismatched_items": mismatched_items,
        "target_group_matches": target_group_matches,
        "simple_score": simple_score,
    }
