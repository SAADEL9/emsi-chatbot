import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .agent import ask
from .config import IMAGES_DIR
from .schemas import ChatRequest, ChatResponse
from .vectordb import client as qdrant

logger = logging.getLogger(__name__)

app = FastAPI(title="Emsi_chatBot API")
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_methods=["*"], allow_headers=["*"])
app.mount("/images", StaticFiles(directory=IMAGES_DIR), name="images")

@app.get("/health")
def health():
    try:
        qdrant.get_collections()
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Qdrant unreachable") from exc
    return {"status": "ok"}

@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    try:
        return ChatResponse(answer=ask(req.message, req.session_id))
    except Exception as exc:
        logger.exception("chat failed")
        raise HTTPException(status_code=503,
                            detail="Chat backend unavailable (Qdrant or Ollama down?)") from exc
