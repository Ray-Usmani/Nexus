import os
import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import insights, voice

load_dotenv()

app = FastAPI(title="Nexus AI API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(insights.router)
app.include_router(voice.router)


@app.get("/health")
def health():
    return {
        "status": "ok",
        "model": os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3.3-70b:free"),
        "stt_model": os.getenv("OPENROUTER_STT_MODEL", "openai/whisper-large-v3"),
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=6969)