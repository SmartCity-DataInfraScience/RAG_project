# import os
# from tqdm import tqdm
# from sentence_transformers import SentenceTransformer
# from langchain_community.document_loaders import PyMuPDFLoader
# from langchain.text_splitter import RecursiveCharacterTextSplitter
# import faiss
# import numpy as np
# import pickle
# from app.config import DATA_DIR, FAISS_DIR, OPENAI_API_KEY


# # KURE-v1 모델 로드
# model = SentenceTransformer("nlpai-lab/KURE-v1")

# def load_pdfs_and_create_faiss(pdf_paths, save_dir):
#     print("🚀 Starting vectorization...")
#     documents = []

#     # PDF 로딩
#     for filename in tqdm(pdf_paths, desc="📄 Loading PDFs"):
#         if filename.endswith(".pdf"):
#             filepath = os.path.join(DATA_DIR, filename)
#             loader = PyMuPDFLoader(filepath)
#             docs = loader.load()
#             documents.extend(docs)

#     # 텍스트 분할
#     splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
#     chunks = splitter.split_documents(documents)
#     texts = [chunk.page_content for chunk in chunks if chunk.page_content.strip()]

#     print(f"🧩 Total chunks: {len(texts)}")

#     embeddings = model.encode(texts, show_progress_bar=True)
#     embedding_matrix = np.array(embeddings).astype("float32")

#     index = faiss.IndexFlatL2(embedding_matrix.shape[1])
#     index.add(embedding_matrix)

#     os.makedirs(save_dir, exist_ok=True)
#     faiss.write_index(index, os.path.join(save_dir, "kure_index.index"))

#     with open(os.path.join(save_dir, "kure_chunks.pkl"), "wb") as f:
#         pickle.dump(texts, f)

#     print(f"✅ Saved FAISS index and chunks to → {save_dir}")

# if __name__ == "__main__":
#     all_pdfs = [f for f in os.listdir(DATA_DIR) if f.endswith(".pdf")]
#     load_pdfs_and_create_faiss(all_pdfs, FAISS_DIR)
import os
from tqdm import tqdm
from langchain_community.document_loaders import PyMuPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain.vectorstores import FAISS
from app.config import DATA_DIR, FAISS_DIR, OPENAI_API_KEY

def load_pdfs_and_create_vectorstore(pdf_paths):
    print("🚀 Starting vectorization...")
    documents = []

    # Load PDFs
    for filename in pdf_paths:
        if filename.endswith(".pdf"):
            filepath = os.path.join(DATA_DIR, filename)
            print(f"📄 Loading: {filename}")
            loader = PyMuPDFLoader(filepath)
            docs = loader.load()
            documents.extend(docs)

    # Split text
    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
    chunks = splitter.split_documents(documents)
    chunks = [chunk for chunk in chunks if chunk.page_content.strip()]
    print(f"🧩 Total valid chunks created: {len(chunks)}")

    # Embed and save to FAISS
    embeddings = OpenAIEmbeddings(openai_api_key=OPENAI_API_KEY)
    vectordb = FAISS.from_documents(documents=chunks, embedding=embeddings)
    vectordb.save_local(FAISS_DIR)
    print(f"✅ FAISS vector store saved to → {CHROMA_DIR}")

if __name__ == "__main__":
    all_pdfs = [f for f in os.listdir(DATA_DIR) if f.endswith(".pdf")]
    total = len(all_pdfs)
    batch_count = (total - 1) // 20 + 1

    print("🚀 Starting batch processing of all PDFs...")
    for i in range(batch_count):
        batch = all_pdfs[i * 20:(i + 1) * 20]
        print(f"\n🔄 Processing batch {i + 1} / {batch_count}...")
        load_pdfs_and_create_vectorstore(batch)
        