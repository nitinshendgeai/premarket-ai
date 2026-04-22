"""
data/fetch_global.py
────────────────────
Fetches global market data that drives Indian pre-market sentiment:
  • S&P 500   → ^GSPC
  • NASDAQ    → ^IXIC
  • Dow Jones → ^DJI
  • USD/INR   → INR=X  (rupee strength context)

GIFT NIFTY note:
  Real GIFT NIFTY requires NSE/broker API access.
  We proxy it via S&P 500 direction (strong ≥ 70% correlation).
  Replace `fetch_gift_nifty_proxy` with a real feed in production.
"""

from __future__ import annotations
import yfinance as yf
from typing import Optional


def _download(ticker: str, period: str = "5d") -> Optional[dict]:
    try:
        df = yf.download(ticker, period=period, interval="1d",
                         progress=False, auto_adjust=True)
        if df is None or df.empty or len(df) < 2:
            return None

        close_now  = float(df["Close"].iloc[-1])
        close_prev = float(df["Close"].iloc[-2])
        pct        = (close_now - close_prev) / close_prev * 100

        return {
            "ticker":     ticker,
            "close":      round(close_now, 2),
            "prev_close": round(close_prev, 2),
            "pct_change": round(pct, 4),
            "trend":      "bullish" if pct > 0 else "bearish",
        }
    except Exception as exc:
        print(f"[fetch_global] Error fetching {ticker}: {exc}")
        return None


def fetch_sp500() -> Optional[dict]:
    return _download("^GSPC")


def fetch_nasdaq() -> Optional[dict]:
    return _download("^IXIC")


def fetch_dow() -> Optional[dict]:
    return _download("^DJI")


def fetch_usd_inr() -> Optional[dict]:
    """USD/INR exchange rate — higher value = weaker rupee = mild bearish bias."""
    return _download("INR=X")


def fetch_gift_nifty_proxy() -> Optional[dict]:
    """
    Proxy for GIFT NIFTY using S&P 500 direction.
    TODO: Replace with real GIFT NIFTY feed (NSE API / broker WebSocket).
    """
    sp = fetch_sp500()
    if sp:
        sp["is_proxy"] = True
        sp["proxy_note"] = "GIFT NIFTY proxied via S&P 500 — replace with real feed"
    return sp


def fetch_all_global_data() -> dict:
    """
    Returns aggregated global data + composite sentiment signal.

    Composite sentiment logic:
      • Count bullish vs bearish across SP500 / NASDAQ / Dow
      • Majority wins → global_sentiment = "positive" | "negative"
    """
    sp500  = fetch_sp500()
    nasdaq = fetch_nasdaq()
    dow    = fetch_dow()
    gift   = fetch_gift_nifty_proxy()
    usd_inr = fetch_usd_inr()

    indices = [sp500, nasdaq, dow]
    trends  = [d["trend"] for d in indices if d is not None]
    bullish_count = trends.count("bullish")

    if not trends:
        global_sentiment = "neutral"
    elif bullish_count >= 2:
        global_sentiment = "positive"
    else:
        global_sentiment = "negative"

    # Weighted breakdown for transparency
    score_detail = {
        "sp500_trend":  sp500["trend"]  if sp500  else "unknown",
        "nasdaq_trend": nasdaq["trend"] if nasdaq else "unknown",
        "dow_trend":    dow["trend"]    if dow    else "unknown",
        "bullish_count": bullish_count,
        "total_signals": len(trends),
    }

    return {
        "sp500":             sp500,
        "nasdaq":            nasdaq,
        "dow":               dow,
        "gift_nifty_proxy":  gift,
        "usd_inr":           usd_inr,
        "global_sentiment":  global_sentiment,
        "score_detail":      score_detail,
    }
