from collections.abc import Mapping, Sequence
from typing import Optional


GROUP_PRIORITY = (
    "ae_e_group",
    "siot_group",
    "giyeok_group",
    "digeut_group",
    "bieup_group",
    "vowel_group",
)

TENSE_ASPIRATED_GROUPS = {"giyeok_group", "digeut_group", "bieup_group"}

GROUP_LABELS = {
    "giyeok_group": "ㄱ/ㄲ/ㅋ",
    "digeut_group": "ㄷ/ㄸ/ㅌ",
    "bieup_group": "ㅂ/ㅃ/ㅍ",
    "siot_group": "ㅅ/ㅆ",
    "vowel_group": "ㅓ/ㅗ/ㅜ",
    "ae_e_group": "ㅐ/ㅔ",
}

GROUP_FEEDBACK_MESSAGES = {
    "ae_e_group": "ㅐ와 ㅔ의 구별을 조금 더 연습해 보세요.",
    "siot_group": "ㅅ과 ㅆ의 세기 차이를 더 분명히 내면 좋습니다.",
    "giyeok_group": "평음·경음·격음의 세기 차이를 구별하는 연습이 필요합니다.",
    "digeut_group": "평음·경음·격음의 세기 차이를 구별하는 연습이 필요합니다.",
    "bieup_group": "평음·경음·격음의 세기 차이를 구별하는 연습이 필요합니다.",
    "vowel_group": "입 모양과 모음의 소리 차이를 더 정확히 구별해 보세요.",
}


def _score(value: object) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0


def _count(value: object) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def _find_priority_mismatch(
        mismatched_items: Sequence[Mapping[str, object]],
) -> Optional[Mapping[str, object]]:
    for group_name in GROUP_PRIORITY:
        for item in mismatched_items:
            if item.get("target_group") == group_name:
                return item

    for item in mismatched_items:
        group_name = item.get("target_group")
        if isinstance(group_name, str) and group_name in GROUP_FEEDBACK_MESSAGES:
            return item

    return None


def get_top_mismatch(
        mismatched_items: Sequence[Mapping[str, object]],
) -> Optional[dict[str, object]]:
    priority_mismatch = _find_priority_mismatch(mismatched_items)
    if priority_mismatch is None:
        return None

    return {
        "index": priority_mismatch.get("index"),
        "expected": priority_mismatch.get("expected"),
        "actual": priority_mismatch.get("actual"),
        "target_group": priority_mismatch.get("target_group"),
    }


def _find_priority_group(
        target_group_matches: Mapping[str, Mapping[str, int]],
) -> Optional[str]:
    highest_group: Optional[str] = None
    highest_mismatch_count = 0

    for group_name in GROUP_PRIORITY:
        counts = target_group_matches.get(group_name, {})
        mismatch_count = _count(counts.get("mismatches"))
        if mismatch_count > highest_mismatch_count:
            highest_group = group_name
            highest_mismatch_count = mismatch_count

    return highest_group


def _target_group_has_error(
        target_group_matches: Mapping[str, Mapping[str, int]],
        target_phoneme_group: Optional[str],
) -> bool:
    if not target_phoneme_group:
        return False

    counts = target_group_matches.get(target_phoneme_group, {})
    return _count(counts.get("mismatches")) > 0


def _summary_message(simple_score: float) -> tuple[str, str]:
    if simple_score >= 90:
        return "excellent", "전반적으로 발음이 자연스럽습니다."
    if simple_score >= 70:
        return "good", "전반적으로 괜찮습니다."
    return "needs_practice", "전체 발음에서 기준 문장과 다른 부분이 여러 번 나타났습니다."


def _pronunciation_message(
        *,
        target_group_matches: Mapping[str, Mapping[str, int]],
        target_phoneme_group: Optional[str],
        pronunciation_stats: Mapping[str, object],
) -> tuple[str, str]:
    priority_group = None
    if _target_group_has_error(target_group_matches, target_phoneme_group):
        priority_group = target_phoneme_group
    if priority_group is None:
        priority_group = _find_priority_group(target_group_matches)

    if priority_group in GROUP_FEEDBACK_MESSAGES:
        label = GROUP_LABELS.get(priority_group, "목표 발음군")
        if target_phoneme_group == priority_group:
            return (
                priority_group,
                f"이 문장의 목표 발음군인 {label}에서 오류가 나타났습니다. "
                f"{GROUP_FEEDBACK_MESSAGES[priority_group]}",
            )
        return priority_group, GROUP_FEEDBACK_MESSAGES[priority_group]

    consonant_score = _score(pronunciation_stats.get("consonant_score"))
    vowel_score = _score(pronunciation_stats.get("vowel_score"))
    consonant_errors = _count(pronunciation_stats.get("consonant_mismatch_count"))
    vowel_errors = _count(pronunciation_stats.get("vowel_mismatch_count"))

    if vowel_errors > consonant_errors and vowel_score < 85:
        return (
            "vowel_focus",
            "모음 오류가 상대적으로 많습니다. 입 모양과 모음의 소리 차이를 더 정확히 구별해 보세요.",
        )
    if consonant_errors > 0 and consonant_score < 85:
        return (
            "consonant_focus",
            "자음 오류가 상대적으로 많습니다. 조음 위치와 발음 세기를 더 분명히 해보세요.",
        )

    return (
        "minor_clarity",
        "목표 발음군은 크게 틀리지 않았습니다.",
    )


