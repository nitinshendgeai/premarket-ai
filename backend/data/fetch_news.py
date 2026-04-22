"""
data/fetch_news.py
──────────────────
Fetches financial headlines from free public RSS feeds and derives
a sentiment signal using keyword scoring.

Sources (no API key needed):
  • Economic Times Markets RSS
  • Moneycontrol Market Reports RSS
  • LiveMint Markets RSS

Sentiment logic:
  Each headline is scored +1 (bullish) / -1 (bearish) / 0 (neutral).
  Net score ≥ +2  → sentiment = "positive"
  Net score ≤ -2  → sentiment = "negative"
  Else            → sentiment = "neutral"
"""

from __future__ import annotations
import requests
from bs4 import BeautifulSoup
from typing import Optional


# ── Config ─────────────────────────────────────────────────────────────────

RSS_FEEDS: dict[str, str] = {
    "economic_times": "https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms",
    "moneycontrol":   "https://www.moneycontrol.com/rss/marketreports.xml",
    "livemint":       "https://www.livemint.com/rss/markets",
}

REQUEST_TIMEOUT = 8  # seconds per feed

BULLISH_KEYWORDS = {
    "rally", "surge", "gain", "rise", "jump", "positive", "bullish",
    "record high", "strong", "recovery", "uptick", "advance", "green",
    "boost", "optimism", "outperform", "beat", "rebound", "soar",
}

BEARISH_KEYWORDS = {
    "fall", "drop", "decline", "crash", "sell-off", "bearish", "weak",
    "loss", "slump", "pressure", "recession", "plunge", "red", "tumble",
    "drag", "fear", "concern", "miss", "underperform", "cut", "risk",
}


# ── Internal helpers ───────────────────────────────────────────────────────

def _parse_rss(url: str, max_items: int = 12) -> list[str]:
    """Fetch an RSS feed and return a list of headline strings."""
    try:
        resp = requests.get(
            url,
            timeout=REQUEST_TIMEOUT,
            headers={"User-Agent": "Mozilla/5.0 (compatible; TradingBot/1.0)"},
        )
        resp.raise_for_status()

        # Try lxml parser first, fall back to html.parser
        try:
            soup = BeautifulSoup(resp.content, "lxml-xml")
        except Exception:
            soup = BeautifulSoup(resp.content, "html.parser")

        items = soup.find_all("item")[:max_items]
        return [item.find("title").text.strip() for item in items if item.find("title")]
    except Exception as exc:
        print(f"[fetch_news] RSS error ({url}): {exc}")
        return []


def _score_headline(text: str) -> int:
    """Score a single headline: +1 bullish, -1 bearish, 0 neutral."""
    lower = text.lower()
    is_bull = any(kw in lower for kw in BULLISH_KEYWORDS)
    is_bear = any(kw in lower for kw in BEARISH_KEYWORDS)
    if is_bull and not is_bear:
        return 1
    if is_bear and not is_bull:
        return -1
    return 0


# ── Public API ─────────────────────────────────────────────────────────────

def fetch_news_sentiment() -> dict:
    """
    Aggregate news from all RSS sources.

    Returns:
      sentiment    → "positive" | "negative" | "neutral"
      score        → net integer score
      headlines    → top 6 headlines for UI display
      scored_count → number of headlines that had a clear sentiment
      sources_ok   → number of RSS feeds that responded
    """
    all_headlines: list[str] = []
    sources_ok = 0

    for name, url in RSS_FEEDS.items():
        batch = _parse_rss(url)
        if batch:
            all_headlines.extend(batch)
            sources_ok += 1

    if not all_headlines:
        return {
            "sentiment":    "neutral",
            "score":        0,
            "headlines":    [],
            "scored_count": 0,
            "sources_ok":   0,
            "error":        "No headlines fetched — all RSS feeds failed",
        }

    scores      = [_score_headline(h) for h in all_headlines]
    net_score   = sum(scores)
    scored_count = sum(1 for s in scores if s != 0)

    if net_score >= 2:
        sentiment = "positive"
    elif net_score <= -2:
        sentiment = "negative"
    else:
        sentiment = "neutral"

    return {
        "sentiment":    sentiment,
        "score":        net_score,
        "headlines":    all_headlines[:6],
        "scored_count": scored_count,
        "sources_ok":   sources_ok,
    }
