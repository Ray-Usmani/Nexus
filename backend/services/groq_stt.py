import os

import httpx

GROQ_TRANSCRIBE_URL = "https://api.groq.com/openai/v1/audio/transcriptions"


async def transcribe(audio_bytes: bytes, audio_format: str) -> str:
    api_key = os.getenv("GROQ_API_KEY", "")
    if not api_key:
        raise RuntimeError("GROQ_API_KEY not set — get a free key at https://console.groq.com")

    model = os.getenv("GROQ_STT_MODEL", "whisper-large-v3-turbo")
    filename = f"recording.{audio_format}"
    mime = {
        "wav": "audio/wav",
        "mp3": "audio/mpeg",
        "m4a": "audio/mp4",
        "aac": "audio/aac",
        "ogg": "audio/ogg",
        "webm": "audio/webm",
        "flac": "audio/flac",
    }.get(audio_format, "application/octet-stream")

    async with httpx.AsyncClient(timeout=120.0) as client:
        res = await client.post(
            GROQ_TRANSCRIBE_URL,
            headers={"Authorization": f"Bearer {api_key}"},
            files={"file": (filename, audio_bytes, mime)},
            data={"model": model, "response_format": "json", "temperature": "0"},
        )
        if not res.is_success:
            detail = res.text
            try:
                detail = res.json().get("error", {}).get("message", detail)
            except Exception:
                pass
            raise RuntimeError(f"Groq STT {res.status_code}: {detail}")
        text = res.json().get("text", "").strip()
        if not text:
            raise RuntimeError("Groq transcription returned empty text")
        return text
