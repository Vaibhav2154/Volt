import aiohttp
import os
import re
from typing import Optional

from app.utils.constants import MERCHANT_KEYWORDS, ALL_CATEGORIES
from app.schemas.simulation_schemas import CategorizationContext, CategorizationResult


class CategorizationService:
    """
    Hybrid transaction categorization:
    - Rule-based (fast)
    - Gemini fallback (accurate)
    """

    def __init__(self, gemini_api_key: str):
        self.gemini_api_key = gemini_api_key
        self.llm_cache: dict[str, CategorizationResult] = {}

    # Merchant Normalization
    def normalize(self, text: str) -> str:
        """Remove noise from merchant strings."""
        if not text:
            return ""
        text = text.lower()
        text = re.sub(r"[^a-z ]", " ", text)
        return re.sub(r"\s+", " ", text).strip()

    # Rule-Based Categorization
    def categorize_rule_based(self, merchant: str, amount: float, raw_message: str) -> Optional[str]:
        if not merchant:
            return None

        merchant_clean = self.normalize(merchant)
        raw_clean = self.normalize(raw_message or "")

        # Merchant keyword match
        for category, keywords in MERCHANT_KEYWORDS.items():
            if any(keyword in merchant_clean for keyword in keywords):
                return category

        # Use raw message as fallback
        for category, keywords in MERCHANT_KEYWORDS.items():
            if any(keyword in raw_clean for keyword in keywords):
                return category

        return None

    # Gemini API Call (Fastest: aiohttp)
    async def _call_gemini(self, prompt: str) -> dict:
        """
        Calls Gemini 1.5 Flash with async http request.
        Returns raw JSON.
        """
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/"
            f"gemini-1.5-flash:generateContent?key={self.gemini_api_key}"
        )

        payload = {
            "contents": [
                {
                    "parts": [
                        { "text": prompt }
                    ]
                }
            ]
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                return await resp.json()

    # LLM Categorization (Gemini Fallback)
    async def categorize_with_llm(
        self,
        merchant: str,
        amount: float,
        raw_message: str,
        transaction_type: str
    ) -> CategorizationResult:

        cache_key = f"{merchant.strip().lower()}_{transaction_type}"
        if cache_key in self.llm_cache:
            return self.llm_cache[cache_key]

        context = CategorizationContext(
            merchant=merchant or "Unknown",
            amount=amount,
            raw_message=raw_message,
            transaction_type=transaction_type
        )

        # ----------------- Gemini Prompt ----------------------
        prompt = f"""
You are an expert financial transaction classifier.

Classify the following transaction into ONE category:
{", ".join(sorted(ALL_CATEGORIES))}

Return STRICT JSON in this format:
{{
  "category": "...",
  "confidence": 0.0 to 1.0,
  "reasoning": "..."
}}

Transaction Details:
Merchant: {context.merchant}
Amount: ₹{context.amount}
Type: {context.transaction_type}
SMS: {context.raw_message[:250] if context.raw_message else "N/A"}

Rules:
- Category must be one of: {', '.join(sorted(ALL_CATEGORIES))}
- If uncertain, choose "OTHER" with confidence < 0.5.
- Keep JSON parseable.
"""

        # ------------------ Gemini API Call -------------------
        try:
            raw = await self._call_gemini(prompt)

            # Extract model text safely
            output_text = (
                raw.get("candidates", [{}])[0]
                   .get("content", {})
                   .get("parts", [{}])[0]
                   .get("text", "")
            )

            # Parse JSON returned by Gemini
            import json
            parsed = json.loads(output_text)

            category = parsed.get("category", "OTHER").upper()
            confidence = float(parsed.get("confidence", 0.3))
            reasoning = parsed.get("reasoning", "No reasoning provided.")

            # Validate category
            if category not in ALL_CATEGORIES:
                category = "OTHER"

            result = CategorizationResult(
                category=category,
                confidence=confidence,
                reasoning=reasoning
            )

            self.llm_cache[cache_key] = result
            return result

        except Exception as e:
            print("Gemini categorization failed:", e)
            return CategorizationResult(
                category="OTHER",
                confidence=0.3,
                reasoning=f"Gemini error: {str(e)}"
            )

    # Main Categorization Method
    async def categorize(
        self,
        merchant: str,
        amount: float,
        raw_message: str = "",
        transaction_type: str = "debit"
    ) -> tuple[str, float]:

        # 1️⃣ Rule-based first (fast)
        category = self.categorize_rule_based(merchant, amount, raw_message)
        if category:
            return category, 0.95

        # 2️⃣ LLM fallback (Gemini)
        result = await self.categorize_with_llm(
            merchant,
            amount,
            raw_message,
            transaction_type
        )

        return result.category, result.confidence
