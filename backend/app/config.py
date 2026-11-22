"""Backend settings. Secrets come from backend/.env; the rest are constants."""

import os

from dotenv import load_dotenv

load_dotenv()

QDRANT_URL = "http://localhost:6333"

TEXT_MODEL = "BAAI/bge-m3"        # 1024-dim
IMAGE_MODEL = "clip-ViT-B-32"     # 512-dim, text and images share one space
OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY", "")
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
XAI_API_KEY = os.environ.get("XAI_API_KEY", "")
XAI_BASE_URL = "https://api.x.ai/v1"
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_API_KEY_2 = os.environ.get("GROQ_API_KEY_2", "")
GROQ_KEYS = list(dict.fromkeys(k for k in (GROQ_API_KEY, GROQ_API_KEY_2) if k))
GROQ_BASE_URL = "https://api.groq.com/openai/v1"
LLM_PROVIDER = os.environ.get("LLM_PROVIDER", "openrouter").lower()  # openrouter | grok | groq | ollama
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.2")
LLM_MODEL = os.environ.get("OPENROUTER_MODEL", "nvidia/nemotron-3.5-lightning:free")  # must support tool calling
VLM_MODEL = os.environ.get("OPENROUTER_VLM_MODEL", "nvidia/nemotron-3.5-super-vl:free")  # must accept images
GROK_MODEL = os.environ.get("GROK_MODEL", "grok-4.7")  # supports tool calling and image input
GROQ_MODEL = os.environ.get("GROQ_MODEL", "openai/gpt-oss-120b")  # text-only, supports tool calling
GROQ_VLM_MODEL = os.environ.get("GROQ_VLM_MODEL", "qwen/qwen3.8-27b")  # accepts images
LLM_TIMEOUT = 600 if LLM_PROVIDER == "ollama" else 120   # local CPU inference is slow

# When set, /chat and /upload require a Supabase access token (JWT secret from
# Project Settings → API). Leave empty for local demos without login.
SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET", "")

DATA_DIR = "data"
IMAGES_DIR = "data/images"
