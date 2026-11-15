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
| Semantic text search | Finds passages by meaning using BGE-M3 embeddings | Core |
| Image search | Finds images from a text query using CLIP | Core |
| Hybrid result fusion | Combines text and image rankings with **RRF** | Core |
| Source citations | Answers reference the file and page used | Core |
| Local LLM | Runs through Ollama, so data stays on your machine | Core |
| Agentic reasoning | ReAct agent chooses tools step by step (LangGraph) | Core |
| Conversation memory | The agent remembers earlier messages in a session | Core |
| MCP tools | Extend the agent with external tools via the Model Context Protocol | Core |
| Document ingestion | Chunking, embedding, and indexing of PDFs and images | Core |
| Image questions (VLM) | Send an image from the phone and ask about it | Planned |
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
                            │ (Qdrant)   │  │ (Ollama)     │
                            └────────────┘  └──────────────┘
```

- **Front-end:** Flutter
- **Back-end:** FastAPI
- **Data layer:** Qdrant with two collections, `texts` (1024-dim) and `images` (512-dim), both using cosine distance

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter, Dart, `http` |
| API | Python 3.10+, FastAPI, Uvicorn |
| Text embeddings | BGE-M3 |
| Image embeddings | CLIP (ViT-B-32) via `sentence-transformers` |
| Vector database | Qdrant |
| LLM / VLM | Ollama (`llama3.2`, `llama3.2-vision`) |
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
│       └── screens/chat_screen.dart
├── docker-compose.yml
└── README.md
```

---

## Getting Started

### Prerequisites

- Python 3.10+ and `python3-venv`
- Flutter SDK
- Docker
- [Ollama](https://ollama.com)

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

### 3. Pull the Ollama models

```bash
ollama pull llama3.2
ollama pull llama3.2-vision   # optional, for image questions
```

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

### 7. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run
```

In `lib/services/api_service.dart`, set `baseUrl` to:

- `http://10.0.2.2:8000` for the Android emulator
- `http://<your-PC-LAN-IP>:8000` for a physical phone on the same Wi-Fi

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
  "answer": "Cosine similarity measures the angle between two vectors..."
}
```

| Field | Type | Description |
|---|---|---|
| `message` | string | The user's question |
| `session_id` | string | Identifies the conversation, used by the agent's memory |

> `session_id` is not authenticated: anyone who knows an id shares that conversation's memory, and memory is process-local, so it resets when the server restarts. Lab demo only.

**Example with curl**
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Explain RAG", "session_id": "test"}'
```

### `POST /upload`

Index a PDF or image so the agent can search it in later questions. Re-uploading the
same name never overwrites the existing file; it is stored with a `-1`, `-2`… suffix.

`multipart/form-data` with one field, `file` (PDF, PNG or JPG, max 20 MB).

```bash
curl -X POST http://localhost:8000/upload -F "file=@notes.pdf"
```

**Response**
```json
{ "indexed": "notes.pdf" }
```

Errors: `400` unsupported type, `413` too large, `422` PDF with no extractable text
(scanned pages), `503` Qdrant or the embedding model is down.

### Static files

Images are served from `/images/<filename>`.

---

## Usage

Example questions to try once your data is indexed:

- "Summarize chapter 2 of the course."
- "What is the difference between classic RAG and agentic RAG?"
- "Show me images related to neural network architectures."
- Follow-up questions such as "Can you explain that more simply?" (the agent uses memory)

Behavior to expect:

- The agent decides whether to search documents, search images, or both.
- If nothing relevant is found, it says it doesn't know rather than inventing an answer.
- Answers cite the source file and page.

---

## Roadmap

- [x] Indexing pipeline (chunking, embedding, Qdrant)
- [x] Classic multimodal RAG with RRF
- [x] Flutter chat UI
- [x] Agentic RAG with LangGraph, memory, and MCP
- [ ] Image upload and VLM question answering
- [ ] Audio input with Whisper
- [ ] Table extraction and indexing
- [ ] Streaming responses
- [ ] Authentication and per-user data
- [ ] Evaluation suite for retrieval and answer quality
- [ ] Docker Compose deployment and release APK

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `externally-managed-environment` on `pip install` | Use a virtual environment: `python3 -m venv .venv && source .venv/bin/activate` |
| App can't reach the API | Use `10.0.2.2` on the Android emulator, or your PC's LAN IP on a real device |
| Plain HTTP blocked on Android | Add `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` for development |
| Agent never calls tools | Use an Ollama model that supports tool calling (`llama3.2`, `qwen2.5`) |
| Irrelevant search results | Make sure indexing and querying use the same embedding model; tune chunk size and `top_k` |
| Slow first answer | The model loads on first call; warm it up at server start |
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
