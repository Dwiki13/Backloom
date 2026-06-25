---
name: automated-trading
description: Build and operate automated forex/crypto trading systems — signal bots, MT5 EAs, Telegram alerts, Python auto-execution, and XAUUSD bot journal/ops management. Covers XAUUSD/gold analysis, HFM/Exness brokers, MT5 via Wine on Linux VPS, yfinance data pipelines, risk management, strategy backtesting, and operational journal/balance workflow. Use when the user wants to build, debug, deploy, or operate any trading bot or signal system.
triggers:
  - trading bot
  - forex bot
  - auto trade
  - EA MT5
  - signal bot
  - XAUUSD
  - gold trading
  - MetaTrader 5
  - trading signal
  - auto execute trade
---

# Automated Trading Systems

Build and deploy trading bots — from simple Telegram signal delivery to fully-auto MT5 Expert Advisors.

## Architecture Decision: Signal Bot vs Full Auto

**Always discuss both options with the user upfront.** Don't jump to the most complex solution.

### Option A: Signal Bot (Telegram Delivery)
- Python script analyzes data → sends BUY/SELL/SL/TP to Telegram
- User executes manually on their broker platform
- **Pros**: Simple, reliable, no Wine/MT5 needed, works on any VPS
- **Cons**: Manual execution, requires user attention
- **Recommended starting point for new trading systems**

### Option B: Full Auto (MT5 Expert Advisor)
- EA (.mq5) runs inside MT5 terminal, reads signals, auto-executes
- **Pros**: Fully automated, no human delay
- **Cons**: Requires MT5 via Wine on Linux VPS (heavy), GUI dependency, complex setup
- **Only pursue if user explicitly insists** after explaining tradeoffs

## Data Fetching

### Yahoo Finance via yfinance (Primary)
```bash
pip install yfinance --quiet
```
- Use `GC=F` (Gold Futures) as proxy for XAUUSD spot — `XAUUSD=X` is often rate-limited or delisted
- 30 days hourly: `ticker.history(period="30d", interval="1h")`
- Yahoo rate-limits VPS IPs aggressively — use yfinance library, not direct API
- Direct Yahoo endpoints (`query1.finance.yahoo.com`) often blocked/404 from VPS

### Data Pipeline
1. Fetch OHLCV candles via yfinance GC=F 1H (primary, unlimited)
2. Get spot price via gold-api.com /price/XAU/USD (primary, cache 30s, free no auth)
3. Fallback spot: GoldAPI.io (key), Binance PAXG, yfinance last close
4. Run technical analysis
5. Generate signal with direction, entry, SL, TP
6. Save to JSON + send via Telegram

## Technical Analysis (Pure Python)

- **EMA**: 20 & 50 period for trend detection
- **RSI**: 14 period, <30 oversold, >70 overbought
- **MACD**: 12/26/9 for momentum confirmation
- **Support/Resistance**: Round highs/lows to nearest 5, find clusters
- **Signal scoring**: Require 3+ confluence factors before generating signal

## Risk Management Defaults

| Parameter | Conservative | Moderate |
|---|---|---|
| Risk/trade | 1% | 2% |
| SL (XAUUSD) | 50 pips | 30-40 pips |
| TP ratio | 1:2 | 1:1.5 |
| Lot (cent account) | 0.01-0.03 | 0.03-0.05 |
| Max daily loss | 2 trades | 3 trades |

**⚠️ Pip Math Warning:** For HFM/Exness Cent accounts, KII verified: **lot 0.01 → 10 pips = 1 cent** (1 pip = 0.1 cent). The correct formula is `risk_cent = (lot / 0.01) * sl_pips * 0.1`. See `forex-trading` skill → `references/cent-account-math.md` for full detail.

## Broker Selection

KII's active broker is **HFM Cent** ($10 account). See `forex-trading` skill for full broker-specific math.

## Modal Guidelines

| Target/Month | Recommended Min Modal | Lot | Notes |
|---|---|---|---|
| $25 | $10+ (1000c+) | 0.01 | Cent micro account — fixed lot, ~1c risk/trade |
| $50 | $500 | 0.05-0.10 | More comfortable |
| $100+ | $1000+ | 0.10 | Proper scaling possible |

**Note:** KII actively trades XAUUSD on HFM Cent with $10 (1000c) using lot 0.01. At this size, risk is ~1c per trade (10 pip SL). This is viable for learning and small consistent gains.

