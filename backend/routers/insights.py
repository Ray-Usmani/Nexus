import os
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Request

from models.schemas import ChatRequest, InsightResponse
from services.openrouter import complete, parse_insight

router = APIRouter(prefix="/insights", tags=["insights"])

SYSTEM_PROMPT = """You are a personal budget coach. Analyze ONLY the JSON context provided.
Return valid JSON with keys: summary (1-2 sentences), recommendations (array of 2-4 short actionable strings).
Do not invent transactions or amounts not in the context. Be concise and practical."""


def verify_secret(authorization: str | None = Header(default=None)) -> None:
    secret = os.getenv("APP_SECRET", "")
    if not secret:
        return
    if authorization != f"Bearer {secret}":
        raise HTTPException(status_code=401, detail="Unauthorized")


async def _insight(context: dict[str, Any], focus: str) -> InsightResponse:
    user = f"{focus}\n\nContext JSON:\n{context}"
    try:
        raw = await complete(SYSTEM_PROMPT, user)
        parsed = parse_insight(raw)
        return InsightResponse(
            summary=parsed.get("summary", ""),
            recommendations=parsed.get("recommendations", []),
        )
    except Exception as e:
        return InsightResponse(
            summary=f"AI unavailable: {e}",
            recommendations=["Review envelopes where actual exceeds planned."],
        )


@router.post("/daily", response_model=InsightResponse, dependencies=[Depends(verify_secret)])
async def daily_insight(request: Request) -> InsightResponse:
    context = await request.json()
    return await _insight(context, "Give one insight of the day for this user's budget.")


@router.post("/weekly", response_model=InsightResponse, dependencies=[Depends(verify_secret)])
async def weekly_insight(request: Request) -> InsightResponse:
    context = await request.json()
    return await _insight(context, "Weekly budget review with recommendations.")


@router.post("/chat", response_model=InsightResponse, dependencies=[Depends(verify_secret)])
async def chat(body: ChatRequest) -> InsightResponse:
    user = f"User question: {body.message}\n\nContext JSON:\n{body.context}"
    try:
        raw = await complete(SYSTEM_PROMPT, user)
        parsed = parse_insight(raw)
        return InsightResponse(
            summary=parsed.get("summary", ""),
            recommendations=parsed.get("recommendations", []),
        )
    except Exception as e:
        return InsightResponse(summary=str(e), recommendations=[])
