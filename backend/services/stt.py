import os


def _provider() -> str:
    configured = os.getenv("STT_PROVIDER", "auto").lower()
    if configured != "auto":
        return configured
    if os.getenv("GROQ_API_KEY"):
        return "groq"
    return "local"


async def transcribe(audio_bytes: bytes, audio_format: str) -> str:
    """Transcribe audio using the configured STT backend.

    auto (default): Groq if GROQ_API_KEY is set, else local Whisper.
    local: faster-whisper on CPU (free, no API key; first run downloads model).
    groq: Groq Whisper API (free tier at console.groq.com).
    openrouter: OpenRouter STT (paid — requires OpenRouter credits).
    """
    provider = _provider()
    if provider == "groq":
        from services.groq_stt import transcribe as fn
    elif provider == "openrouter":
        from services.openrouter import transcribe as fn
    elif provider == "local":
        from services.local_stt import transcribe as fn
    else:
        raise RuntimeError(f"Unknown STT_PROVIDER: {provider}")
    return await fn(audio_bytes, audio_format)


def provider_label() -> str:
    return _provider()
