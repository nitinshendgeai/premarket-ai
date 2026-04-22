"""
options/strategy_selector.py
─────────────────────────────
Maps market bias → index selection → options strategy.

Index selection logic
─────────────────────
  bank_strength == "strong" → BANK NIFTY
  else                      → NIFTY 50

Strategy logic
──────────────
  bullish  → Buy CE (Call Option)
  bearish  → Buy PE (Put Option)
  sideways → Avoid

Minimum confidence gate
───────────────────────
  Confidence < MIN_CONFIDENCE_TO_TRADE → Avoid regardless of bias.
  This prevents trading in low-conviction setups.
"""

from __future__ import annotations

MIN_CONFIDENCE_TO_TRADE = 45   # below this → force "Avoid"


def select_index(features: dict) -> str:
    """Return the best index to trade based on sector signals."""
    return "BANK NIFTY" if features.get("bank_strength") == "strong" else "NIFTY 50"


def select_strategy(bias: str, confidence: int) -> tuple[str, str]:
    """
    Parameters
    ----------
    bias       : "bullish" | "bearish" | "sideways"
    confidence : 0–100

    Returns
    -------
    (strategy, reason_fragment)
      strategy : "Buy CE" | "Buy PE" | "Avoid"
    """
    if confidence < MIN_CONFIDENCE_TO_TRADE:
        return (
            "Avoid",
            f"Confidence {confidence}% is below minimum threshold "
            f"({MIN_CONFIDENCE_TO_TRADE}%) — skip this session",
        )

    mapping = {
        "bullish":  ("Buy CE", "Bullish bias → Buy Call Option (CE)"),
        "bearish":  ("Buy PE", "Bearish bias → Buy Put Option (PE)"),
        "sideways": ("Avoid",  "Sideways market — no directional edge, avoid options"),
    }

    return mapping.get(bias, ("Avoid", "Unknown bias — defaulting to Avoid"))
