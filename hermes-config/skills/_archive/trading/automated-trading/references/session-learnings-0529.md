# Session Learnings — May 29 2026

## Key Corrections from KII

### Win Rate Calculation — Per Signal (NOT Per Position)
- KII counts 1 signal = 1 trade, regardless of how many positions
- Signal with 3 positions all W = 1 Win (not 3 wins)
- 4 signals total, 1W 3L = 25% WR
- Stats JSON wins/losses are per-signal counts

### Stats Format (Updated)
Use total_signals (not total). fmt_journal_summary() must handle both keys.
```json
{
  "total_signals": 4,
  "wins": 1,
  "losses": 3,
  "be": 0,
  "win_rate": 25,
  "pnl_cent": -149.55
}
```

### Multi-Position Update Protocol
1. KII reports incrementally: "pos 1 W +64.10", later "pos 2 W +55.95", etc.
2. Add each to positions[] array as info arrives
3. signal_pnl = running sum
4. Set signal W/L/BE only when ALL positions reported
5. Remove signal entries KII did not trade

### KII Report Parser
- "L 0.05 Entry Price 4522.82 SL 4531.98 LOSS -45.80c"
- "W 0.05 Entry Price 4537.78 TP1 +64.10c"
- "BE 0.05 Entry Price 4537.30 BE Price 4538.76 +7.30c"

### Balance (May 29 2026 EOD)
- HFM: 1767.98c ($17.68)
- Bot PnL: -149.55c (4 signals)
- Manual: +470.20c (not tracked)
- Start: 1447.23c (2026-05-28)

### Cron Delivery — Known Broken
- Agent-based: agent adds meta-text → format kacau
- Shell+curl: token auto-masked → can't send
- Workaround: run manual when KII asks

### Market Structure Filter — Active
analyze_market_structure() → filter_by_trend() → get_loss_review()
- Blocks SELL in uptrend (HH+HL)
- Blocks BUY in downtrend (LH+LL)
- Loss review appended when >=2 recent losses same direction