# Trading Journal — JSON Schema

## PnL Math (HFM Cent, pip_value_001 = 0.1)

Formula: `pnl_cent = (lot / 0.01) x pips x 0.1`

| Lot | SL (100p) | TP1 (150p) | TP2 (200p) |
|---|---|---|---|
| 0.01 | 10c | 15c | 20c |
| 0.05 | 50c | 75c | 100c |
| 0.10 | 100c | 150c | 200c |

## Balance Timeline

| Date | Balance (cent) | Notes |
|---|---|---|
| Pre-28 Mei | 1917.53 | Start |
| After 29 Mei | 1767.98 | User-confirmed |
| Current | 1520.83 | Real (incl manual) |

## Signal History

### 28 Mei 2026
- #1 London Breakout BUY | L | -49.7c
- #2 London Breakout SELL | L | -95.8c

### 29 Mei 2026
- #3 London Breakout SELL | L | -131.4c
- #4 NY Open BUY | W | +127.35c
- #5 NY Open BUY | BE | 0c (no entry)

### 1 Juni 2026
- #6 London Breakout SELL | L | -200c (4 pos x 0.05 SL)
- #7 London Breakout SELL | W | +100c (2W TP2 + 2L SL, 0.05)
- #8 London Breakout SELL | W | adjusted (partial TP)
- #9 London Breakout SELL | W | adjusted (partial TP)