## Wine + MT5 on Linux VPS

**Only if user explicitly wants full auto-execute.**

```bash
# Ubuntu/Debian setup
apt-get install -y xvfb wine64

# Start virtual display (background!)
Xvfb :99 -screen 0 1024x768x24 -ac &

# Initialize Wine
export DISPLAY=:99 WINEARCH=win64 WINEPREFIX=/root/.wine
/usr/bin/wineboot --init  # NOT wine64 — use /usr/bin/wine
```

### Key Pitfalls
- Wine binary is `/usr/bin/wine` on Ubuntu (not `wine64` command)
- Xvfb MUST run before any Wine command — background it first
- **MT5 GUI installer fails on headless VPS** — `wine mt5setup.exe /silent` exits 0 but doesn't install. `nodrv_CreateWindow` / `kernel32.dll` errors = Wine can't render GUI. No workaround short of full GPU/driver passthrough.
- **MetaEditor cannot compile EAs on headless VPS** — it's a Windows GUI IDE. Compile `.mq5` → `.ex5` on a local Windows PC, then copy the `.ex5` file to the Wine prefix.
- The practical alternative: **signal bot + user compiles EA locally**. Write EA source on VPS, send to user, they compile on their Windows PC running MT5.
- pip installs (`yfinance`, `MetaTrader5` Py library) can be very slow on VPS (~5+ min) — use background process
- NEVER handle user's broker credentials directly
- MT5 terminal must stay running 24/7

### Wine + Xvfb Startup Sequence (Tested)
```bash
# 1. Start Xvfb (background, persistent)
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
sleep 2

# 2. Initialize Wine prefix
export DISPLAY=:99 WINEARCH=win64 WINEPREFIX=/root/.wine
/usr/bin/wineboot --init   # Ignore "nodrv_CreateWindow" errors — normal on headless

# 3. Test
/usr/bin/wine cmd /c "echo hello"   # Should print "hello"
```
Errors like `nodrv_CreateWindow`, `RpcSs`, `systray` are **normal** on headless — Wine still works for CLI operations.

## MT5 Signal File Pattern

Standard handoff between Python analyzer and MT5 EA:

```python
signal = {
    "direction": "BUY",     # BUY, SELL, NONE
    "entry": 3285.50,
    "sl": 3280.00,
    "tp1": 3295.00,
    "tp2": 3305.00,
    "lot_size": 0.05,
    "confidence": "HIGH",
    "timestamp": "2025-01-15T14:30:00Z"
}
with open("/path/to/signal.json", "w") as f:
    json.dump(signal, f)
```

EA reads this file on each tick; executes on new signal.

## Telegram Delivery via send_tg() in Python (Preferred for Bot Scripts)

When the bot itself sends to Telegram via Python `requests`, use this pattern:

```python
def send_tg(msg):
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID: return False
    try:
        chat_id = TELEGRAM_CHAT_ID
        params = {"chat_id": chat_id, "text": msg}
        # For topic/thread delivery, parse "chat_id:thread_id" format
        if ":" in str(chat_id):
            parts = str(chat_id).split(":", 1)
            params["chat_id"] = parts[0]
            params["message_thread_id"] = parts[1]  # MUST be separate param!
        r = requests.post(
            f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage",
            json=params, timeout=15)
        return r.status_code == 200
    except Exception as e:
        log(f"Telegram error: {e}"); return False
```

**⚠️ CRITICAL**: `message_thread_id` MUST be a separate JSON param. Do NOT embed it in `chat_id` (e.g., `chat_id="-100xxx:334"`) — Telegram API will treat it as a regular chat and send to the main topic/general chat instead.

**Loading bot token from .env:**
```python
# Load .env if available (token in env file doesn't auto-load into os.environ)
_env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
if os.path.exists(_env_path):
    with open(_env_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith("#") and "=" in _line:
                _k, _v = _line.split("=", 1)
                _k = _k.strip(); _v = _v.strip().strip('"')
                if _k == "TELEGRAM_BOT_TOKEN" and not TELEGRAM_BOT_TOKEN:
                    TELEGRAM_BOT_TOKEN = _v
                elif _k == "TELEGRAM_CHAT_ID" and not TELEGRAM_CHAT_ID:
                    TELEGRAM_CHAT_ID = _v
```

