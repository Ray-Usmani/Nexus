from typing import Any

from pydantic import BaseModel, Field


class InsightResponse(BaseModel):
    summary: str
    recommendations: list[str] = Field(default_factory=list)


class ChatRequest(BaseModel):
    message: str
    context: dict[str, Any] = Field(default_factory=dict)
