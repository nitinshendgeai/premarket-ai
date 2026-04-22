"""
decision/rules.py
─────────────────
Rule-based logic that maps feature signals to bias votes.

Each rule returns a RuleResult namedtuple:
  bias_vote  : "bullish" | "bearish" | "sideways"
  weight     : int (points contributed to bias bucket)
  reason     : human-readable explanation string
  rule_name  : identifier for debugging

Rules are ADDITIVE — all matching rules fire and contribute to scoring.
The scoring engine aggregates them into a final bias + confidence.

Weight scale:
  25 → strong corroborating signal (global + domestic aligned)
  20 → major single-factor signal
  15 → moderate supporting signal
  10 → minor supporting signal
   8 → weak signal or sector-specific
   5 → tiebreaker / tertiary signal
"""

from __future__ import annotations
from typing import NamedTuple


class RuleResult(NamedTuple):
    bias_vote: str   # "bullish" | "bearish" | "sideways"
    weight:    int
    reason:    str
    rule_name: str


def evaluate_all_rules(features: dict) -> list[RuleResult]:
    """
    Evaluate every trading rule against the current feature set.
    Returns list of all RuleResult objects for matching rules.
    """
    results: list[RuleResult] = []
    r = results.append  # alias for brevity

    # ── Unpack features ────────────────────────────────────────────────────
    g   = features.get("global_sentiment", "neutral")
    gn  = features.get("gift_nifty_trend", "bearish")
    bs  = features.get("bank_strength", "weak")
    ns  = features.get("nifty_strength", "weak")
    its = features.get("it_strength", "weak")
    vx  = features.get("volatility", "medium")
    nw  = features.get("news_sentiment", "neutral")
    rp  = features.get("rupee_pressure", False)

    # ══════════════════════════════════════════════════════════════════════
    # BULLISH RULES
    # ══════════════════════════════════════════════════════════════════════

    # Rule B1 — Core bullish: global + banking aligned
    if g == "positive" and bs == "strong":
        r(RuleResult("bullish", 25,
            "Global markets positive AND banking sector strong",
            "B1_global_bank_aligned"))

    # Rule B2 — GIFT NIFTY leading indicator bullish
    if gn == "bullish" and g == "positive":
        r(RuleResult("bullish", 20,
            "GIFT NIFTY bullish aligned with positive global close",
            "B2_gift_global"))

    # Rule B3 — Domestic broad market strength
    if ns == "strong" and bs == "strong":
        r(RuleResult("bullish", 15,
            "Both NIFTY 50 and BANK NIFTY showing broad strength",
            "B3_broad_domestic"))

    # Rule B4 — News supports direction
    if nw == "positive" and g == "positive":
        r(RuleResult("bullish", 10,
            "Financial news sentiment positive, confirms global trend",
            "B4_news_confirms_global"))

    # Rule B5 — IT / tech sector leading (NASDAQ proxy)
    if its == "strong" and g == "positive":
        r(RuleResult("bullish", 8,
            "IT sector (NASDAQ proxy) strong — FII interest expected",
            "B5_it_sector"))

    # Rule B6 — Low VIX supports trend continuation
    if vx == "low" and g == "positive":
        r(RuleResult("bullish", 5,
            "India VIX low — calm environment supports bullish trend",
            "B6_low_vix_bullish"))

    # Rule B7 — GIFT NIFTY solo signal
    if gn == "bullish" and g != "positive":
        r(RuleResult("bullish", 8,
            "GIFT NIFTY indicating bullish open despite mixed global cues",
            "B7_gift_solo"))

    # ══════════════════════════════════════════════════════════════════════
    # BEARISH RULES
    # ══════════════════════════════════════════════════════════════════════

    # Rule R1 — Core bearish: global + banking both weak
    if g == "negative" and bs == "weak":
        r(RuleResult("bearish", 25,
            "Global markets negative AND banking sector weak",
            "R1_global_bank_weak"))

    # Rule R2 — GIFT NIFTY leading indicator bearish
    if gn == "bearish" and g == "negative":
        r(RuleResult("bearish", 20,
            "GIFT NIFTY bearish aligned with negative global close",
            "R2_gift_global_bear"))

    # Rule R3 — Domestic broad weakness
    if ns == "weak" and bs == "weak":
        r(RuleResult("bearish", 15,
            "Both NIFTY 50 and BANK NIFTY showing broad weakness",
            "R3_broad_domestic_weak"))

    # Rule R4 — Bearish news reinforcing
    if nw == "negative" and g == "negative":
        r(RuleResult("bearish", 10,
            "Financial news bearish, reinforces global sell-off",
            "R4_news_bear"))

    # Rule R5 — Rupee under pressure adds bearish weight
    if rp and g == "negative":
        r(RuleResult("bearish", 8,
            "USD/INR rising (rupee weak) — FII outflow risk",
            "R5_rupee_pressure"))

    # Rule R6 — High VIX → fear in market
    if vx == "high" and g == "negative":
        r(RuleResult("bearish", 8,
            "India VIX elevated with global weakness — fear dominant",
            "R6_high_vix_bear"))

    # ══════════════════════════════════════════════════════════════════════
    # SIDEWAYS / CONFLICT RULES
    # ══════════════════════════════════════════════════════════════════════

    # Rule S1 — High VIX alone → uncertainty regardless of direction
    if vx == "high":
        r(RuleResult("sideways", 12,
            "India VIX elevated — high uncertainty, prefer to avoid",
            "S1_high_vix"))

    # Rule S2 — Mixed signals: global positive but domestic weak
    if g == "positive" and bs == "weak" and ns == "weak":
        r(RuleResult("sideways", 10,
            "Global positive but domestic indices both weak — divergence",
            "S2_global_domestic_diverge"))

    # Rule S3 — Mixed: global negative but domestic holding
    if g == "negative" and bs == "strong":
        r(RuleResult("sideways", 8,
            "Global negative but banking resilient — mixed signals",
            "S3_defensive_banking"))

    # Rule S4 — Neutral news with no clear global direction
    if nw == "neutral" and g == "neutral":
        r(RuleResult("sideways", 5,
            "No clear directional signal from news or global markets",
            "S4_no_direction"))

    return results
