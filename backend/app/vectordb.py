from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance

client = QdrantClient(url="http://localhost:6333")


def init_collections():
    """Create the collections (recreated from scratch on each call)."""
    for name, size in (("texts", 1024), ("images", 512)):
        if client.collection_exists(name):
            client.delete_collection(name)
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


def rrf(result_lists: list[list], k: int = 60, top_n: int = 5):
    """Reciprocal Rank Fusion over several ranked result lists."""
    scores, payloads = {}, {}
    for results in result_lists:
        for rank, hit in enumerate(results, start=1):
            key = f"{hit.payload.get('type')}:{hit.id}"
            scores[key] = scores.get(key, 0) + 1 / (k + rank)
            payloads[key] = hit.payload
    ranked = sorted(scores, key=scores.get, reverse=True)[:top_n]
    return [payloads[key] for key in ranked]