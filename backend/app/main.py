import logging
import os

from fastapi import Depends, FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .agent import ask
from .auth import current_user_id
from .config import DATA_DIR, IMAGES_DIR
from .errors import LLMUnavailable
from .ingestion import ingest_image_files, ingest_pdf, ingest_text
from .schemas import ChatRequest, ChatResponse
from .vectordb import client as qdrant
from .vlm import describe_image

logger = logging.getLogger(__name__)

UPLOAD_SUFFIXES = {".pdf", ".png", ".jpg", ".jpeg"}  # what the RAG pipeline can index
MAX_UPLOAD_BYTES = 30 * 1024 * 1024
LLM_DOWN = "The LLM is not working right now. All configured API keys failed; try again later."

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

def _free_path(folder: str, filename: str) -> str:
    """Never overwrite an existing corpus file that happens to share the name."""
    stem, ext = os.path.splitext(filename)
    path, n = os.path.join(folder, filename), 1
    while os.path.exists(path):
        path = os.path.join(folder, f"{stem}-{n}{ext}")
        n += 1
    return path


@app.post("/upload")
def upload(file: UploadFile = File(...), user_id: str | None = Depends(current_user_id)):
    """Index an uploaded PDF or image so the agent can search it."""
    name = os.path.basename(file.filename or "")
    ext = os.path.splitext(name)[1].lower()
    if ext not in UPLOAD_SUFFIXES:
        raise HTTPException(400, "Unsupported file: upload a PDF, PNG or JPG")
    data = file.file.read(MAX_UPLOAD_BYTES + 1)
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(413, f"File too large (max {MAX_UPLOAD_BYTES // (1024 * 1024)} MB)")

    path = _free_path(IMAGES_DIR if ext != ".pdf" else DATA_DIR, name)
    with open(path, "wb") as out:
        out.write(data)
    try:
        if ext == ".pdf":
            if not ingest_pdf(path):
                os.remove(path)  # nothing searchable in it; don't keep a dead file
                raise HTTPException(422, "No text or images found in this PDF")
        else:
            ingest_image_files([path])
            ingest_text(os.path.basename(path), describe_image(path))
    except HTTPException:
        raise
    except LLMUnavailable as exc:
        logger.warning("upload failed: %s", exc)
        raise HTTPException(status_code=503, detail=LLM_DOWN) from exc
    except Exception as exc:
        logger.exception("upload failed")
        raise HTTPException(503,
                            detail="Could not index the upload (Qdrant, embedding or vision model down?)") from exc
    return {"indexed": os.path.basename(path)}

@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest, user_id: str | None = Depends(current_user_id)):
    try:
        answer, images = ask(req.message, user_id or req.session_id)
        return ChatResponse(answer=answer, images=images)
    except LLMUnavailable as exc:
        logger.warning("chat failed: %s", exc)
        raise HTTPException(status_code=503, detail=LLM_DOWN) from exc
    except Exception as exc:
        logger.exception("chat failed")
        raise HTTPException(status_code=503,
                            detail="Chat backend unavailable (Qdrant or the LLM provider down?)") from exc
