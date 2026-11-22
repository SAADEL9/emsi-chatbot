import logging, os, re, unicodedata
from urllib.parse import quote
from langchain_core.tools import tool
from langchain_ollama import ChatOllama
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver
from openai import OpenAIError
from qdrant_client.models import FieldCondition, Filter, MatchValue
from .config import (
    GROK_MODEL,
    GROQ_BASE_URL,
    GROQ_KEYS,
    GROQ_MODEL,
    LLM_MODEL,
    LLM_PROVIDER,
    LLM_TIMEOUT,
    OLLAMA_MODEL,
    OPENROUTER_API_KEY,
    OPENROUTER_BASE_URL,
    XAI_API_KEY,
    XAI_BASE_URL,
)
from .embeddings import embed_text, embed_text_for_image_search
from .errors import LLMUnavailable
from .vectordb import client, search

logger = logging.getLogger(__name__)

@tool
def search_documents(query: str) -> str:
    """Search the text knowledge base (courses, PDFs, image captions) for relevant passages."""
    hits = search("texts", embed_text([query])[0], limit=5)
    return "\n\n".join(
        f"[{h.payload['source']} p.{h.payload['page']}] {h.payload['content']}"
        for h in hits)

PERSON_WORDS = {"directeur", "directrice", "president", "presidente", "pdg", "dg",
                "drh", "fondateur", "fondatrice", "professeur", "enseignant",
                "laureat", "doyen", "recteur"}
STOPWORDS = {"photo", "photos", "image", "images", "montre", "montrer", "affiche",
             "donne", "voir", "quel", "quelle", "quels", "quelles", "avec", "pour",
             "dans", "sur", "les", "des", "une", "est", "que", "qui", "sont",
             "the", "and", "for", "with", "show", "me", "moi", "of", "du", "de",
             "la", "le", "un", "et"}


def _normalize(text: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", text.lower())
                   if unicodedata.category(c) != "Mn")


def _page_image(query: str):
    """Image from the PDF page whose text names the subject, when there is one."""
    words = [t for t in re.findall(r"[a-z0-9]+", _normalize(query))
             if len(t) >= 2 and t not in STOPWORDS]
    # Len 2 terms match inside unrelated words ("el" in "professionnel").
    terms = {t for t in words if len(t) >= 3} | (set(words) & PERSON_WORDS)
    if not terms:
        return None
    capitalized = re.search(r"\b[A-ZÀ-Ý][a-zà-ÿ]+(?:\s+[A-ZÀ-Ý][a-zà-ÿ]+)+", query)
    # Page-ground people and names; CLIP is fine for general subjects.
    if not (terms & PERSON_WORDS or capitalized):
        return None
    # The corpus is small; revisit if it grows past 1000 text chunks.
    points = client.scroll("texts", limit=1000, with_payload=True)[0]
    pages = {}
    for point in points:
        content = _normalize(point.payload.get("content", ""))
        key = (point.payload.get("source"), point.payload.get("page"))
        hits = {term for term in terms if term in content}
        if hits:
            pages.setdefault(key, set()).update(hits)
    scores = {}
    for hit in search("texts", embed_text([query])[0], limit=50):
        key = (hit.payload.get("source"), hit.payload.get("page"))
        scores[key] = max(scores.get(key, 0), hit.score)  # best chunk per page
    for source, page in sorted(pages, key=lambda k: (len(pages[k]), scores.get(k, 0)),
                               reverse=True):
        if not source or page is None:
            continue
        hits = client.query_points(
            collection_name="images",
            query=embed_text_for_image_search(query).tolist(),
            query_filter=Filter(must=[
                FieldCondition(key="source", match=MatchValue(value=source)),
                FieldCondition(key="page", match=MatchValue(value=page)),
            ]),
            limit=1, with_payload=True).points
        if hits:
            return hits[0]
    return None

