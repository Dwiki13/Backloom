# Balance Calculation — Lessons Learned (June 2, 2026)

## The Bug

Daily summary was computing balance as:
```
balance = start_balance_cent + signal_pnl
```

This gave wrong results because:
1. `start_balance_cent` was incorrectly set (included manual profits that weren't tracked through signals)
2. Manual profits don't go through signal entries — they're direct balance adjustments
3. The computed value didn't match actual broker balance

## The Fix

Daily summary now reads `j['balance_cent']` directly from journal as source of truth:
```python
bal = j.get('balance_cent', j.get('start_balance_cent', 0) + st['pnl_cent'])
```

## Balance Tracking Rules

1. **`balance_cent` in journal = source of truth** — must always match actual broker balance
2. When user reports manual profit/loss: update `balance_cent` directly in journal AND `C['balance_cent']` in script config
3. Manual profits do NOT create journal signal entries and do NOT affect WR/stats
4. Signal PnL is tracked through journal entries and summed in `stats['pnl_cent']`
5. **Always ask user for actual broker balance** when there's a discrepancy — don't try to compute from components

## Verified Balance Flow (June 2, 2026)

| Date | Event | Balance |
|---|---|---|
| June 1 pre-signals | Bot log shows | 1520.83c |
| June 1 signals #6-#12 | -200 + 100 + 700 = +600c | 2120.83c |
| Manual profit | +62.7c | 2183.53c |
| June 2 signal #13 | 0c (BE no entry) | 2183.53c |
| June 2 signal #14 | +425c (3xTP1 + 2xTP2, 5 pos lot 0.05) | 2608.53c |

## start_balance_cent

Set to **1520.83** (June 1 pre-signal balance, verified from bot log).

Note: Signals #1-#5 (May 28-29) had PnL of -149.55c which was already realized in broker before June 1, so 1520.83 already includes those losses.
