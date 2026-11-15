from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance
from .config import QDRANT_URL

client = QdrantClient(url=QDRANT_URL)


def init_collections():
    """Create missing collections; existing data is kept.

    Points written before this change used random ids, so drop the collections
    once after upgrading to clear those duplicates.
    """
    for name, size in (("texts", 1024), ("images", 512)):
        if not client.collection_exists(name):
            client.create_collection(
                collection_name=name,
                vectors_config=VectorParams(size=size, distance=Distance.COSINE),
            )


def search(collection: str, vector, limit: int = 5):
    """Return the top `limit` points (each has .id, .score, .payload)."""
    if hasattr(vector, "tolist"):
        vector = vector.tolist()
    response = client.query_points(
        collection_name=collection,
        query=vector,
        limit=limit,
        with_payload=True,
    )
    return response.points