**Bot handles delivery = cron should NOT double-deliver:**
- When the bot script calls `send_tg()` internally, the cron job should NOT also deliver output via `send_message`
- Use `deliver="local"` in cron config — the bot's own `send_tg()` handles Telegram delivery
- The cron agent just needs to run the script and return the output locally

## Journal Format (Per-Signal with Multi-Position)

Journal tracks SIGNAL BOT only (not manual trades). Balance reflects real HFM balance (set manually by user).

**Schema:**
```json
{
  "account": "HFM Cent",
  "currency": "cent",
  "start_balance_cent": 1447.23,
  "balance_cent": <real HFM balance>,
  "signals": [
    {
      "signal_id": 1,
      "timestamp": "ISO8601",
      "strategy": "London Breakout",
      "direction": "BUY",
      "positions": [
        {"pos": 1, "entry": 4537.78, "sl": 4525.60, "lot": 0.05, "result": "W", "pnl": 64.10, "note": "TP1 hit"}
      ],
      "signal_pnl": 64.10,
      "status": "CLOSED"
    }
  ],
  "stats": {
    "total_signals": 4,
    "wins": 1,
    "losses": 3,
    "be": 0,
    "win_rate": 25,
    "pnl_cent": -149.55
  }
}
```

**Key rules:**
- 1 signal = 1 journal entry, regardless of how many positions user takes
- `positions[]` array holds each individual position within that signal
- Stats (`wins`/`losses`/`be`) are counted PER SIGNAL, not per position
- `win_rate` = wins / total_signals * 100
- `balance_cent` = real HFM balance (includes manual trades), NOT start_balance + bot_pnl
- `pnl_cent` in stats = sum of all signal PNL (bot only)
- Bot config `C["balance_cent"]` must be updated manually when user reports new balance
- When user reports results, format: "Signal #X: [W/L/BE] [lot] Entry [price] [TP1/SL/exit] [pnl]"

**Bug fix (May 2026):** Old journal format used `st["total"]` key. New format uses `st["total_signals"]`. Bot's `fmt_journal_summary()` MUST use `st["total_signals"]` not `st["total"]`.

## Market Structure Filter (Trend-Aware Signals)

Add trend analysis to avoid trading against the market:

```python
def analyze_market_structure(candles, lookback=20):
    """Detect trend from swing points. Returns 'uptrend' (HH+HL), 'downtrend' (LH+LL), or 'ranging'."""
    # Find swing highs/lows (higher-high + higher-low = uptrend, etc.)

def filter_by_trend(direction, structure):
    """Block SELL in uptrend, BUY in downtrend."""
    if structure == 'uptrend' and direction == 'SELL': return False
    if structure == 'downtrend' and direction == 'BUY': return False
    return True

def get_loss_review(candles):
    """After 2+ consecutive losses against trend, generate review + correction."""
    # Check journal for recent losses, cross-reference with market structure
    # Returns review string like: "LOSS REVIEW: Market UPTrend (HH+HL) | SELL loss 4x | Fokus BUY dalam uptrend"
```

**Integration in main():**
```python
# After each strategy generates a signal:
if sig:
    structure, _, _ = analyze_market_structure(candles)
    if not filter_by_trend(sig['direction'], structure):
        log(f"Blocked {sig['direction']} against {structure} trend")
        sig = None  # Let next strategy try

# After format_msg():
loss_review = get_loss_review(candles)
if loss_review:
    msg = msg + "\n\n" + loss_review
```

**Typical output in signal message:**
```
⚠️ LOSS REVIEW: Market UPTrend (HH+HL) | SELL loss 4x | Fokus BUY dalam uptrend
```

## EA Development (.mq5) — from forex-ea-mt5

Key constraints on Linux VPS:
- MetaEditor is a Windows GUI app → **cannot compile `.mq5` on headless VPS**
- Solution: Develop source on VPS, send to user, they compile on their local Windows MT5
- Copy compiled `.ex5` back to Wine prefix `MQL5/Experts/` directory
- **MT5 GUI installer does NOT work on headless VPS** — `wine mt5setup.exe /silent` exits 0 but doesn't install
- Wine binary path: `/usr/bin/wine` (NOT `wine64` command)

### Signal File Protocol (JSON — Current Standard)

```json
{
  "signal": "BUY",
  "timestamp": "2026-05-27T14:30:00+00:00",
  "entry": 3285.50,
  "sl": 3280.00, "tp1": 3296.00, "tp2": 3310.00,
  "lot_size": 0.05, "confidence": "HIGH"
}
```