@tool
def search_images(query: str) -> str:
    """Find the single most relevant image for the query. Returns its URL."""
    # CLIP scores every portrait almost identically; page text knows the name.
    hit = _page_image(query)
    if hit is None:
        hits = search("images", embed_text_for_image_search(query), limit=1)
        hit = hits[0] if hits else None
    if hit is None:
        return "No image found."
    # Payloads store server paths; the app fetches them from the /images mount.
    url = "/images/" + quote(os.path.basename(hit.payload["path"]))
    source, page = hit.payload.get("source"), hit.payload.get("page")
    return f"{url} ({source} p.{page})" if source and page else url

if LLM_PROVIDER == "ollama":  # local option for when the hosted APIs are unavailable
    llms = [("ollama", ChatOllama(model=OLLAMA_MODEL, temperature=0.2,
                                  client_kwargs={"timeout": LLM_TIMEOUT}))]
elif LLM_PROVIDER == "grok":
    if not XAI_API_KEY:
        raise RuntimeError("XAI_API_KEY is not set; add it to backend/.env")
    llms = [("grok", ChatOpenAI(model=GROK_MODEL, temperature=0.2, timeout=LLM_TIMEOUT,
                                api_key=XAI_API_KEY, base_url=XAI_BASE_URL))]
elif LLM_PROVIDER == "groq":
    if not GROQ_KEYS:
        raise RuntimeError("GROQ_API_KEY is not set; add it to backend/.env")
    llms = [(f"groq key {n}", ChatOpenAI(model=GROQ_MODEL, temperature=0.2,
                                         timeout=LLM_TIMEOUT, api_key=key,
                                         base_url=GROQ_BASE_URL))
            for n, key in enumerate(GROQ_KEYS, 1)]
    if OPENROUTER_API_KEY:  # last resort when every Groq key is exhausted
        llms.append(("openrouter", ChatOpenAI(model=LLM_MODEL, temperature=0.2,
                                              timeout=LLM_TIMEOUT,
                                              api_key=OPENROUTER_API_KEY,
                                              base_url=OPENROUTER_BASE_URL)))
else:
    if not OPENROUTER_API_KEY:
        raise RuntimeError("OPENROUTER_API_KEY is not set; add it to backend/.env")
    llms = [("openrouter", ChatOpenAI(model=LLM_MODEL, temperature=0.2,
                                      timeout=LLM_TIMEOUT,
                                      api_key=OPENROUTER_API_KEY,
                                      base_url=OPENROUTER_BASE_URL))]

SYSTEM_PROMPT = """You are Emsi_chatBot. Use the tools to look up information
before answering. Cite your sources. If nothing relevant is found, say so.
For questions about a person or a campus, also call search_images so the app
can show the matching picture.
Uploaded images and images inside PDFs are captioned in the text knowledge
base, so search documents to answer questions about them. Image URLs returned
by tools are displayed by the app automatically: mention them briefly, but
never paste or rewrite the URLs in your answer."""

# One agent per key with its own memory, so a fallback starts a fresh thread.
agents = [(name, create_react_agent(
    llm,
    tools=[search_documents, search_images],  # add MCP tools here (see below)
    checkpointer=MemorySaver(),
    prompt=SYSTEM_PROMPT,
)) for name, llm in llms]

IMAGE_URL = re.compile(r"/images/[^\s)\]\"',`]+")  # no trailing punctuation or backticks

def _image_urls(messages) -> list[str]:
    """Image URLs from this turn only; older turns live in the agent's memory."""
    start = max((i for i, m in enumerate(messages) if m.type == "human"), default=0)
    return list(dict.fromkeys(
        url.rstrip(".,;:")
        for message in messages[start:]
        for url in IMAGE_URL.findall(str(message.content))))[:6]

def ask(question: str, thread_id: str = "default") -> tuple[str, list[str]]:
    for name, agent in agents:
        try:
            result = agent.invoke(
                {"messages": [("user", question)]},
                config={"configurable": {"thread_id": thread_id}})
        except OpenAIError as exc:  # bad key, rate limit, outage: try the next key
            logger.warning("LLM %s failed: %s", name, exc)
            continue
        return result["messages"][-1].content, _image_urls(result["messages"])
    raise LLMUnavailable("every configured LLM key failed")
