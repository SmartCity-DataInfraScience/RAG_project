from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from app.rag_engine import query_rag
import os, json

router = APIRouter()

class ChatRequest(BaseModel):
    question: str
    history: List[str] = []
    top_k: int = 5

class ChatResponse(BaseModel):
    answer: str

@router.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest):
    try:
        answer = query_rag(
            question=request.question,
            history=request.history,
            k=request.top_k
        )
        return ChatResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

