import glob, os
from pypdf import PdfReader
from qdrant_client.models import PointStruct
from .chunking import point_id, usable_chunks
from .embeddings import embed_image, embed_text
from .config import DATA_DIR, IMAGES_DIR
from .vectordb import client, init_collections

def ingest_pdf(path: str):
    reader = PdfReader(path)
    source = os.path.basename(path)
    items = [(chunk, page_no, idx)
             for page_no, page in enumerate(reader.pages, start=1)
             for idx, chunk in usable_chunks(page.extract_text() or "")]
    if not items:
        print(f"warning: no text extracted from {source} (scanned PDF?) - nothing indexed")
        return 0
    # One encode call batches internally; per-chunk calls were the slow path.
    vectors = embed_text([chunk for chunk, _, _ in items])
    client.upsert("texts", [
        PointStruct(id=point_id(source, page, idx), vector=v.tolist(),
                    payload={"type": "text", "content": chunk,
                             "source": source, "page": page})
        for v, (chunk, page, idx) in zip(vectors, items)])
    return len(items)

def ingest_image_files(paths: list[str]):
    """Index specific image files (uploads); `ingest_images` does a whole folder."""
    if not paths:
        return
    vecs = embed_image(paths)
    client.upsert("images", [
        PointStruct(id=point_id("image", os.path.basename(p)), vector=v.tolist(),
                    payload={"type": "image", "path": p})
        for p, v in zip(paths, vecs)])

def ingest_images(folder: str):
    ingest_image_files(glob.glob(f"{folder}/*.[jp][pn]g"))

if __name__ == "__main__":
    init_collections()
    for pdf in glob.glob(f"{DATA_DIR}/*.pdf"):
        ingest_pdf(pdf)
    ingest_images(IMAGES_DIR)
