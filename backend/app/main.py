import logging
import os

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .agent import ask
from .config import DATA_DIR, IMAGES_DIR
from .ingestion import ingest_image_files, ingest_pdf
from .schemas import ChatRequest, ChatResponse
from .vectordb import client as qdrant

logger = logging.getLogger(__name__)

UPLOAD_SUFFIXES = {".pdf", ".png", ".jpg", ".jpeg"}  # what the RAG pipeline can index
MAX_UPLOAD_BYTES = 20 * 1024 * 1024

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
def upload(file: UploadFile = File(...)):
    """Index an uploaded PDF or image so the agent can search it."""
    name = os.path.basename(file.filename or "")
    ext = os.path.splitext(name)[1].lower()
    if ext not in UPLOAD_SUFFIXES:
        raise HTTPException(400, "Unsupported file: upload a PDF, PNG or JPG")
    data = file.file.read(MAX_UPLOAD_BYTES + 1)
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(413, "File too large (max 20 MB)")

    path = _free_path(IMAGES_DIR if ext != ".pdf" else DATA_DIR, name)
    with open(path, "wb") as out:
        out.write(data)
    try:
        if ext == ".pdf":
            if not ingest_pdf(path):
                os.remove(path)  # nothing searchable in it; don't keep a dead file
                raise HTTPException(422, "No text found in this PDF (scanned image?)")
        else:
            ingest_image_files([path])
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("upload failed")
        raise HTTPException(503,
                            detail="Could not index the upload (Qdrant or embedding model down?)") from exc
    return {"indexed": os.path.basename(path)}

@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    try:
        return ChatResponse(answer=ask(req.message, req.session_id))
    except Exception as exc:
        logger.exception("chat failed")
        raise HTTPException(status_code=503,
                            detail="Chat backend unavailable (Qdrant or Ollama down?)") from exc
