# XAUUSD Trading Strategy Reference

## Pair Characteristics

- **Symbol**: XAUUSD (Gold vs US Dollar)
- **Typical daily range**: 500-1500 points (Gold Futures), varies for spot
- **Trading hours**: 24h (Sun 22:00 - Fri 22:00 GMT)
- **Data proxy**: GC=F (Gold Futures) via yfinance — trend correlates with XAUUSD spot but absolute price differs

## Broker: Exness

KII uses Exness. Important notes:
- Check XAUUSD spread on Exness specifically (varies by account type)
- Verify lot minimums and step sizes on your specific account
- Cent account pip values differ from standard accounts
- **Always verify actual pip value by opening a test trade**

## Lot Sizing & Pip Math (Cent Account) — VERIFIED BY KII

**Correct math (May 2026 correction):**
- 0.1 lot XAUUSD on cent account: 100 pips = 100 cents = **$1**
- Therefore: 1 pip at 0.1 lot = **$0.01 (1 cent)**
- And: 1 pip at 0.01 lot = **$0.001 (0.1 cent)**

**The ONLY reliable way to verify:** Open a 0.01 lot trade, move 10 pips, check actual PnL.

### Lot Sizing Table (Exness/HFM Cent, verified)

| Account | Lot | 1 pip value | 50 pip SL = | 100 pip SL = |
|---|---|---|---|---|
| $100 | 0.05 | $0.005 | $0.25 | $0.50 |
| $100 | 0.10 | $0.01 | $0.50 | $1.00 |
| $500 | 0.05 | $0.005 | $0.25 | $0.50 |
| $500 | 0.10 | $0.01 | $0.50 | $1.00 |
| $1000 | 0.10 | $0.01 | $0.50 | $1.00 |

### Target Math ($25/month = $0.83/day)
With 0.1 lot ($0.01/pip):
- Need ~83 pips/day profit -> achievable with 1-2 good trades
- At 50% win rate, 1:2 RR: expect ~$15-25/month

## Recommended Strategy: ICT Smart Money

Best backtest performer: 72% WR, PF 9.07, DD 9.6% (on GC=F data).
Expect 50-60% WR in live trading due to spread/slippage.

### Core Concepts
- **Order Blocks**: Institutional entry zones (last counter-trend candle before strong move)
- **Premium/Discount**: Sell above 50% of range, buy below
- **Liquidity Sweeps**: Stop hunts above/below key levels = reversal signals
- **Break of Structure**: Confirms trend direction change
- **Confluence scoring**: Need 3+ factors for a signal

### Timeframe
- **Daily** for trend direction and OB detection
- **H1/H4** for precise entry timing

### Entry Rules (BUY example)
- EMA20 > EMA50 (uptrend) [+1]
- Price in discount zone [+1]
- Near bullish order block [+1]
- Liquidity sweep or BOS [+1]
- Score >= 3 = signal

### SL/TP Guidelines
- **SL**: Below recent swing low + buffer (use ATR-based, ~1.5x ATR)
- **TP1**: 2x risk (1:2 RR) — close 50%
- **TP2**: 3x risk (1:3 RR) — trail remainder
- **Max hold**: 30 candles

## Risk Management Rules
1. Never risk more than 2% per trade
2. Max 2 consecutive losses → stop for the day
3. Max 3 trades per day
4. Always use SL — no exceptions
5. No trading during high-impact news (NFP, CPI, FOMC)
6. Weekly loss limit: 6% → stop for the week

## Session Guide (WIB)
| Session | Time | Volatility | Notes |
|---------|------|------------|-------|
| Sydney | 04:00-13:00 | Low | Asian range |
| London | 15:00-00:00 | HIGH | Best for XAUUSD |
| New York | 20:00-05:00 | HIGH | |
| London/NY Overlap | 20:00-00:00 | PEAK | Best entries |

## News to Avoid
- **NFP** (Non-Farm Payrolls) — 1st Friday of month, 19:30 WIB
- **CPI** — monthly, 19:30 WIB
- **FOMC Rate Decision** — 8x/year, 01:00-02:00 WIB
- No trading 30 min before/after high-impact news
