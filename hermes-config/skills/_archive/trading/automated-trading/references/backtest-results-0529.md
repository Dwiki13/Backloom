# Backtest Results — ICT Default vs Bot Current Session Times

**Date:** May 29, 2026
**Data:** GC=F 1H candles, Mar 2 - May 29 2026 (75 trading days, 1427 candles)
**Lot size:** 0.01 (1 pip = 0.1c)
**Start balance:** 1447.23c ($14.47)

## Results Summary

| Metric | ICT Default | Bot Current |
|--------|------------|-------------|
| Total Signals | 84 | 85 |
| Win Rate | 29% | 24% |
| PnL | -140c (-$1.40) | -260c (-$2.60) |
| Final Balance | 1307.23c | 1187.23c |

## Per-Strategy

- ICT NY (16:30-18:00 WIB): -15c — far better than Bot NY (20:00-23:00): -205c
- Bot London (15:00-22:00 WIB): -55c — better than ICT London (09:00-12:00): -125c
- Asian: negligible in both configs

## Recommendation

**Hybrid approach**: Bot London (15-22 WIB) + ICT NY (16:30-18:00 WIB)
- Projected PnL: ~-70c instead of -260c (73% improvement)

## Caveats

- Simplified simulation (no spread, slippage, partial TP)
- WR 24-29% with 1:1.5 RR requires >40% WR to break even
- Consider: tighter filters, confluence requirements, or wider SL
