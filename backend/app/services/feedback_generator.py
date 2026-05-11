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

GROUP_FEEDBACK_MESSAGES = {
    "giyeok_group": "ㄱ, ㄲ, ㅋ 차이를 더 분명하게 내보세요.",
    "digeut_group": "ㄷ, ㄸ, ㅌ 차이를 더 또렷하게 구분해보세요.",
    "bieup_group": "ㅂ, ㅃ, ㅍ은 입술 힘 차이를 더 살려보세요.",
    "siot_group": "ㅅ과 ㅆ은 세기 차이를 더 분명하게 내보세요.",
    "vowel_group": "ㅓ, ㅗ, ㅜ는 입모양 차이를 더 분명하게 해보세요.",
    "ae_e_group": "ㅐ와 ㅔ는 모음 차이를 더 또렷하게 내보세요.",
}


def _find_priority_mismatch(
    mismatched_items: Sequence[Mapping[str, object]],
) -> Optional[Mapping[str, object]]:
    for group_name in GROUP_PRIORITY:
        for item in mismatched_items:
            item_group_name = item.get("target_group")
            if item_group_name == group_name:
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


def _build_specific_feedback(
    mismatched_item: Mapping[str, object],
) -> Optional[dict[str, str]]:
    group_name = mismatched_item.get("target_group")
    expected_char = mismatched_item.get("expected")
    actual_char = mismatched_item.get("actual")

    if not isinstance(group_name, str):
        return None
    if not isinstance(expected_char, str) or not isinstance(actual_char, str):
        return None

    if group_name == "ae_e_group":
        message = "ㅐ와 ㅔ 모음 차이를 더 또렷하게 내보세요."
    elif group_name == "siot_group":
        message = "ㅅ과 ㅆ은 세기 차이를 더 분명하게 내보세요."
    elif group_name == "giyeok_group":
        message = "ㄱ, ㄲ, ㅋ은 힘과 거센소리 차이를 더 살려보세요."
    elif group_name == "digeut_group":
        message = "ㄷ, ㄸ, ㅌ은 혀 힘 차이를 더 또렷하게 구분해보세요."
    elif group_name == "bieup_group":
        message = "ㅂ, ㅃ, ㅍ은 입술 힘 차이를 더 살려보세요."
    elif group_name == "vowel_group":
        message = "ㅓ, ㅗ, ㅜ는 입모양 차이를 더 또렷하게 해보세요."
    else:
        return None

    feedback_type = "{0}_to_{1}".format(expected_char, actual_char)
    return {
        "feedback_type": feedback_type,
        "feedback_message": message,
    }


def _find_priority_group(
    target_group_matches: Mapping[str, Mapping[str, int]],
) -> Optional[str]:
    highest_group: Optional[str] = None
    highest_mismatch_count = 0

    for group_name in GROUP_PRIORITY:
        counts = target_group_matches.get(group_name, {})
        mismatch_count = counts.get("mismatches", 0)
        if mismatch_count > highest_mismatch_count:
            highest_group = group_name
            highest_mismatch_count = mismatch_count

    return highest_group


def generate_feedback(
    mismatched_items: Sequence[Mapping[str, object]],
    target_group_matches: Mapping[str, Mapping[str, int]],
    simple_score: float,
) -> dict[str, str]:
    if simple_score >= 90 and not mismatched_items:
        return {
            "feedback_type": "excellent",
            "feedback_message": "전반적으로 발음이 아주 정확해요.",
        }

    priority_mismatch = _find_priority_mismatch(mismatched_items)
    if priority_mismatch:
        specific_feedback = _build_specific_feedback(priority_mismatch)
        if specific_feedback:
            return specific_feedback

    priority_group = _find_priority_group(target_group_matches)
    if priority_group:
        return {
            "feedback_type": priority_group,
            "feedback_message": GROUP_FEEDBACK_MESSAGES[priority_group],
        }

    if simple_score >= 70:
        return {
            "feedback_type": "good",
            "feedback_message": "전체적으로 괜찮지만 몇몇 발음을 조금 더 또렷하게 해보세요.",
        }

    return {
        "feedback_type": "needs_practice",
        "feedback_message": "한 음절씩 천천히 또박또박 말해보며 다시 연습해보세요.",
    }
