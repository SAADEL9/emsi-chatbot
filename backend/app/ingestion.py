import glob, logging, os, time
from PIL import Image
from pypdf import PdfReader
from qdrant_client.models import PointStruct
from .chunking import point_id, usable_chunks
from .embeddings import embed_image, embed_text
from .config import DATA_DIR, IMAGES_DIR, LLM_PROVIDER
from .errors import LLMUnavailable
from .vectordb import client, init_collections
from .vlm import describe_image

logger = logging.getLogger(__name__)

PDF_IMAGE_MIN_SIDE = 100   # skip icons, bullets and tracking pixels
PDF_IMAGE_MAX_SIDE = 1600  # plenty for the app and the VLM, keeps files small
CAPTION_DELAY = 35 if LLM_PROVIDER == "groq" else 0  # Groq free tier: 8k tokens/min, 1k output/min


def _rgb(image):
    """Flatten transparency onto white; JPEG has no alpha channel."""
    if image.mode in ("RGBA", "LA", "P"):
        image = image.convert("RGBA")
        background = Image.new("RGB", image.size, "white")
        background.paste(image, mask=image.getchannel("A"))
        return background
    return image.convert("RGB")


def _pdf_images(reader):
    """Yield (page_no, index, RGB image) for embedded images worth indexing."""
    for page_no, page in enumerate(reader.pages, start=1):
        try:
            images = list(page.images)
        except Exception as exc:
            logger.warning("page %s: cannot list images: %s", page_no, exc)
            continue
        for idx, image_file in enumerate(images):
            try:
                image = _rgb(image_file.image)
            except Exception as exc:
                logger.warning("page %s image %s: cannot decode: %s", page_no, idx, exc)
                continue
            if min(image.size) < PDF_IMAGE_MIN_SIDE:
                continue
            yield page_no, idx, image


def ingest_pdf(path: str):
    reader = PdfReader(path)
    source = os.path.basename(path)
    stem = os.path.splitext(source)[0]

    text_items = [(chunk, page_no, idx)
                  for page_no, page in enumerate(reader.pages, start=1)
                  for idx, chunk in usable_chunks(page.extract_text() or "")]

    image_items = []  # (saved path, page, index)
    for page_no, idx, image in _pdf_images(reader):
        image.thumbnail((PDF_IMAGE_MAX_SIDE, PDF_IMAGE_MAX_SIDE))
        out = os.path.join(IMAGES_DIR, f"{stem}-p{page_no}-{idx}.jpg")
        image.save(out, "JPEG", quality=85)
        image_items.append((out, page_no, idx))

    # Skip images already captioned, so re-ingesting a PDF only pays for missing ones.
    caption_ids = [point_id(source, page, "img", idx) for _, page, idx in image_items]
    existing = ({p.id for p in client.retrieve("texts", ids=caption_ids, with_payload=False)}
                if caption_ids else set())
    caption_items = []  # (caption, page, index); a failed caption must not lose the image
    rate_limited = False
    for out, page_no, idx in image_items:
        if rate_limited or point_id(source, page_no, "img", idx) in existing:
            continue
        if CAPTION_DELAY:
            time.sleep(CAPTION_DELAY)
        try:
            caption_items.append((describe_image(out), page_no, idx))
        except LLMUnavailable as exc:
            logger.warning("%s p.%s: captions unavailable: %s", source, page_no, exc)
            rate_limited = True  # every later call would fail too; re-run resumes
        except Exception as exc:
            logger.warning("%s p.%s: caption failed: %s", source, page_no, exc)

    if not text_items and not image_items:
        print(f"warning: no text or images extracted from {source} - nothing indexed")
        return 0

    # One encode call per batch; per-chunk calls were the slow path.
    if text_items:
        vectors = embed_text([chunk for chunk, _, _ in text_items])
        client.upsert("texts", [
            PointStruct(id=point_id(source, page, idx), vector=v.tolist(),
                        payload={"type": "text", "content": chunk,
                                 "source": source, "page": page})
            for v, (chunk, page, idx) in zip(vectors, text_items)])

    if image_items:
        vectors = embed_image([p for p, _, _ in image_items])
        client.upsert("images", [
            PointStruct(id=point_id("image", os.path.basename(p)), vector=v.tolist(),
                        payload={"type": "image", "path": p,
                                 "source": source, "page": page})
            for v, (p, page, _) in zip(vectors, image_items)])

    if caption_items:
        vectors = embed_text([c for c, _, _ in caption_items])
        client.upsert("texts", [
            PointStruct(id=point_id(source, page, "img", idx), vector=v.tolist(),
                        payload={"type": "text", "content": caption,
                                 "source": source, "page": page})
            for v, (caption, page, idx) in zip(vectors, caption_items)])

    print(f"indexed {source}: {len(text_items)} text chunks, "
          f"{len(image_items)} images, {len(caption_items)} captions")
    return len(text_items) + len(image_items) + len(caption_items)

def ingest_image_files(paths: list[str]):
    """Index specific image files (uploads); `ingest_images` does a whole folder."""
    if not paths:
        return
    vecs = embed_image(paths)
    client.upsert("images", [
        PointStruct(id=point_id("image", os.path.basename(p)), vector=v.tolist(),
                    payload={"type": "image", "path": p})
        for p, v in zip(paths, vecs)])

def ingest_text(source: str, text: str):
    """Index plain text (e.g. an image caption) in the searchable texts collection."""
    items = list(usable_chunks(text))
    if not items:
        return 0
    vectors = embed_text([chunk for _, chunk in items])
    client.upsert("texts", [
        PointStruct(id=point_id(source, 1, idx), vector=v.tolist(),
                    payload={"type": "text", "content": chunk,
                             "source": source, "page": 1})
        for v, (idx, chunk) in zip(vectors, items)])
    return len(items)

def ingest_images(folder: str):
    ingest_image_files(glob.glob(f"{folder}/*.[jp][pn]g"))

if __name__ == "__main__":
    init_collections()
    for pdf in glob.glob(f"{DATA_DIR}/*.pdf"):
        ingest_pdf(pdf)
    ingest_images(IMAGES_DIR)
