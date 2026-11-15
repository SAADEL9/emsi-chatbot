from langchain_ollama import ChatOllama
from .embeddings import embed_text, embed_text_for_image_search
from .vectordb import search, rrf

llm = ChatOllama(model="llama3.2", temperature=0.2)

SYSTEM_PROMPT = """You are Emsi_chatBot, an assistant for EMSI students.
Answer ONLY using the provided context. If the answer is not in the context,
say you don't know. Always cite the source (file and page)."""


def classic_rag(question: str):
    # 1. Search text and images
    t_hits = search("texts", embed_text([question])[0], limit=5)
    i_hits = search("images", embed_text_for_image_search(question), limit=3)

    # 2. Fuse the two rankings with RRF
    context = rrf([t_hits, i_hits], top_n=5)
    ctx_str = "\n\n".join(str(c) for c in context)

    # 3. Ask the LLM with the context
    messages = [
        ("system", SYSTEM_PROMPT),
        ("human", f"Context:\n{ctx_str}\n\nQuestion: {question}"),
    ]
    return llm.invoke(messages).content, context