"""
data/fetch_market.py
────────────────────
Fetches Indian market data via yfinance:
  • NIFTY 50     → ^NSEI
  • BANK NIFTY   → ^NSEBANK
  • INDIA VIX    → ^INDIAVIX

Each function returns a typed dict or None on failure.
All callers must handle None gracefully.
"""

from __future__ import annotations
import yfinance as yf
from typing import Optional


# ── Internal helper ────────────────────────────────────────────────────────

def _download_ohlc(ticker: str, period: str = "5d") -> Optional[dict]:
    """
    Download last N days of daily OHLC for *ticker*.
    Returns a dict with close, prev_close, pct_change, trend — or None.
    """
    try:
        df = yf.download(
            ticker,
            period=period,
            interval="1d",
            progress=False,
            auto_adjust=True,
        )
        if df is None or df.empty or len(df) < 2:
            print(f"[fetch_market] Insufficient data for {ticker}")
            return None

        close_now  = float(df["Close"].iloc[-1])
        close_prev = float(df["Close"].iloc[-2])
        pct        = (close_now - close_prev) / close_prev * 100

        return {
            "ticker":      ticker,
            "close":       round(close_now, 2),
            "prev_close":  round(close_prev, 2),
            "pct_change":  round(pct, 4),
            "open":        round(float(df["Open"].iloc[-1]), 2),
            "high":        round(float(df["High"].iloc[-1]), 2),
            "low":         round(float(df["Low"].iloc[-1]), 2),
            "trend":       "bullish" if pct > 0 else "bearish",
        }
    except Exception as exc:
        print(f"[fetch_market] Error fetching {ticker}: {exc}")
        return None


# ── Public API ─────────────────────────────────────────────────────────────

def fetch_nifty() -> Optional[dict]:
    """NIFTY 50 data."""
    return _download_ohlc("^NSEI")


def fetch_bank_nifty() -> Optional[dict]:
    """BANK NIFTY data."""
    return _download_ohlc("^NSEBANK")


def fetch_india_vix() -> Optional[dict]:
    """
    India VIX data with volatility level classification.
      VIX > 20  → high
      VIX 15-20 → medium
      VIX < 15  → low
    """
    data = _download_ohlc("^INDIAVIX")
    if data:
        vix = data["close"]
        if vix > 20:
            level = "high"
        elif vix > 15:
            level = "medium"
        else:
            level = "low"
        data["volatility_level"] = level
    return data


def fetch_all_market_data() -> dict:
    """
    Aggregate all domestic market data.
    Returns dict with keys: nifty, bank_nifty, india_vix.
    Values are either the data dict or None.
    """
    return {
        "nifty":      fetch_nifty(),
        "bank_nifty": fetch_bank_nifty(),
        "india_vix":  fetch_india_vix(),
    }
