# Trading Journal Rules for KII's XAUUSD Bot

## Canonical semantics

- **Valid journal entries:** only actual `BUY` / `SELL` signals that are meant to be tracked as trades.
- **`waiting` signals:** still sendable as signals, but not a finalized trade outcome.
- **`no entry`:** record as **BE** with **0c PnL**.
- **Manual balance updates:** update balance only; do **not** alter WR / win-loss statistics.
- **Stats source of truth:** only completed BUY/SELL entries affect WR, W/L/BE counts.
- **PnL preference:** if broker PnL is available, use that over rough estimates.

## Operational reminders

- Do not manually trigger scheduled cron runs unless the user explicitly asks.
- Avoid double-counting: if a signal was already sent by automation, do not recreate it manually.
- If the user says the signal produced no entry, log it as BE 0c rather than loss/win.
- If the user asks for a balance update, treat it as a balance-only operation unless they explicitly ask to reconcile a trade.

## Reporting style

- Keep updates short and operational.
- Report the updated balance clearly.
- If the trade outcome is ambiguous, ask for the realized outcome instead of guessing.
