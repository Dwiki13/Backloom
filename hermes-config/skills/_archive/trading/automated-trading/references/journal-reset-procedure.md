# Journal Reset Procedure

## When to Reset

User may request a full or partial journal reset. Common triggers:
- "reset jurnal"
- "reset semuanya"
- "mulai dari nol"
- "reset balance jua"

## Reset Types

### Full Reset (signals + stats + balance)
User wants to start completely fresh — balance set to 0, all signals cleared, stats zeroed.

```json
{
  "account": "HFM Cent",
  "currency": "cent",
  "start_balance_cent": 0,
  "balance_cent": 0,
  "balance_start_date": "<today's date>",
  "signals": [],
  "stats": {
    "total_signals": 0,
    "wins": 0,
    "losses": 0,
    "be": 0,
    "win_rate": 0,
    "pnl_cent": 0,
    "total": 0
  }
}
```

### Signals + Stats Reset (keep balance)
User wants to clear trade history but keep current balance as starting point.

```json
{
  "start_balance_cent": <current balance>,
  "balance_cent": <current balance>,
  "balance_start_date": "<today's date>",
  "signals": [],
  "stats": {
    "total_signals": 0, "wins": 0, "losses": 0, "be": 0,
    "win_rate": 0, "pnl_cent": 0, "total": 0
  }
}
```

## Procedure

1. **Clarify scope** — confirm whether balance should be reset or kept, and if reset, to what value (0 or original starting balance).
2. **Write the new journal** via `write_file` to `/root/projects/trading/xauusd-bot/trading_journal.json`.
3. **Signal counter auto-resets** — bot uses `max(existing_ids, default=0) + 1`, so empty array → next ID = 1.
4. **Report summary** after reset: new balance, WR (0%), next signal ID (1).

## Important Notes

- `total` field in stats = `total_signals` (deprecated alias — keep in sync).
- `balance_start_date` = the reset date, not the original account opening date.
- After reset, the daily summary cron reports from the new baseline.
- Do NOT create a backup file unless user asks — old data is intentionally discarded.
