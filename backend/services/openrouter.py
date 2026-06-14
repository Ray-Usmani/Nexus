import json
import os

import httpx

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


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
    try:
        start = raw.find("{")
        end = raw.rfind("}") + 1
        if start >= 0 and end > start:
            return json.loads(raw[start:end])
    except json.JSONDecodeError:
        pass
    return {"summary": raw.strip(), "recommendations": []}
