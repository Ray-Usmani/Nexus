import os
import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import insights, voice
from services.stt import provider_label

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
    stt = provider_label()
    return {
        "status": "ok",
        "model": os.getenv("OPENROUTER_MODEL", "openrouter/free"),
        "stt_provider": stt,
        "stt_note": "OpenRouter STT is paid; default uses local Whisper or Groq (free).",
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=6969)