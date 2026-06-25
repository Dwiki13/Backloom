# Balance History — June 2026 Anchor Points

Key balance checkpoints established through log + journal cross-reference:

| Date | Event | Balance | Source |
|------|-------|---------|--------|
| 2026-05-27 | Deposit/start | 1000c ($10) | Bot log |
| 2026-05-28 14:00 WIB | Pre-signals (Mei) | 1447.23c | Bot log |
| 2026-05-28~29 | Signals #1-#5 (Mei) | -149.55c | Journal |
| 2026-06-01 pre-#6 | Before June signals | 1520.83c | Bot log (18:00) |
| 2026-06-01 | Signals #6-#12 | +600c | Journal |
| 2026-06-01 EOD | After June 1 signals | 2120.83c | Derived |
| 2026-06-02 | Manual profit | +62.7c | User reported |
| 2026-06-02 | Signal #13 BE | 0c | Journal |
| 2026-06-02 | Signal #14 W | +425c | User reported (actual broker) |
| 2026-06-02 NOW | Current balance | 2608.53c | User confirmed |

## Journal Schema (confirmed)

start_balance_cent: 1670.38 (= 1520.83 + 149.55 pre-June losses)
balance_cent: 2608.53 (user-confirmed)
stats.pnl_cent: 875.45 (sum all 14 closed signals)

Formula check: 1670.38 + 875.45 + 62.7 = 2608.53
