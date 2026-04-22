"""
options/strike_selector.py
──────────────────────────
Calculates the At-The-Money (ATM) strike price for the selected index.

Strike rounding conventions
───────────────────────────
  NIFTY 50   → nearest 50 points
  BANK NIFTY → nearest 100 points

If live spot price is unavailable, returns "ATM" as a label with a
note to use the live strike at market open (9:15 AM IST).
"""

from __future__ import annotations
from typing import Optional


STRIKE_STEPS: dict[str, int] = {
    "NIFTY 50":   50,
    "BANK NIFTY": 100,
}


def _round_to_step(price: float, step: int) -> int:
    """Round price to the nearest multiple of step."""
    return int(round(price / step) * step)


def get_atm_strike(index: str, spot_price: Optional[float]) -> dict:
    """
    Parameters
    ----------
    index       : "NIFTY 50" or "BANK NIFTY"
    spot_price  : latest known index level (close price)

    Returns
    -------
    {
      strike_label : display string  (e.g. "ATM ~24600")
      strike_value : int | None
      step         : int
      note         : explanation string
    }
    """
    step = STRIKE_STEPS.get(index, 100)

    if spot_price is None:
        return {
            "strike_label": "ATM",
            "strike_value": None,
            "step":         step,
            "note":         (
                f"Live spot unavailable — identify ATM strike "
                f"(nearest {step}) at market open (9:15 AM IST)"
            ),
        }

    atm = _round_to_step(spot_price, step)

    return {
        "strike_label": f"ATM ~{atm:,}",
        "strike_value": atm,
        "step":         step,
        "note":         (
            f"Rounded to nearest {step} from yesterday's close "
            f"{spot_price:,.2f}. Verify ATM at 9:15 AM."
        ),
    }
