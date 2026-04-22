"""
features/feature_engine.py
──────────────────────────
Converts raw market / global / news dicts into a flat, typed signal dict
consumed by the decision engine.

Signals produced
────────────────
  gift_nifty_trend  : "bullish" | "bearish"
  global_sentiment  : "positive" | "negative" | "neutral"
  bank_strength     : "strong" | "weak"
  nifty_strength    : "strong" | "weak"
  it_strength       : "strong" | "weak"   (NASDAQ proxy for IT sector)
  volatility        : "low" | "medium" | "high"
  news_sentiment    : "positive" | "negative" | "neutral"

_raw sub-dict contains numeric values for UI transparency.
"""

from __future__ import annotations
from typing import Optional


# ── Thresholds ──────────────────────────────────────────────────────────────

BANK_NIFTY_STRENGTH_THRESHOLD = 0.3   # % move to be called "strong"
NIFTY_STRENGTH_THRESHOLD      = 0.2
NASDAQ_STRENGTH_THRESHOLD     = 0.3


def _pct_to_strength(pct: Optional[float], threshold: float) -> str:
    if pct is None:
        return "weak"
    return "strong" if pct > threshold else "weak"


# ── Public API ──────────────────────────────────────────────────────────────

def build_features(
    market_data: dict,
    global_data: dict,
    news_data:   dict,
) -> dict:
    """
    Parameters
    ----------
    market_data : output of fetch_all_market_data()
    global_data : output of fetch_all_global_data()
    news_data   : output of fetch_news_sentiment()

    Returns
    -------
    Flat feature dict ready for the decision engine.
    """

    # ── Gift NIFTY / global trend ──────────────────────────────────────────
    gift = global_data.get("gift_nifty_proxy")
    gift_nifty_trend = gift["trend"] if gift else "bearish"

    global_sentiment: str = global_data.get("global_sentiment", "neutral")

    # ── Bank NIFTY strength ────────────────────────────────────────────────
    bank_data = market_data.get("bank_nifty")
    bank_pct  = bank_data["pct_change"] if bank_data else None
    bank_strength = _pct_to_strength(bank_pct, BANK_NIFTY_STRENGTH_THRESHOLD)

    # ── NIFTY strength ─────────────────────────────────────────────────────
    nifty_data = market_data.get("nifty")
    nifty_pct  = nifty_data["pct_change"] if nifty_data else None
    nifty_strength = _pct_to_strength(nifty_pct, NIFTY_STRENGTH_THRESHOLD)

    # ── IT sector (NASDAQ proxy) ───────────────────────────────────────────
    nasdaq_data = global_data.get("nasdaq")
    nasdaq_pct  = nasdaq_data["pct_change"] if nasdaq_data else None
    it_strength = _pct_to_strength(nasdaq_pct, NASDAQ_STRENGTH_THRESHOLD)

    # ── Volatility (India VIX) ────────────────────────────────────────────
    vix_data   = market_data.get("india_vix")
    volatility = vix_data.get("volatility_level", "medium") if vix_data else "medium"

    # ── News sentiment ────────────────────────────────────────────────────
    news_sentiment: str = news_data.get("sentiment", "neutral")

    # ── USD/INR signal (rupee weakness adds bearish pressure) ─────────────
    usd_inr_data = global_data.get("usd_inr")
    rupee_pressure = False
    if usd_inr_data:
        # If USD/INR rose > 0.3% → rupee weakened → mild bearish signal
        rupee_pressure = usd_inr_data.get("pct_change", 0) > 0.3

    return {
        # ── Primary signals ─────────────────────────────────────────────
        "gift_nifty_trend": gift_nifty_trend,
        "global_sentiment": global_sentiment,
        "bank_strength":    bank_strength,
        "nifty_strength":   nifty_strength,
        "it_strength":      it_strength,
        "volatility":       volatility,
        "news_sentiment":   news_sentiment,
        "rupee_pressure":   rupee_pressure,

        # ── Raw numeric values for UI / debugging ──────────────────────
        "_raw": {
            "bank_nifty_pct":  round(bank_pct, 4)  if bank_pct  is not None else None,
            "nifty_pct":       round(nifty_pct, 4) if nifty_pct is not None else None,
            "nasdaq_pct":      round(nasdaq_pct, 4) if nasdaq_pct is not None else None,
            "vix_value":       vix_data["close"]    if vix_data  else None,
            "news_score":      news_data.get("score"),
            "bank_nifty_close": bank_data["close"]  if bank_data else None,
            "nifty_close":     nifty_data["close"]  if nifty_data else None,
        },
    }
