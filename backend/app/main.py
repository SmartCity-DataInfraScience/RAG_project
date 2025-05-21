from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Allow all domains to access
    allow_credentials=True,     # Allow cookies
    allow_methods=["*"],        # Allow all HTTP methods
    allow_headers=["*"],        # Allow all request headers
)

app.include_router(router)
