# XAUUSD Signal Bot — Setup Reference

## Bot Location
Source code: `/root/projects/trading/xauusd-bot/xauusd_multi_session.py`
Runtime data (logs, journal, signal): **same folder as source** (`/root/projects/trading/xauusd-bot/`) — `DATA_DIR` is dynamic via `os.path.dirname(__file__)`. Do NOT hardcode or copy elsewhere. The `.env` file with `TELEGRAM_BOT_TOKEN` must also be in this folder.
**Do NOT move/copy source files when KII relocates them — update paths in cron prompts instead.**

## Strategies
| Strategy | Active Hours (WIB) | Description |
|---|---|---|
| London Breakout | 15:00-22:00 | Range 15:00, breakout 16:00+ |
| NY Open Momentum | 20:00-23:00 | Follow first candle at 20:00 |
| Asian Range Breakout | 12:00-21:00 | Range 00:00-08:00, breakout during London |

## Market Structure & Trend Filter
The bot analyzes market structure from 1H candle swing highs/lows (20-candle lookback):
- **Uptrend** (HH + HL): SELL signals **blocked**
- **Downtrend** (LH + LL): BUY signals **blocked**
- **Ranging**: All signals allowed, with "hati-hati false breakout" warning

## Loss Review & Self-Correction
- `get_loss_review()`: Triggered when today has losses OR recent 5 trades have 2+ losses. Compares loss direction vs market structure (e.g., "SELL loss 3x in UPTrend → Fokus BUY").
- `get_trade_context()`: Shows last W/L, consecutive loss warnings, recent 5-trade WR%.
- Both appear in signal messages automatically when conditions are met.

## Broker Config (HFM Cent)
- SL: 100 pips | TP1: 150 pips | TP2: 200 pips
- Spread: 3.5 pips (35 pts)
- Lot: 0.01 | Balance: **2120.83 cent** (updated 2026-06-02; update manually when KII reports manual trading)
- Daily target: $1-2 (100-200 cent)
- Pip math: lot 0.01, 10 pips = 1 cent | lot 0.05, 10 pips = 5 cents

## Cron Jobs

### Signal Bot
- **Job ID**: `bef16b10e342`
- **Schedule**: `0 15,16,17,18,19,20,21,22,23 * * *` (9x/hari, WIB)
- **Delivery**: `local` (bot self-sends via `send_tg()`)
- **Telegram Target**: Topic 334 (Topic Trading) in MyAssistant24/7
- **Weekend**: Bot sends "Market closed" + structure + last trade + stats
- **Script path**: `/root/projects/trading/xauusd-bot/xauusd_multi_session.py`

### Daily Summary
- **Job ID**: `ebac7cd7fe93`
- **Schedule**: `0 0 * * *` (00:00 WIB daily)
- **Script**: `/root/projects/trading/xauusd-bot/daily_summary.py`
- **Logic**: If OPEN signals → PERINGATAN; if all closed → full recap

## Key Files
- `.env` — secret, contains `TELEGRAM_BOT_TOKEN`
- `trading_journal.json` — trade journal
- `daily_summary.py` — daily recap script
- `bot.log` — execution log

## Signal Message Format
1. Header (direction, strategy, confidence, WR%, time, source)
2. Entry/SL/TP
3. Lot ref table
4. Balance (real)
5. Setup
6. 🔮 Context (last W/L, warnings, recent WR)
7. Journal summary (Total, W/L/BE, PnL, Balance)
8. Reply instruction

## Journal Summary Format
```
📒 Journal: Total:12 W:3 L:4 BE:5 | PnL:+450c | Bal:2120.83c
```
- WR in signal header only, not in journal footer
- Balance = real balance from `C["balance_cent"]`

## Critical Rules
1. NEVER run `cronjob(action="run")` manually — duplicates signals and messes up journal
2. Bot loads `.env` explicitly
3. One journal entry per signal regardless of position count
4. Journal IDs never reset across days
5. Balance config = real balance (manual trades → config only, no journal entry)
6. Ask for per-signal breakdown if PnL totals don't match
7. User may refer to signals by chat message number, not journal ID
8. **When KII moves source files, update cron prompt paths — do NOT copy files back**
