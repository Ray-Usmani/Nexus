import json
import os
from typing import Any

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile

from models.schemas import VoiceParseResponse
from services.openrouter import complete, parse_expense_fields
from services import stt

router = APIRouter(prefix="/voice", tags=["voice"])

PARSE_SYSTEM = """You extract structured expense data from natural language (often spoken).
Return ONLY valid JSON with these keys:
- amount (number, required if mentioned; use null if truly unknown)
- category_id (string, must be one of the provided category ids)
- note (short description of the expense)
- payment_method (one of: Cash, Card, UPI — default Cash)
- date (YYYY-MM-DD or null for today)
- tag_ids (array of tag ids from the provided list; empty if none match)

Rules:
- Currency is PKR/Rs; amounts are plain numbers (450 not "450 rs").
- Pick the best matching category by meaning (e.g. lunch → Food, uber → Transport).
- If multiple expenses are mentioned, extract the primary one only.
- Do not invent categories or tags not in the lists."""

_AUDIO_EXT = {
    "wav": "wav",
    "mp3": "mp3",
    "m4a": "m4a",
    "aac": "aac",
    "ogg": "ogg",
    "webm": "webm",
    "flac": "flac",
}


def verify_secret(authorization: str | None = Header(default=None)) -> None:
    secret = os.getenv("APP_SECRET", "")
    if not secret:
        return
    if authorization != f"Bearer {secret}":
        raise HTTPException(status_code=401, detail="Unauthorized")


def _audio_format(filename: str | None, content_type: str | None) -> str:
    if filename and "." in filename:
        ext = filename.rsplit(".", 1)[-1].lower()
        if ext in _AUDIO_EXT:
            return ext
    if content_type:
        ct = content_type.lower()
        for fmt in _AUDIO_EXT:
            if fmt in ct:
                return fmt
    return "m4a"


async def _parse_transcription(text: str, context: dict[str, Any]) -> VoiceParseResponse:
    categories = context.get("categories", [])
    tags = context.get("tags", [])
    user = (
        f"Transcription:\n{text}\n\n"
        f"Categories JSON:\n{json.dumps(categories)}\n\n"
        f"Tags JSON:\n{json.dumps(tags)}"
    )
    try:
        raw = await complete(PARSE_SYSTEM, user)
        parsed = parse_expense_fields(raw)
        return VoiceParseResponse(
            transcription=text,
            amount=parsed.get("amount"),
            category_id=parsed.get("category_id"),
            category_name=_category_name(categories, parsed.get("category_id")),
            note=parsed.get("note") or text,
            payment_method=parsed.get("payment_method") or "Cash",
            date=parsed.get("date"),
            tag_ids=parsed.get("tag_ids") or [],
        )
    except Exception as e:
        return VoiceParseResponse(transcription=text, note=text, error=str(e))


def _category_name(categories: list[Any], category_id: str | None) -> str | None:
    if not category_id:
        return None
    for c in categories:
        if isinstance(c, dict) and c.get("id") == category_id:
            return c.get("name")
    return None


@router.post("/parse", response_model=VoiceParseResponse, dependencies=[Depends(verify_secret)])
async def parse_voice(
    context: str = Form(...),
    audio: UploadFile | None = File(default=None),
    text: str | None = Form(default=None),
) -> VoiceParseResponse:
    try:
        ctx = json.loads(context)
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid context JSON: {e}") from e

    transcription = (text or "").strip()

    if audio is not None and audio.filename:
        audio_bytes = await audio.read()
        if not audio_bytes:
            raise HTTPException(status_code=400, detail="Empty audio file")
        fmt = _audio_format(audio.filename, audio.content_type)
        try:
            transcription = await stt.transcribe(audio_bytes, fmt)
        except Exception as e:
            msg = str(e)
            if "402" in msg or "credit" in msg.lower():
                msg += (
                    " OpenRouter STT is paid. Use STT_PROVIDER=local (default) or add a free "
                    "GROQ_API_KEY at console.groq.com."
                )
            return VoiceParseResponse(error=f"Transcription failed: {msg}")

    if not transcription:
        raise HTTPException(status_code=400, detail="Provide audio or text")

    return await _parse_transcription(transcription, ctx)
