import uuid


def chunk_text(text: str, size: int = 800, overlap: int = 100) -> list[str]:
    return [text[i:i + size] for i in range(0, len(text), size - overlap)]


def usable_chunks(text: str, size: int = 800, overlap: int = 100):
    """Yield (index, chunk) for non-empty chunks; index stays stable when blanks are skipped."""
    for idx, chunk in enumerate(chunk_text(text, size, overlap)):
        if chunk.strip():
            yield idx, chunk


def point_id(*parts) -> str:
    """Stable point id, so re-ingesting the same source overwrites instead of duplicating."""
    return str(uuid.uuid5(uuid.NAMESPACE_URL, ":".join(str(p) for p in parts)))
