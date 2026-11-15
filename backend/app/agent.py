from langchain_core.tools import tool
from langchain_ollama import ChatOllama
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver
from .embeddings import embed_text, embed_text_for_image_search
from .vectordb import search, rrf

@tool
def search_documents(query: str) -> str:
    """Search the text knowledge base (courses, PDFs) for relevant passages."""
    hits = search("texts", embed_text([query])[0], limit=5)
    return "\n\n".join(
        f"[{h.payload['source']} p.{h.payload['page']}] {h.payload['content']}"
        for h in hits)

@tool
def search_images(query: str) -> str:
    """Find images related to the query. Returns image paths."""
    hits = search("images", embed_text_for_image_search(query), limit=3)
    return "\n".join(h.payload["path"] for h in hits)

llm = ChatOllama(model="llama3.2", temperature=0.2)   # must support tool calling
memory = MemorySaver()                                 # conversation memory

SYSTEM_PROMPT = """You are Emsi_chatBot. Use the tools to look up information
before answering. Cite your sources. If nothing relevant is found, say so."""

agent = create_react_agent(
    llm,
    tools=[search_documents, search_images],  # add MCP tools here (see below)
    checkpointer=memory,
    prompt=SYSTEM_PROMPT,
)

def ask(question: str, thread_id: str = "default") -> str:
    result = agent.invoke(
        {"messages": [("user", question)]},
        config={"configurable": {"thread_id": thread_id}})
    return result["messages"][-1].content