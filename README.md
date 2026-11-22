# Emsi_chatBot

An intelligent mobile chatbot built with **Flutter** and powered by an **Agentic Multimodal RAG** back-end. Ask questions in natural language and get answers grounded in your own documents and images, with sources cited.

> Developed as a lab project at EMSI (started 10/11/2026).

---

## Table of Contents

1. [About the Project](#about-the-project)
2. [Features](#features)
3. [How It Works](#how-it-works)
4. [Architecture](#architecture)
5. [Tech Stack](#tech-stack)
6. [Project Structure](#project-structure)
7. [Getting Started](#getting-started)
8. [API Reference](#api-reference)
9. [Usage](#usage)
10. [Roadmap](#roadmap)
11. [Troubleshooting](#troubleshooting)
12. [Glossary](#glossary)

---

## About the Project

Large Language Models (LLMs) only know what they learned during training. They can't answer questions about *your* course material, PDFs, or images, and they sometimes make things up.

**Emsi_chatBot** solves this with **RAG (Retrieval Augmented Generation)**:

1. Your documents are split into chunks and converted into vectors (embeddings).
2. The vectors are stored in a **vector database**.
3. When a user asks a question, the most relevant chunks are retrieved by **semantic similarity**.
4. The LLM receives the question *plus* those chunks as context and writes a grounded answer.

The project goes beyond classic RAG in two ways:

- **Multimodal:** it works with text *and* images (and, later, tables and audio).
- **Agentic:** instead of a fixed pipeline, an **agent** (`LLM + Tools + Memory`) decides what to search and which tools to call, using the **ReAct** (Reasoning + Action) pattern.

---

## Features

| Feature | Description | Status |
|---|---|---|
| Chat interface | Flutter mobile app with a conversational UI | Core |
| Supabase auth | Email sign-up / sign-in; chat is keyed per user | Core |
| Semantic text search | Finds passages by meaning using BGE-M3 embeddings | Core |
| Image search | Finds images from a text query using CLIP | Core |
| Hybrid result fusion | Combines text and image rankings with **RRF** | Core |
| Source citations | Answers reference the file and page used | Core |
| LLM | OpenRouter by default, optional local Ollama fallback | Core |
| Agentic reasoning | ReAct agent chooses tools step by step (LangGraph) | Core |
| Conversation memory | The agent remembers earlier messages in a session | Core |
| MCP tools | Extend the agent with external tools via the Model Context Protocol | Core |
| Document ingestion | Text and embedded images from PDFs, plus standalone images, are indexed | Core |
| Image understanding (VLM) | Uploaded images and images inside PDFs are captioned and indexed for chat | Core |
| Audio input | Voice questions transcribed with Whisper | Planned |
| Table understanding | Extract and index tables from documents | Planned |
| Streaming answers | Typing effect via Server-Sent Events | Planned |

---

## How It Works

### Phase 1: Indexing (done by the developer)

```
Data source (text, images, audio, tables)
        │
        ▼
 1. Chunking        → split documents into small pieces
 2. Tokenization    → chunks become tokens
 3. Embedding       → tokens become vectors
        │              Text  : BGE-M3 (Transformer)
        │              Images: CLIP (ViT)
        ▼
    Vector DB
```

### Phase 2: Question answering (at runtime)

| Step | What happens |
|---|---|
| 1 | The user types a question in the mobile app |
| 2 | The app sends the user prompt to the FastAPI web service |
| 3 | The back-end queries the vector database |
| 4 | The database returns context (references, metadata, images) |
| 5 | The back-end sends *user prompt + context* (and a system prompt) to the LLM/VLM |
| 6 | The LLM generates the answer |
| 7 | The answer returns to the mobile app |
| 8 | The app displays it to the user |

### Semantic search and cosine similarity

Every chunk is a vector. Two chunks are similar when the angle between their vectors is small:

```
Sim(V1, V2) = cos(θ) = (V1 · V2) / (‖V1‖ · ‖V2‖)
```

With normalized vectors, this is just the dot product. Example: θ = 45° gives cos(45°) ≈ 0.71, so the two texts are about 71 % similar.

### Reciprocal Rank Fusion (RRF)

To merge text results and image results into one ranked list:

```
score(d) = Σ 1 / (k + rank_i(d))      with k = 60
```

### Classic RAG vs Agentic RAG

| | Classic Multimodal RAG | Agentic Multimodal RAG (this project) |
|---|---|---|
| Flow | Fixed: retrieve, then generate | Dynamic: the agent decides |
| Tools | None | Search tools, MCP tools |
| Memory | Usually none | Per-session conversation memory |
| Frameworks | Custom code | LangChain, LangGraph, MCP |

---

## Architecture

```
┌──────────────┐   HTTP/JSON    ┌──────────────────┐
│  Mobile App  │ ─────────────► │   FastAPI        │
│  (Flutter)   │ ◄───────────── │   Web Service    │
└──────────────┘                └────────┬─────────┘
                                         │
                                         ▼
                                ┌──────────────────┐        ┌────────────┐
                                │  LangGraph Agent │ ─────► │ MCP tools  │
                                │  (ReAct + memory)│        └────────────┘
                                └───┬──────────┬───┘
                       search tools │          │ prompt + context
                                    ▼          ▼
                            ┌────────────┐  ┌──────────────┐
                            │ Vector DB  │  │ LLM / VLM    │
                            │ (Qdrant)   │  │ (OpenRouter) │
                            └────────────┘  └──────────────┘
```

- **Front-end:** Flutter
- **Back-end:** FastAPI
- **Data layer:** Qdrant with two collections, `texts` (1024-dim) and `images` (512-dim), both using cosine distance

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter, Dart, `http`, Supabase Auth |
| API | Python 3.10+, FastAPI, Uvicorn |
| Text embeddings | BGE-M3 |
| Image embeddings | CLIP (ViT-B-32) via `sentence-transformers` |
| Vector database | Qdrant |
| LLM | OpenRouter (default), Groq, xAI Grok, or local Ollama, switchable via `LLM_PROVIDER` |
| VLM | OpenRouter, Groq (`qwen/qwen3.8-27b`), or xAI Grok, whichever `LLM_PROVIDER` selects |
| Agent framework | LangChain, LangGraph, `langchain-mcp-adapters` |
| Parsing | `pypdf`, `pdfplumber`, Pillow |
| Packaging | Docker, Docker Compose |

---

## Project Structure

```
emsi-chatbot/
├── backend/
│   ├── app/
│   │   ├── main.py            # FastAPI entry point and routes
│   │   ├── config.py          # settings
│   │   ├── embeddings.py      # BGE-M3 and CLIP wrappers
│   │   ├── vectordb.py        # Qdrant client, search, RRF
│   │   ├── ingestion.py       # chunking and indexing pipeline
│   │   ├── agent.py           # LangGraph ReAct agent
│   │   └── schemas.py         # request/response models
│   ├── data/                  # source documents and images
│   └── requirements.txt
├── mobile/                    # Flutter app
│   └── lib/
│       ├── main.dart
│       ├── services/api_service.dart
│       ├── services/auth_service.dart
│       └── screens/
├── docker-compose.yml
└── README.md
```

---

## Getting Started

### Prerequisites

- Python 3.10+ and `python3-venv`
- Flutter SDK
- Docker
- [OpenRouter](https://openrouter.ai) API key

### 1. Clone the repository

```bash
git clone <your-repo-url> emsi-chatbot
cd emsi-chatbot
```

### 2. Start Qdrant

```bash
docker run -d -p 6333:6333 -p 6334:6334 \
  -v $(pwd)/qdrant_data:/qdrant/storage \
  qdrant/qdrant
```

Dashboard: http://localhost:6333/dashboard

### 3. Configure OpenRouter

Create an API key at https://openrouter.ai/keys and put it in `backend/.env`:

```bash
cp backend/.env.example backend/.env
# edit backend/.env and set OPENROUTER_API_KEY=sk-or-v1-...
```

The default model is the free `nvidia/nemotron-3.5-lightning:free`; set `OPENROUTER_MODEL`
in `.env` to use any other [tool-calling model](https://openrouter.ai/models).
Image uploads are captioned by `nvidia/nemotron-3.5-super-vl:free`; override it with
`OPENROUTER_VLM_MODEL` using any [image-capable model](https://openrouter.ai/models).
Free models are rate-limited (about 20 requests/min and roughly 50 requests/day
without credits, shared by both models) and may be used for training by their
providers; pick a paid model if that matters. Captioning a large PDF uses one
vision request per image, so it can exhaust the free daily quota by itself.

To use Groq, add keys from https://console.groq.com/keys. It handles chat with
`openai/gpt-oss-120b` and image captions with `qwen/qwen3.8-27b`:

```bash
# backend/.env
LLM_PROVIDER=groq
GROQ_API_KEY=gsk_...
GROQ_API_KEY_2=gsk_...        # optional second key, tried next
OPENROUTER_API_KEY=sk-or-...  # last resort when both Groq keys fail
# GROQ_MODEL=openai/gpt-oss-120b
# GROQ_VLM_MODEL=qwen/qwen3.8-27b
```

When a key is rate-limited or rejected, chat and captioning try the next one.
If every key fails, `/chat` returns 503 with "The LLM is not working right now".
Keys in the same Groq organization share the free-tier quota.

To use xAI Grok instead, add an API key from https://console.x.ai and set the
provider. Grok handles both chat and image captions:

```bash
# backend/.env
LLM_PROVIDER=grok
XAI_API_KEY=xai-...
# GROK_MODEL=grok-4.7
```

If the free quota runs out, you can answer with a local Ollama model instead.
Install [Ollama](https://ollama.com), pull the model once, and set the provider
in `backend/.env`:

```bash
ollama pull llama3.2
# backend/.env
LLM_PROVIDER=ollama
```

Switch back with `LLM_PROVIDER=openrouter` when the quota resets. The VLM still
uses OpenRouter, so image captions need the OpenRouter quota.

### 4. Set up the back-end

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate

# Optional: CPU-only PyTorch (smaller download if you have no NVIDIA GPU)
pip install torch --index-url https://download.pytorch.org/whl/cpu

pip install -r requirements.txt
```

### 5. Index your data

Put PDFs in `backend/data/` and images in `backend/data/images/`, then run:

```bash
python -m app.ingestion
```

### 6. Run the API

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive docs: http://localhost:8000/docs

### 7. Set up Supabase Auth

1. Create a project at [supabase.com](https://supabase.com).
2. In **Authentication → Providers**, keep Email enabled. For local testing you can turn off **Confirm email**.
3. Copy the project URL and anon key from **Project Settings → API**.
4. Copy the JWT secret from the same page into `backend/.env` so the API can verify sessions:

```bash
# backend/.env
SUPABASE_JWT_SECRET=your-jwt-secret
```

5. Put the public keys in `mobile/supabase.json` (gitignored):

```bash
cp mobile/supabase.json.example mobile/supabase.json
# edit URL and anon key
```

### 8. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run --dart-define-from-file=supabase.json
```

Without that file the app still opens, but sign-in is disabled until the keys are set.

The app picks the API host automatically:

- Android emulator: `http://10.0.2.2:8000`
- Chrome/web, desktop, iOS simulator: `http://localhost:8000`
- Physical phone: pass your PC's LAN IP:

```bash
flutter run --dart-define-from-file=supabase.json --dart-define=API_URL=http://<your-PC-LAN-IP>:8000
```

---

## API Reference

### `POST /chat`

Send a message to the agent.

**Request**
```json
{
  "message": "What is cosine similarity?",
  "session_id": "mobile-user"
}
```

**Response**
```json
{
  "answer": "Cosine similarity measures the angle between two vectors...",
  "images": ["/images/Brochure-EMSI-p1-0.jpg"]
}
```

| Field | Type | Description |
|---|---|---|
| `message` | string | The user's question |
| `session_id` | string | Identifies the conversation, used by the agent's memory |
| `images` | string[] | Image URLs found by the agent; the app renders them under the answer |

> When `SUPABASE_JWT_SECRET` is set, send `Authorization: Bearer <access_token>`. The server ignores `session_id` and uses the token's user id. Without the secret, `session_id` is still unauthenticated (lab demo): anyone who knows an id shares that conversation's memory, and memory is process-local, so it resets when the server restarts.

**Example with curl**
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Explain RAG", "session_id": "test"}'
```

### `POST /upload`

Index a PDF or image so the agent can search it in later questions. Re-uploading the
same name never overwrites the existing file; it is stored with a `-1`, `-2`… suffix.

`multipart/form-data` with one field, `file` (PDF, PNG or JPG, max 30 MB).

```bash
curl -X POST http://localhost:8000/upload -F "file=@notes.pdf"
```

**Response**
```json
{ "indexed": "notes.pdf" }
```

Errors: `400` unsupported type, `413` too large, `422` PDF with no extractable
text or images, `503` Qdrant or the embedding model is down.

### Static files

Images are served from `/images/<filename>`.

---

## Usage

Example questions to try once your data is indexed:

- "Summarize chapter 2 of the course."
- "What is the difference between classic RAG and agentic RAG?"
- "Show me images related to neural network architectures."
- Upload a diagram or photo with **+**, then ask "What does this image show?"
- Follow-up questions such as "Can you explain that more simply?" (the agent uses memory)

Behavior to expect:

- The agent decides whether to search documents, search images, or both.
- If nothing relevant is found, it says it doesn't know rather than inventing an answer.
- Answers cite the source file and page.
- Images found by the agent are returned in `images` and shown under the answer.

---

## Roadmap

- [x] Indexing pipeline (chunking, embedding, Qdrant)
- [x] Classic multimodal RAG with RRF
- [x] Flutter chat UI
- [x] Agentic RAG with LangGraph, memory, and MCP
- [x] Image upload and VLM captioning
- [x] Embedded PDF images extracted, captioned, and shown in chat
- [ ] Audio input with Whisper
- [ ] Table extraction and indexing
- [ ] Streaming responses
- [x] Authentication and per-user data (Supabase)
- [ ] Evaluation suite for retrieval and answer quality
- [ ] Docker Compose deployment and release APK

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `externally-managed-environment` on `pip install` | Use a virtual environment: `python3 -m venv .venv && source .venv/bin/activate` |
| App can't reach the API | Use `10.0.2.2` on the Android emulator, or your PC's LAN IP on a real device |
| Plain HTTP blocked on Android | Add `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` for development |
| Agent never calls tools | Use an OpenRouter model that supports tool calling (e.g. `nvidia/nemotron-3.5-lightning:free`) |
| `429` from a provider | Rate limit reached; wait for the reset, add credits, or switch `LLM_PROVIDER` to `groq`, `grok`, or `ollama` in `backend/.env` |
| `401` / `No auth credentials` from OpenRouter | Set `OPENROUTER_API_KEY` in `backend/.env` and restart the API |
| Slow first answer | The local embedding models load on first call; later answers are faster |
| Irrelevant search results | Make sure indexing and querying use the same embedding model; tune chunk size and `top_k` |
| Hallucinated answers | Keep the "answer only from context" system prompt and a low temperature |
| Large install size | Install CPU-only PyTorch before the other dependencies |

---

## Glossary

- **RAG:** Retrieval Augmented Generation, where retrieved context is given to an LLM before it answers.
- **Chunk:** a small piece of a document.
- **Token:** a unit of text read by a model (word or sub-word).
- **Embedding:** a numeric vector that represents meaning.
- **Vector DB:** a database optimized for similarity search over vectors.
- **LLM / VLM:** Large Language Model / Vision-Language Model.
- **RRF:** Reciprocal Rank Fusion, a method for merging ranked lists.
- **MCP:** Model Context Protocol, a standard way to give LLMs access to tools and data.
- **ReAct:** an agent loop that alternates reasoning and actions.
- **System prompt:** hidden instructions that define the assistant's behavior.

---

## License

Educational project, EMSI. Add a license of your choice (for example MIT) before publishing.
