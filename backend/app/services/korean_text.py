import re
import unicodedata
from functools import lru_cache

from g2pk2 import G2p
from jamo import h2j, j2hcj


def normalize_text(text: str) -> str:
    normalized = unicodedata.normalize("NFC", text).strip()
    return re.sub(r"\s+", " ", normalized)


@lru_cache
def get_g2p() -> G2p:
    return G2p()


def text_to_pronunciation(text: str) -> str:
    normalized = normalize_text(text)
    if not normalized:
        return ""
    return normalize_text(get_g2p()(normalized))


def decompose_to_jamo(text: str) -> str:
    normalized = normalize_text(text)
    if not normalized:
        return ""
    return j2hcj(h2j(normalized))
