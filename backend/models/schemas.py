from typing import Any

from pydantic import BaseModel, Field


class InsightResponse(BaseModel):
    summary: str
    recommendations: list[str] = Field(default_factory=list)


class ChatRequest(BaseModel):
    message: str
    context: dict[str, Any] = Field(default_factory=dict)


class VoiceParseResponse(BaseModel):
    transcription: str = ""
    amount: float | None = None
    category_id: str | None = None
    category_name: str | None = None
    note: str = ""
    payment_method: str = "Cash"
    date: str | None = None
    tag_ids: list[str] = Field(default_factory=list)
    error: str | None = None
