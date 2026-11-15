"""Backend settings. Edit these values directly; no env vars or config files yet."""

QDRANT_URL = "http://localhost:6333"

TEXT_MODEL = "BAAI/bge-m3"        # 1024-dim
IMAGE_MODEL = "clip-ViT-B-32"     # 512-dim, text and images share one space
LLM_MODEL = "llama3.2"            # must support tool calling
LLM_TIMEOUT = 120                 # seconds; the first call also loads the model

DATA_DIR = "data"
IMAGES_DIR = "data/images"
