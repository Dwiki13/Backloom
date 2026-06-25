# Session Learnings — June 1, 2026

## Telegram Topic Delivery Fix

**Problem:** `send_tg()` was sending to General chat instead of Topic Trading.

**Root cause:** `message_thread_id` was appended to `chat_id` as `"-1003966561389:334"`. Telegram API ignores the `:334` suffix and sends to the default topic.

**Fix:** Parse `chat_id` and `message_thread_id` separately:
```python
params = {"chat_id": chat_id, "text": msg}
if ":" in str(chat_id):
    parts = str(chat_id).split(":", 1)
    params["chat_id"] = parts[0]
    params["message_thread_id"] = parts[1]
```

**Delivery format that works:** `telegram:MyAssistant24/7 / topic 334` (Hermes auto-resolves to chat_id `-1003966561389`)

## .env File Loading

**Problem:** `TELEGRAM_BOT_TOKEN` was always empty despite `.env` file existing.

**Root cause:** `os.environ.get()` reads system env vars, NOT `.env` files.

**Fix:** Added manual `.env` parser in bot script.

## Cron Duplicate Signals

**Problem:** Agent manually triggered `cronjob run` multiple times during debugging, causing duplicate signals.

**Rule:** NEVER manually trigger cron during live trading. Only for code testing.

## Journal ID Continuity

Signal IDs must NEVER reset to #1 on a new day. Always continue from last ID.

## Balance Reconciliation Formula

`start_balance_cent = KII_reported_actual_balance - stats.pnl_cent`

## Daily Recap Cron

New cron: `XAUUSD Daily Recap` at `0 23 * * *` WIB → Topic Trading

## Multi-Position PnL Pattern

For lot 0.05, SL=100p, TP2=200p:
- W TP2: (0.05/0.01) × 200 × 0.1 = +100c
- L SL:  (0.05/0.01) × 100 × 0.1 = -50c
