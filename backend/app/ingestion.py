import uuid, glob, os
from pypdf import PdfReader
from qdrant_client.models import PointStruct
from .embeddings import embed_text, embed_image
from .vectordb import client, init_collections

def chunk_text(text: str, size=800, overlap=100):
    chunks, start = [], 0
    while start < len(text):
        chunks.append(text[start:start + size])
        start += size - overlap
    return chunks

def ingest_pdf(path: str):
    reader = PdfReader(path)
    points = []
    for page_no, page in enumerate(reader.pages, start=1):
        for chunk in chunk_text(page.extract_text() or ""):
            vec = embed_text([chunk])[0].tolist()
            points.append(PointStruct(
                id=str(uuid.uuid4()), vector=vec,
                payload={"type": "text", "content": chunk,
                         "source": os.path.basename(path), "page": page_no}))
    client.upsert("texts", points)

def ingest_images(folder: str):
    paths = glob.glob(f"{folder}/*.[jp][pn]g")
    vecs = embed_image(paths)
    points = [PointStruct(id=str(uuid.uuid4()), vector=v.tolist(),
                          payload={"type": "image", "path": p})
              for p, v in zip(paths, vecs)]
    client.upsert("images", points)

if __name__ == "__main__":
    init_collections()
    for pdf in glob.glob("data/*.pdf"):
        ingest_pdf(pdf)
    ingest_images("data/images")