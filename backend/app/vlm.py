"""Image captioning through the configured vision model, for RAG over images."""

import base64
import logging
import mimetypes

from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI
from openai import OpenAIError

from .config import (
    GROK_MODEL,
    GROQ_BASE_URL,
    GROQ_KEYS,
    GROQ_VLM_MODEL,
    LLM_PROVIDER,
    LLM_TIMEOUT,
    OPENROUTER_API_KEY,
    OPENROUTER_BASE_URL,
    VLM_MODEL,
    XAI_API_KEY,
    XAI_BASE_URL,
)
from .errors import LLMUnavailable

logger = logging.getLogger(__name__)

if LLM_PROVIDER == "grok":
    if not XAI_API_KEY:
        raise RuntimeError("XAI_API_KEY is not set; add it to backend/.env")
    vlms = [ChatOpenAI(model=GROK_MODEL, temperature=0, timeout=LLM_TIMEOUT,
                       api_key=XAI_API_KEY, base_url=XAI_BASE_URL)]
elif LLM_PROVIDER == "groq":
    if not GROQ_KEYS:
        raise RuntimeError("GROQ_API_KEY is not set; add it to backend/.env")
    vlms = [ChatOpenAI(model=GROQ_VLM_MODEL, temperature=0, timeout=LLM_TIMEOUT,
                       max_tokens=450,  # free tier caps output at 1000 tokens/min
                       api_key=key, base_url=GROQ_BASE_URL)
            for key in GROQ_KEYS]
    if OPENROUTER_API_KEY:  # last resort when every Groq key is exhausted
        vlms.append(ChatOpenAI(model=VLM_MODEL, temperature=0, timeout=LLM_TIMEOUT,
                               api_key=OPENROUTER_API_KEY,
                               base_url=OPENROUTER_BASE_URL))
else:
    vlms = [ChatOpenAI(model=VLM_MODEL, temperature=0, timeout=LLM_TIMEOUT,
                       api_key=OPENROUTER_API_KEY, base_url=OPENROUTER_BASE_URL)]

PROMPT = """Describe this image for a searchable course knowledge base in under 250 words.
Transcribe all visible text, names, numbers and labels. Explain diagrams,
charts, screenshots and photos in enough detail that someone who cannot see
the image can understand it."""

def describe_image(path: str) -> str:
    mime = mimetypes.guess_type(path)[0] or "image/jpeg"
    with open(path, "rb") as f:
        data = base64.b64encode(f.read()).decode()
    message = HumanMessage(content=[
        {"type": "text", "text": PROMPT},
        {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{data}"}},
    ])
    for model in vlms:
        try:
            return model.invoke([message]).content
        except OpenAIError as exc:  # bad key, rate limit, outage: try the next key
            logger.warning("caption model failed: %s", exc)
    raise LLMUnavailable("every configured vision model failed")
