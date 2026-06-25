# June 2, 2026 Session — Key Learnings

## Balance Tracking Correction

User reported signal #14 actual PnL = +425c (broker confirmed), not +408c (theoretical calculation).
Also has previous manual profit = +62.7c.

Correct formula: `balance = start_balance + signal_pnl + manual_profit`
- Start: 2120.83c
- Signal PnL (all 14 closed): +875.45c (including #14 at +425c)
- Manual: +62.7c
- **Total: 3058.98c**

Lesson: Always use user-reported broker PnL, never re-calculate theoretically.

## daily_summary.py Fixes Applied

1. **DATA_DIR hardcoded** — Was `/root/xauusd-bot`, changed to `os.path.dirname(os.path.abspath(__file__))`
2. **Stats field names wrong** — Referenced `st["total_signals"]` and `st["win_rate"]` which don't exist. Fixed to calculate manually.
3. **Strategy breakdown added** — Added per-strategy W/L/BE/PnL section.

## Trend Filter Decision

- **User decision: Revert to NO trend filter (June 1 style)**
- Counter-trend signals were profitable on June 1 (+700c SELL in uptrend)
- Pending: min range filter + consecutive loss protection (discussed, not yet applied)

## Stats Field Reference

Journal schema: `total_signals` (or `total`), `wins`, `losses`, `be`, `pnl_cent`
WR calculated manually: `wins / (wins + losses) * 100`
