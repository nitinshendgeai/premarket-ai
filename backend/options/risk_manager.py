"""
options/risk_manager.py
───────────────────────
Provides risk management parameters for the selected strategy.

Base parameters (options buying):
  Stop Loss : 25% of premium paid
  Target    : 50% of premium paid

VIX-adjusted parameters:
  High VIX  → SL 20%, Target 40%  (markets erratic — tighter params)
  Low VIX   → SL 25%, Target 60%  (calm market — let profits run)
  Medium    → SL 25%, Target 50%  (standard)

Time-based exit:
  If target / SL not hit by 11:30 AM IST, exit and re-evaluate.
"""

from __future__ import annotations
from typing import Optional


def get_risk_parameters(strategy: str, volatility: str) -> dict:
    """
    Parameters
    ----------
    strategy   : "Buy CE" | "Buy PE" | "Avoid"
    volatility : "low" | "medium" | "high"

    Returns
    -------
    {
      stop_loss_pct  : int | None
      target_pct     : int | None
      note           : str
      advice         : str | None
      time_exit      : str
    }
    """
    if strategy == "Avoid":
        return {
            "stop_loss_pct": None,
            "target_pct":    None,
            "note":          "No trade — risk parameters not applicable",
            "advice":        None,
            "time_exit":     "N/A",
        }

    if volatility == "high":
        sl_pct, tgt_pct = 20, 40
        note = "High VIX: tighter stop-loss, conservative target"
    elif volatility == "low":
        sl_pct, tgt_pct = 25, 60
        note = "Low VIX: standard SL, extended target as trend likely to hold"
    else:
        sl_pct, tgt_pct = 25, 50
        note = "Standard risk profile for medium volatility"

    advice = (
        f"Enter at market open (9:15 AM). "
        f"Exit immediately if premium drops {sl_pct}% from entry price. "
        f"Book full profit at {tgt_pct}% gain. "
        f"Time-based exit: close position by 11:30 AM IST if neither level hit."
    )

    return {
        "stop_loss_pct": sl_pct,
        "target_pct":    tgt_pct,
        "note":          note,
        "advice":        advice,
        "time_exit":     "11:30 AM IST",
    }
