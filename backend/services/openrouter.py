import base64
import json
import os

import httpx

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
TRANSCRIBE_URL = "https://openrouter.ai/api/v1/audio/transcriptions"


async def complete(system: str, user: str) -> str:
    api_key = os.getenv("OPENROUTER_API_KEY", "")
    model = os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3.3-70b:free")
    if not api_key:
        raise RuntimeError("OPENROUTER_API_KEY not set")

    async with httpx.AsyncClient(timeout=60.0) as client:
        res = await client.post(
            OPENROUTER_URL,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": system},
                    {"role": "user", "content": user},
                ],
            },
        )
        res.raise_for_status()
        data = res.json()
        return data["choices"][0]["message"]["content"]


def parse_insight(raw: str) -> dict:
    return _extract_json(raw) or {"summary": raw.strip(), "recommendations": []}


def parse_expense_fields(raw: str) -> dict:
    return _extract_json(raw) or {}


def _extract_json(raw: str) -> dict | None:
    try:
        start = raw.find("{")
        end = raw.rfind("}") + 1
        if start >= 0 and end > start:
            return json.loads(raw[start:end])
    except json.JSONDecodeError:
        pass
    return None


async def transcribe(audio_bytes: bytes, audio_format: str) -> str:
    api_key = os.getenv("OPENROUTER_API_KEY", "")
    model = os.getenv("OPENROUTER_STT_MODEL", "openai/whisper-large-v3")
    if not api_key:
        raise RuntimeError("OPENROUTER_API_KEY not set")

    async with httpx.AsyncClient(timeout=120.0) as client:
        res = await client.post(
            TRANSCRIBE_URL,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "input_audio": {
                    "data": base64.b64encode(audio_bytes).decode("ascii"),
                    "format": audio_format,
                },
            },
        )
        res.raise_for_status()
        data = res.json()
        text = data.get("text", "").strip()
        if not text:
            raise RuntimeError("Transcription returned empty text")
        return text
