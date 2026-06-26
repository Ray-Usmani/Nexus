import asyncio
import os
import tempfile
from pathlib import Path

_model = None


def _get_model():
    global _model
    if _model is None:
        from faster_whisper import WhisperModel

        size = os.getenv("WHISPER_MODEL_SIZE", "base")
        device = os.getenv("WHISPER_DEVICE", "cpu")
        compute = os.getenv("WHISPER_COMPUTE", "int8")
        _model = WhisperModel(size, device=device, compute_type=compute)
    return _model


def _transcribe_sync(audio_bytes: bytes, audio_format: str) -> str:
    suffix = f".{audio_format}" if audio_format else ".m4a"
    path = None
    try:
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as f:
            f.write(audio_bytes)
            path = f.name
        segments, _ = _get_model().transcribe(path, vad_filter=True)
        text = " ".join(s.text.strip() for s in segments).strip()
        if not text:
            raise RuntimeError("Local Whisper returned empty text")
        return text
    finally:
        if path:
            Path(path).unlink(missing_ok=True)


async def transcribe(audio_bytes: bytes, audio_format: str) -> str:
    return await asyncio.to_thread(_transcribe_sync, audio_bytes, audio_format)
