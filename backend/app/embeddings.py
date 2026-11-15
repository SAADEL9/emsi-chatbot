from sentence_transformers import SentenceTransformer
from PIL import Image
from .config import IMAGE_MODEL, TEXT_MODEL

text_model = SentenceTransformer(TEXT_MODEL)             # 1024-dim
image_model = SentenceTransformer(IMAGE_MODEL)           # 512-dim, text + images

def embed_text(texts: list[str]):
    return text_model.encode(texts, normalize_embeddings=True)

def embed_image(paths: list[str]):
    imgs = [Image.open(p).convert("RGB") for p in paths]
    return image_model.encode(imgs, normalize_embeddings=True)

def embed_text_for_image_search(query: str):
    # CLIP maps text and images into the same space
    return image_model.encode([query], normalize_embeddings=True)[0]