See `references/xauusd-strategy.md` for XAUUSD-specific strategy notes and broker specs.

### Data Sources for Signal Generation

1. **gold-api.com `/price/XAU/USD`** — PRIMARY (free, no auth, cache 30s)
2. **GoldAPI.io `/api/XAU/USD`** — FALLBACK (needs key)
3. **Binance PAXG/USDT** — FALLBACK (real-time, no key)
4. **yfinance `GC=F`** — Historical/backtest only (delayed ~15min, rate-limited from VPS)

**⚠️ gold-api.com has ~5-10 min price delay** — acceptable for swing/day trading, NOT scalping.
**⚠️ `/ohlc` endpoint returns AGGREGATED OHLC for the entire period, NOT per-candle** — use yfinance 1H candles for intraday breakout detection.

See `references/api-gold-api-com.md` for full API reference.

## Strategy Backtesting & Comparison — from trading-bot-builder

Always backtest before deploying. Use the walk-forward approach:

1. Split data: use past N candles for indicator calculation, evaluate on next candle
2. Simulate SL/TP hits on future candles (use `high`/`low`, not just `close`)
3. Include a timeout (e.g., 30 candles max hold) for trades that don't hit SL or TP
4. Track: win rate, profit factor, net profit, max drawdown, total trades

**Key metrics:**
- **Win Rate**: % of winning trades (need >50% for 1:2 RR, or >40% for 1:3 RR)
- **Profit Factor**: Gross profit / Gross loss (need >1.2 for viable strategy)
- **Max Drawdown**: Largest peak-to-trough decline (keep <30% for safety)

**Common pitfalls:**
- Don't use `close` price for SL/TP simulation — use `high`/`low` of future candles
- Fixed SL in pips doesn't adapt to volatility — prefer ATR-based SL
- Too many confirmation filters = too few trades = unreliable statistics
- Backtest on at least 100+ trades for statistical significance
- **More indicators ≠ better signals** — each indicator adds lag. ICT (price action) outperforms multi-indicator strategies.

**Backtest results (GC=F 2-year daily, $150 start, 2% risk):**
| Strategy | Trades | WR | PF | Net | DD |
|---|---|---|---|---|---|
| ICT Smart Money | 36 | 72.2% | 9.07 | +$304 | 9.6% |
| Trend Following + ADX | 9 | 55.6% | 1.88 | +$47 | 22.8% |
| MACD Divergence | 23 | 43.5% | 1.27 | +$28 | 22.2% |
| EMA Crossover + RSI | 12 | 41.7% | 1.31 | +$16 | 15.0% |
| Mean Reversion (RSI+BB) | 27 | 25.9% | 1.02 | +$4 | 58.3% |

See `references/backtest-results.md` for full results and `templates/backtest_engine.py` for the backtest engine template.

## Trading Journal Management — from trading-journal-mgmt

### Journal Location
`/root/projects/trading/xauusd-bot/trading_journal.json` (co-located with source)

### Journaling Rules
- **One signal = one entry**, regardless of position count. Multi-position results go in `note`.
- **IDs increment forever** — use `max(existing_ids, default=0) + 1`, never `len(signals) + 1`
- **Result values**: `"W"` (net profit), `"L"` (net loss), `"BE"` (break-even), `null` (OPEN)
- **Stats**: wins/losses/be are per-signal counts. `win_rate = wins / total_signals * 100`

### Balance Tracking
- **`balance_cent` in journal = source of truth** (must match actual broker balance)
- **Formula**: `balance = start_balance + all_realized_signal_pnl + all_manual_profit`
- Manual trades: update `balance_cent` directly, NO journal entry, NO effect on WR/stats
- When user reports balance: update BOTH `j["balance_cent"]` AND `C["balance_cent"]` atomically
- **Always use user-reported broker PnL** — never re-calculate theoretically

### PnL Math (HFM Cent)
```python
pnl_cent = (lot / 0.01) * pips * 0.1
```
- lot 0.05, TP2 (200p) = +100c | lot 0.05, SL (100p) = -50c

### Daily Summary Cron
- Schedule: `0 0 * * *` (00:00 WIB daily)
- Script: `/root/projects/trading/xauusd-bot/daily_summary.py`
- Logic: OPEN signals → ⚠️ PERINGATAS; all closed → full recap
- Reads `j['balance_cent']` directly as source of truth