def _target_prosody_message(target_prosody_type: Optional[str]) -> Optional[str]:
    if target_prosody_type == "sentence_final_fall":
        return "이 문장은 끝을 내리는 억양이 더 자연스럽습니다."
    if target_prosody_type == "sentence_final_rise":
        return "이 문장은 끝을 올리는 억양이 더 자연스럽습니다."
    return None


def _prosody_message(
        prosody_result: Optional[Mapping[str, object]],
        target_prosody_type: Optional[str],
) -> Optional[str]:
    if not prosody_result:
        return None
    if prosody_result.get("reason"):
        return None

    pitch_similarity = prosody_result.get("pitch_similarity")
    pitch_score = _score(
        pitch_similarity
        if pitch_similarity is not None
        else prosody_result.get("prosody_score")
    )
    rhythm_score = _score(prosody_result.get("rhythm_score"))
    ending_match = bool(prosody_result.get("ending_pattern_match"))
    expected_pattern = prosody_result.get("expected_pattern")
    ending_pattern = prosody_result.get("ending_pattern")
    reference_rate = _score(prosody_result.get("reference_speech_rate"))
    learner_rate = _score(prosody_result.get("learner_speech_rate"))

    if pitch_score and pitch_score < 70:
        return "전체적인 말투 흐름이 기준 음성과 다르므로 높낮이 변화를 더 자연스럽게 따라 해보세요."

    if not ending_match and expected_pattern not in (None, "", "unknown"):
        if expected_pattern == "falling":
            return "문장 끝이 기준보다 덜 내려가므로, 마지막 어절을 조금 더 낮추어 말해 보세요."
        if expected_pattern == "rising":
            return "문장 끝이 기준보다 덜 올라가므로, 마지막 어절을 조금 더 올려 말해 보세요."
        if ending_pattern not in (None, "", "unknown"):
            return "문장 끝 억양이 기준과 다릅니다. 마지막 어절의 높낮이를 기준 음성에 맞춰 보세요."

    target_message = _target_prosody_message(target_prosody_type)
    if target_message and not ending_match:
        return target_message

    if reference_rate and learner_rate:
        rate_gap = abs(reference_rate - learner_rate) / reference_rate
        if rate_gap >= 0.25:
            return "말 속도를 조금 조절하면 더 자연스럽게 들립니다."

    if rhythm_score and rhythm_score < 75:
        return "호흡과 리듬을 일정하게 유지해 보세요."

    return None


def _practice_direction(feedback_type: str, has_prosody_feedback: bool) -> str:
    if feedback_type in TENSE_ASPIRATED_GROUPS:
        return "다음 연습에서는 같은 위치의 평음·경음·격음을 짧게 반복한 뒤 문장 전체를 다시 말해 보세요."
    if feedback_type in {"ae_e_group", "vowel_group", "vowel_focus"}:
        return "다음 연습에서는 입 모양을 먼저 고정하고 짧은 단어 단위로 모음 차이를 확인해 보세요."
    if feedback_type in {"siot_group", "consonant_focus"}:
        return "다음 연습에서는 자음의 세기와 공기 흐름을 천천히 분리해서 말해 보세요."
    if has_prosody_feedback:
        return "다음 연습에서는 기준 음성을 한 번 듣고 같은 속도와 끝 억양으로 따라 해보세요."
    return "다음 연습에서는 현재 흐름을 유지해 보세요."


def generate_feedback(
        mismatched_items: Sequence[Mapping[str, object]],
        target_group_matches: Mapping[str, Mapping[str, int]],
        simple_score: float,
        pronunciation_stats: Optional[Mapping[str, object]] = None,
        prosody_result: Optional[Mapping[str, object]] = None,
        target_phoneme_group: Optional[str] = None,
        target_prosody_type: Optional[str] = None,
) -> dict[str, object]:
    stats = pronunciation_stats or {}
    summary_type, summary = _summary_message(simple_score)

    if simple_score >= 90 and not mismatched_items:
        pronunciation_type = "excellent"
        pronunciation = "목표 발음군에서도 눈에 띄는 오류가 거의 없습니다."
    else:
        pronunciation_type, pronunciation = _pronunciation_message(
            target_group_matches=target_group_matches,
            target_phoneme_group=target_phoneme_group,
            pronunciation_stats=stats,
        )

    prosody = _prosody_message(prosody_result, target_prosody_type)
    practice = _practice_direction(pronunciation_type, prosody is not None)

    message_parts = [summary, pronunciation]
    if prosody:
        message_parts.append(prosody)
    message_parts.append(practice)

    return {
        "feedback_type": pronunciation_type if pronunciation_type != "excellent" else summary_type,
        "feedback_message": " ".join(message_parts),
        "summary_feedback": summary,
        "pronunciation_feedback": pronunciation,
        "prosody_feedback": prosody or "",
        "practice_direction": practice,
    }
