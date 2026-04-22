"""
api/routes.py
─────────────
FastAPI router with the main pre-market analysis endpoint.

GET /premarket-analysis
  → Runs the full pipeline and returns structured JSON.

GET /health
  → Lightweight ping.
"""

from __future__ import annotations

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional

from data.fetch_market         import fetch_all_market_data
from data.fetch_global         import fetch_all_global_data
from data.fetch_news           import fetch_news_sentiment
from features.feature_engine   import build_features
from decision.scoring          import compute_decision
from options.strategy_selector import select_index, select_strategy
from options.strike_selector   import get_atm_strike
from options.risk_manager      import get_risk_parameters

router = APIRouter()


# ── Pydantic response models ───────────────────────────────────────────────

class StrikeInfo(BaseModel):
    strike_label: str
    strike_value: Optional[int]
    step:         int
    note:         str

class RiskInfo(BaseModel):
    stop_loss_pct: Optional[int]
    target_pct:    Optional[int]
    note:          str
    advice:        Optional[str]
    time_exit:     str

class MarketSnapshot(BaseModel):
    close:      Optional[float]
    pct_change: Optional[float]
    trend:      Optional[str]

class PremarketResponse(BaseModel):
    # ── Core decision ──────────────────────────────────────────────────────
    bias:       str = Field(..., description="bullish | bearish | sideways")
    confidence: int = Field(..., ge=0, le=100)
    index:      str = Field(..., description="NIFTY 50 | BANK NIFTY")
    strategy:   str = Field(..., description="Buy CE | Buy PE | Avoid")
    strike:     StrikeInfo
    risk:       RiskInfo
    reason:     str = Field(..., description="Human-readable reasoning")

    # ── Supporting context ────────────────────────────────────────────────
    top_headlines:   list[str]
    features:        dict
    score_buckets:   dict
    raw_market:      dict


# ── Pipeline helper ────────────────────────────────────────────────────────

def _run_pipeline() -> PremarketResponse:
    """Execute the full analysis pipeline. Raises on critical failures."""

    # 1 ── Fetch all raw data (errors handled internally; returns None fields)
    market_data = fetch_all_market_data()
    global_data = fetch_all_global_data()
    news_data   = fetch_news_sentiment()

    # 2 ── Feature engineering
    features = build_features(market_data, global_data, news_data)

    # 3 ── Decision engine
    decision   = compute_decision(features)
    bias       = decision["bias"]
    confidence = decision["confidence"]
    reasons    = decision["reasons"]

    # 4 ── Options logic
    index = select_index(features)
    strategy, strategy_reason = select_strategy(bias, confidence)

    # Spot price for strike calculation (use previous close as proxy)
    spot_price: Optional[float] = None
    if index == "BANK NIFTY":
        bn = market_data.get("bank_nifty")
        spot_price = bn["close"] if bn else None
    else:
        ni = market_data.get("nifty")
        spot_price = ni["close"] if ni else None

    strike = get_atm_strike(index, spot_price)
    risk   = get_risk_parameters(strategy, features.get("volatility", "medium"))

    # 5 ── Compose human-readable reasoning
    all_reasons = reasons + [strategy_reason]
    reason_text = "; ".join(all_reasons)

    # 6 ── Raw market snapshot for UI ticker
    def _snap(d: Optional[dict]) -> dict:
        if not d:
            return {"close": None, "pct_change": None, "trend": None}
        return {
            "close":      d.get("close"),
            "pct_change": d.get("pct_change"),
            "trend":      d.get("trend"),
        }

    raw_market = {
        "nifty":      _snap(market_data.get("nifty")),
        "bank_nifty": _snap(market_data.get("bank_nifty")),
        "india_vix":  _snap(market_data.get("india_vix")),
        "sp500":      _snap(global_data.get("sp500")),
        "nasdaq":     _snap(global_data.get("nasdaq")),
    }

    # Strip _raw from features for cleaner response
    public_features = {k: v for k, v in features.items() if k != "_raw"}

    return PremarketResponse(
        bias=bias,
        confidence=confidence,
        index=index,
        strategy=strategy,
        strike=StrikeInfo(**strike),
        risk=RiskInfo(**risk),
        reason=reason_text,
        top_headlines=news_data.get("headlines", []),
        features=public_features,
        score_buckets=decision.get("score_buckets", {}),
        raw_market=raw_market,
    )


# ── Endpoints ──────────────────────────────────────────────────────────────

@router.get(
    "/premarket-analysis",
    response_model=PremarketResponse,
    tags=["Analysis"],
    summary="Run full pre-market analysis",
)
def premarket_analysis():
    """
    Executes the complete pre-market pipeline:
    fetch data → engineer features → score bias → select options strategy.

    Typical latency: 5–15 seconds (dominated by yfinance + RSS calls).
    """
    try:
        return _run_pipeline()
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Analysis pipeline failed: {str(exc)}",
        )