See `references/journal-schema.md` for schema details and `references/balance-history-2026-06.md` for anchor point reconstruction.

## Cron Job → Telegram Delivery — from cronjob-telegram-delivery

### The Core Rule
**Never use raw numeric chat IDs for Telegram topic delivery.** The format `telegram:<chat_id>:<thread_id>` resolves to a DM, NOT a topic.

### Correct Target Format
```
telegram:-1003966561389:334      ✅ Group MyAssistant24/7, Topic Trading (334)
telegram:1724161158:334          ❌ DM (KII's personal chat ID), not topic
```

### Pattern: Bot Self-Delivery (Preferred)
When the bot sends to Telegram via Python `requests`:
1. Set `deliver: "local"` in the cron job (saves output, doesn't auto-deliver)
2. Bot's `send_tg()` handles Telegram delivery directly
3. Cron agent should NOT call `send_message`

### send_tg() Implementation
```python
def send_tg(msg):
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID: return False
    try:
        chat_id = TELEGRAM_CHAT_ID
        params = {"chat_id": chat_id, "text": msg}
        if ":" in str(chat_id):
            parts = str(chat_id).split(":", 1)
            params["chat_id"] = parts[0]
            params["message_thread_id"] = parts[1]  # MUST be separate param!
        r = requests.post(
            f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage",
            json=params, timeout=15)
        return r.status_code == 200
    except Exception as e:
        log(f"Telegram error: {e}"); return False
```

### .env File Loading
```python
_env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
if os.path.exists(_env_path):
    with open(_env_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith("#") and "=" in _line:
                _k, _v = _line.split("=", 1)
                _k, _v = _k.strip(), _v.strip().strip('"')
                if _k == "TELEGRAM_BOT_TOKEN" and not TELEGRAM_BOT_TOKEN:
                    TELEGRAM_BOT_TOKEN=***                elif _k == "TELEGRAM_CHAT_ID" and not TELEGRAM_CHAT_ID:
                    TELEGRAM_CHAT_ID = _v
```

### Common Pitfalls
1. **`message_thread_id` MUST be separate** — embedding in `chat_id` sends to General/DM
2. **Bot self-send vs cron delivery** — if bot sends via `send_tg()`, use `deliver: "local"` to avoid double-delivery
3. **Manual `cronjob run` causes duplicate signals** — never manually trigger a signal bot cron
4. **`.env` file must be in same folder as script** — bot loads it with `os.path.dirname(os.path.abspath(__file__))`
5. **`DATA_DIR` must be dynamic** — never hardcode paths like `/root/xauusd-bot/`
6. **Cron schedule vs strategy hours** — align cron schedule with strategy's active hours

See `references/xauusd-bot-setup.md` for the full XAUUSD bot setup reference.

## XAUUSD Session Strategies (KII's Active Bot) — from xauusd-trading-bot

As of June 2026, KII runs a multi-session breakout bot with 3 strategies:

### London Breakout (15:00-22:00 WIB)
- Opening range from 15:00-16:00 WIB candles
- **Min range filter**: range must be ≥ 30 pips (skip if flat/small range)
- Breakout: spot closes outside range high/low ± 0.05

### NY Open Momentum (20:00-23:00 WIB)
- First NY candle (20:00-21:00) determines direction
- **Min body filter**: candle body must be ≥ 30 pips

### Asian Range Breakout (12:00-21:00 WIB)
- Asia range from 00:00-08:00 WIB candles
- Range must be < 300 pips → breakout during London hours

### General Config
- **Trend filter**: WARNING-ONLY (never blocks signal)
- **SL/TP**: SL 100p / TP1 150p / TP2 200p
- **Daily target**: $1-2 (100-200c)
- **Weekend**: Bot sends "Market closed" + structure + stats
- Cron schedule: `0 15,16,17,18,19,20,21,22,23 * * *` (9x/day)

### Bot Setup Summary Format
When user asks for "Bot Setup Summary", query journal for fresh data (never hardcode) and send formatted summary to `telegram:-1003966561389:334`. See `references/bot-setup-summary-format.md` for the template.

## Broker-Specific Math (HFM Cent) — from forex-trading

**Always confirm pip values with the actual broker. Pip definitions vary wildly.**

### HFM Cent — XAUUSD (Active Account)
- Format: 2 decimals (4439.00)
- **Pip convention: 100 points = 10 pips** (1 pip = 10 points)
- Lot 0.01 → 1 pip = **0.1 cent** ($0.001)
- **10 pips × 0.01 lot = 1 cent** — confirmed by user testing
- Spread: **35 points = 3.5 pips**
- **Entry/SL/TP display: USD format** (e.g. `4374.50`)
- **Risk/PnL/balance display: cent** (e.g. `1000c`)
- **Entry Area**: ±20p around spot price
- **SL/TP**: 100p/150p/200p (RR 1:1.5 and 1:2)

### Universal Calculation Pattern
```python
pip_to_points = 10      # 1 pip = how many points? (10 for HFM Cent)
pip_value_001 = 0.1     # cent per pip per 0.01 lot

risk_cent = (lot / 0.01) * sl_pips * pip_value_001
tp_cent   = (lot / 0.01) * tp_pips * pip_value_001
```

**⚠️ WRONG:** `risk = lot * sl_pips * pip_value` → gives tiny values
**⚠️ RIGHT:** `risk = (lot / 0.01) * sl_pips * pip_value`

### Float Formatting Bug
```python
# WRONG — ValueError: Unknown format code 'd' for float
bal_str = f"{bal:.1f}" if bal != int(bal) else f"{bal:+d}"

# RIGHT — always use .1f
bal_str = f"{bal:.1f}"
```

See `references/cent-account-math.md` for full detail.

## XAUUSD Specifics — from forex-trading

- Gold moves ~1000-2000 pips/day during active sessions
- Best sessions: London (15:00-18:00 WIB) & NY (20:00-23:00 WIB)
- GC=F futures ≈ XAUUSD spot (price varies, check current rate)
- Retail brokers (HFM, Exness) do NOT provide trading APIs — need MT5+EA for auto
- **Signal format: USD prices for entry/SL/TP, cent for risk/PnL/balance** (KII preference)
- Signal bot source: `/root/projects/trading/xauusd-bot/xauusd_multi_session.py`
- Journal: `/root/projects/trading/xauusd-bot/trading_journal.json`

## Session Times (ICT) — from forex-trading

| Session | UTC | WIB (UTC+7) | Description |
|---------|-----|-------------|-------------|
| Asia | 20:00-00:00 | 03:00-07:00 | Asian session range |
| London Killzone | 02:00-05:00 | 09:00-12:00 | London AM killzone |
| NY AM | 09:30-11:00 | 16:30-18:00 | New York AM session |
| NY PM | 13:30-16:00 | 20:30-23:00 | New York PM session |

See `references/ict-session-times.md` for full ICT session reference.
See `references/xauusd-bot-setup.md` for the full XAUUSD bot setup reference.

---

## XAUUSD Bot Operations

Operational playbook for managing the XAUUSD bot journal, balance, and signal workflow. See [references/trading-journal-rules.md](references/trading-journal-rules.md).

### Core Rules
1. **Update the journal first, not the narrative** — balance changes, BE outcomes, and trade results should be reflected in journal state before drafting any message.
2. **Separate balance updates from performance stats** — manual balance updates do NOT change WR / win-loss statistics. Only valid BUY/SELL journal entries affect stats.
3. **Honor signal result semantics** — `no entry` → record as BE with `0c` PnL; `waiting` → still a valid signal to send, not a finished trade.
4. **Don't trigger cron manually unless explicitly asked** — manual triggering creates duplicate signals.
5. **Prefer broker PnL when available** — if broker-reported PnL conflicts with estimate, broker PnL wins.
6. **Discuss strategy changes before acting** — stop and align before modifying any trading rules.

### Workflow
1. Identify request type: balance update, journal entry, signal outcome, or strategy discussion
2. Determine journal action: balance refresh only, add/update BUY/SELL entry, mark no-entry as BE `0c`, keep waiting as active
3. Preserve existing stats unless user explicitly reports a realized trade outcome
4. Keep replies concise and operational

### Journal Reset
When user requests a journal reset, follow the procedure in `references/journal-reset-procedure.md`. Clarify scope first (full reset vs. keep balance), then write the new journal directly.

### Pitfalls
- Do NOT turn a balance refresh into a new trade record
- Do NOT count `no entry` as a win or loss
- Do NOT manually run scheduled bot jobs just to check status
- Do NOT silently change strategy or risk rules
