"""
decision/scoring.py
───────────────────
Aggregates rule votes into a final market bias and confidence score.

Scoring model
─────────────
1. Each rule contributes its weight to one of three buckets:
     {"bullish": int, "bearish": int, "sideways": int}

2. Winning bias = bucket with the highest total weight.

3. Confidence formula:
     raw_conf = (winner_pts / total_pts) * 100
     Clamped to [MIN_CONF, MAX_CONF] = [30, 95]

4. Conflict dampening:
     If (winner - second_place) < CONFLICT_THRESHOLD (=12 pts),
     confidence is reduced by 12 and bias is overridden to "sideways"
     (the market is too contested to trade directionally).

5. VIX override:
     If volatility = "high", cap confidence at 55 — erratic markets
     are inherently hard to predict.
"""

from __future__ import annotations
from decision.rules import evaluate_all_rules, RuleResult


# ── Tuning constants ────────────────────────────────────────────────────────
MIN_CONFIDENCE       = 30
MAX_CONFIDENCE       = 95
VIX_HIGH_CONF_CAP   = 55
CONFLICT_THRESHOLD  = 12   # pts gap below which we call it "sideways"


# ── Public API ──────────────────────────────────────────────────────────────

def compute_decision(features: dict) -> dict:
    """
    Run all rules and produce the final bias + confidence decision.

    Parameters
    ----------
    features : output of build_features()

    Returns
    -------
    {
      bias          : str
      confidence    : int (0-100)
      reasons       : list[str]   — reasons for the winning bias
      all_rules     : list[dict]  — full rule breakdown for debugging
      score_buckets : dict        — raw points per bias
    }
    """
    rules: list[RuleResult] = evaluate_all_rules(features)

    # ── Accumulate score buckets ───────────────────────────────────────────
    buckets: dict[str, int]        = {"bullish": 0, "bearish": 0, "sideways": 0}
    reason_map: dict[str, list[str]] = {"bullish": [], "bearish": [], "sideways": []}

    for rule in rules:
        buckets[rule.bias_vote]    += rule.weight
        reason_map[rule.bias_vote].append(rule.reason)

    total_pts = sum(buckets.values())

    # ── Edge case: no rules fired ──────────────────────────────────────────
    if total_pts == 0:
        return {
            "bias":          "sideways",
            "confidence":    MIN_CONFIDENCE,
            "reasons":       ["No strong directional signal — defaulting to Sideways"],
            "all_rules":     [],
            "score_buckets": buckets,
        }

    # ── Determine winner ───────────────────────────────────────────────────
    sorted_biases = sorted(buckets.keys(), key=lambda k: buckets[k], reverse=True)
    winner        = sorted_biases[0]
    runner_up     = sorted_biases[1]

    winner_pts    = buckets[winner]
    runner_up_pts = buckets[runner_up]
    margin        = winner_pts - runner_up_pts

    # ── Compute raw confidence ─────────────────────────────────────────────
    # Normalise against max possible (arbitrary cap at 100)
    raw_conf   = (winner_pts / max(total_pts, 100)) * 100
    confidence = int(max(MIN_CONFIDENCE, min(MAX_CONFIDENCE, raw_conf)))

    # ── Conflict dampening ─────────────────────────────────────────────────
    if margin < CONFLICT_THRESHOLD:
        winner      = "sideways"
        confidence  = max(MIN_CONFIDENCE, confidence - 12)

    # ── VIX override ───────────────────────────────────────────────────────
    if features.get("volatility") == "high":
        confidence = min(confidence, VIX_HIGH_CONF_CAP)

    # ── Compile reasons for winning bias ───────────────────────────────────
    final_reasons = reason_map.get(winner, [])
    if not final_reasons:
        final_reasons = ["Conflicting signals — market direction unclear"]

    return {
        "bias":          winner,
        "confidence":    confidence,
        "reasons":       final_reasons,
        "all_rules":     [r._asdict() for r in rules],
        "score_buckets": buckets,
    }
