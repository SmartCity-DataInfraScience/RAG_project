# from langchain_community.vectorstores import FAISS
# from sentence_transformers import SentenceTransformer
# from langchain.chat_models import ChatOpenAI
# from langchain.schema import SystemMessage, HumanMessage, AIMessage
# from app.config import FAISS_DIR, LLM_MODEL, LLM_TEMPERATURE
# import pickle
# import faiss

# # Custom embedding using SentenceTransformer
# class KureEmbedding:
#     def __init__(self):
#         print("Loading KURE-v1 SentenceTransformer...")
#         self.model = SentenceTransformer("nlpai-lab/KURE-v1")

#     def embed_documents(self, texts):
#         return self.model.encode(texts, show_progress_bar=True, convert_to_numpy=True).tolist()

#     def embed_query(self, text):
#         return self.model.encode([text], convert_to_numpy=True)[0].tolist()

# # Initialization
# try:
#     print("Initializing KURE Embeddings...")
#     embedding = KureEmbedding()

#     print("Loading FAISS index...")
#     index = faiss.read_index(f"{FAISS_DIR}/kure_index.index")

#     print("Loading chunks...")
#     with open(f"{FAISS_DIR}/kure_chunks.pkl", "rb") as f:
#         texts = pickle.load(f)

#     print("Loading sources...")
#     with open(f"{FAISS_DIR}/kure_sources.pkl", "rb") as f:
#         metadatas = pickle.load(f)

#     vectordb = FAISS(embedding_function=embedding.embed_query, index=index, documents=texts, docstore=None, index_to_docstore_id=None)

#     print("Initializing ChatOpenAI...")
#     llm = ChatOpenAI(
#         temperature=LLM_TEMPERATURE,
#         model_name=LLM_MODEL,
#         request_timeout=15
#     )
# except Exception as e:
#     print("Initialization failed:", e)
#     raise e

# # RAG query function
# def query_rag(question: str, history: list[str], k: int = 3) -> str:
#     print("Input question:", question)

#     try:
#         print("Starting similarity search in FAISS DB")
#         query_vec = embedding.embed_query(question)
#         D, I = vectordb.index.search([query_vec], k)
#         docs = [texts[i] for i in I[0] if i != -1]
#         print(f"Retrieved {len(docs)} relevant documents")
#     except Exception as e:
#         print("similarity_search failed:", e)
#         return "Error: Failed to search from FAISS DB."

#     context = "\n\n".join(docs) or "No relevant documents were found."

#     messages = [
#         SystemMessage(content="You are a construction safety manual expert chatbot. Always respond in English, even if the question or documents are in Korean. Your answers must be accurate and concise."),
#         HumanMessage(content=f"Refer to the following content to answer the question:\n\n{context}")
#     ]

#     for idx, msg in enumerate(history):
#         if idx % 2 == 0:
#             messages.append(HumanMessage(content=msg))
#         else:
#             messages.append(AIMessage(content=msg))

#     messages.append(HumanMessage(content=question))

#     try:
#         print("Requesting GPT response...")
#         response = llm.invoke(messages)
#         print("GPT response received")
#         return response.content
#     except Exception as e:
#         print("GPT API error:", e)
#         return "Error: GPT failed to respond. Please try again later."

from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings
from langchain.chat_models import ChatOpenAI
from langchain.schema import SystemMessage, HumanMessage, AIMessage
from app.config import OPENAI_API_KEY, FAISS_DIR, LLM_MODEL, LLM_TEMPERATURE
from openai import OpenAIError

# Initialization
try:
    print("Loading OpenAIEmbeddings...")
    embedding = OpenAIEmbeddings(openai_api_key=OPENAI_API_KEY)

    print("Loading FAISS DB...")
    vectordb = FAISS.load_local(
        FAISS_DIR,
        embeddings=embedding,
        allow_dangerous_deserialization=True
    )

    print("Initializing ChatOpenAI...")
    llm = ChatOpenAI(
        temperature=LLM_TEMPERATURE,
        model_name=LLM_MODEL,
        openai_api_key=OPENAI_API_KEY,
        request_timeout=15
    )
except Exception as e:
    print("Initialization failed:", e)
    raise e

# RAG query function
def query_rag(question: str, history: list[str], k: int = 3) -> str:
    print("Input question:", question)

    try:
        docs = vectordb.similarity_search(question, k=k)
        docs = [doc for doc in docs if len(doc.page_content.strip()) > 30]
        print(f"Retrieved {len(docs)} relevant documents")
    except Exception as e:
        print("similarity_search failed:", e)
        return "Error: Failed to search from FAISS DB."

    context = "\n\n".join([doc.page_content for doc in docs]) or "No relevant documents were found."
    print("Context to GPT:\n", context)

    messages = [
        SystemMessage(content=(
            "You are a professional chatbot for Korean construction safety manuals. "
            "Always respond in the following format:\n\n"
            "[Question]\n{user question}\n\n"
            "[Relevant Regulation Summary]\nSummarize the content extracted from the documents in English, even if the original documents are in Korean.\n\n"
            "[Expert Answer]\nProvide an accurate and concise answer based on the documents or general knowledge.\n\n"
            "[Recommendation]\nRecommend follow-up actions or specific regulations.\n\n"
            "Always respond only in English. Never include Korean text in your output. The tone should be clear, technical, and professional."
        )),
        HumanMessage(content=f"Refer to the following content to answer the question:\n\n{context}")
    ]

    for idx, msg in enumerate(history):
        messages.append(HumanMessage(content=msg) if idx % 2 == 0 else AIMessage(content=msg))

    messages.append(HumanMessage(content=question))

    try:
        response = llm.invoke(messages)
        return response.content
    except OpenAIError as e:
        print("GPT API error:", e)
        return "Error: GPT failed to respond. Please try again later."