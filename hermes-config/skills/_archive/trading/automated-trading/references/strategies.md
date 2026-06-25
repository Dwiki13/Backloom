# Trading Strategy Reference

## Strategy Comparison (XAUUSD / GC=F, 2-Year Daily Backtest, $150 start, 2% risk/trade)

| Strategy | Trades | Win Rate | PF | Net Profit | Max DD |
|---|---|---|---|---|---|
| **ICT Smart Money** | 36 | **72.2%** | **9.07** | **+$304.70** | **9.6%** |
| Trend Following + ADX | 9 | 55.6% | 1.88 | +$46.84 | 22.8% |
| MACD Divergence + Trend | 23 | 43.5% | 1.27 | +$28.14 | 22.2% |
| EMA Crossover (8/21/50) + RSI | 12 | 41.7% | 1.31 | +$16.02 | 15.0% |
| Mean Reversion (RSI Ext + BB) | 27 | 25.9% | 1.02 | +$4.13 | 58.3% |
| Breakout + Volume | 2 | 50.0% | 1.02 | +$0.24 | 6.7% |
| BB Squeeze + Momentum | 1 | 0.0% | 0.00 | -$5.54 | 3.7% |
| Multi-EMA + MACD + S/R (v1) | 221 | 31.2% | 0.51 | -$1008 | 413% |

**Key insight**: Fewer, higher-quality signals (ICT: 36 trades) massively outperform high-frequency approaches (Multi-EMA: 221 trades, -672% ROI). Quality > quantity.

---

## ICT Smart Money Strategy (Best Performer)

### Concepts
Based on Inner Circle Trader (ICT) / Smart Money Concepts:

1. **Order Blocks (OB)**: Last bearish candle before a strong bull move = bullish OB (buy zone). Vice versa for bearish OB.
2. **Fair Value Gaps (FVG)**: Imbalance zones where price moved too fast, leaving a gap. Price tends to revisit.
3. **Liquidity Sweeps**: Price sweeps past equal highs/lows (stop hunts) then reverses. Sweep of highs = bullish signal.
4. **Break of Structure (BOS)**: Price breaks a key swing high/low, confirming trend direction.
5. **Premium/Discount**: Above 50% of recent range = premium (sell zone). Below = discount (buy zone).
6. **Kill Zones**: London open (15:00-18:00 WIB) and NY open (20:00-23:00 WIB) — highest probability times.

### Signal Rules

**BUY (score >= 3):**
- EMA20 > EMA50 (uptrend) [+1]
- Price in discount zone (below 50% of 50-candle range) [+1]
- Price near bullish order block (within 100 points) [+1]
- Liquidity sweep of sell-side (price swept high then closed below) [+1]
- Bullish BOS (broke above swing high) [+1]

**SELL (score >= 3):** Mirror of BUY conditions.

### Risk Management
- SL: Below/above recent swing low/high + 30-point buffer
- TP: 2x risk distance (1:2 RR), with TP2 at 3x for runners
- Max hold: 30 candles (then close at market)
- Risk: 1.5-2% of account per trade
- Lot size: dynamic based on ATR distance (risk amount / SL distance)

### Implementation Notes
- Works best on Daily timeframe for swing trading
- Can be adapted to H1/H4 for more signals
- ATR-based SL preferred over fixed pips (gold volatility changes over time)
- Python implementation uses yfinance GC=F as proxy for XAUUSD

### Prerequisites
```bash
pip install yfinance
```
yfinance install can be VERY slow on VPS (5+ min) — run in background.

---

## Trend Following + ADX (Runner-up)

### Rules
- Only trade when ADX > 20 (strong trend)
- EMA20 > EMA50 for buys, < for sells
- RSI pullback to 35-55 zone = entry trigger
- Enter on bounce off EMA20

### Why it works
ADX filter eliminates choppy/sideways markets where most losses occur.

---

## Why Multi-Indicator Strategies Fail

The worst performer (31% win rate, -672% ROI) used:
- EMA crossover + MACD + RSI + Support/Resistance + Trend filter
- 5 indicators, needed 3+ confirmations
- Resulted in 221 trades (high frequency, low quality)
- Each indicator added lag; by the time all confirmed, the move was over

**Lesson**: More indicators != better signals. Each indicator adds delay. ICT works because it reads market structure (price action), not lagging indicators.

---

## Data Source Notes

- `yfinance` + `GC=F` = most reliable free gold data
- Yahoo Finance direct API (v8) often rate-limits from VPS IPs
- Gold futures (GC=F) trade at different absolute price than XAUUSD spot (ratio varies over time)
- **CRITICAL**: Backtest results use GC=F data. Actual entry/SL/TP prices MUST be calibrated to your broker's XAUUSD spot price. The trend/direction is highly correlated, but absolute price levels differ.
- For accurate broker-specific backtesting, compare GC=F price to broker XAUUSD price once to get the offset

---

## Lot Sizing & Pip Math (Exness/HFM Cent Account) — VERIFIED

**KII's correction (May 2026):** The ONLY reliable way to know your pip value: open a 0.01 lot trade, move 10 pips, check actual PnL in cents.

For Exness/HFM Cent account (based on KII's verification):
- **0.1 lot -> 100 pips = 100 cents = $1** -> 1 pip at 0.1 lot = **$0.01 (1 cent)**
- **0.01 lot -> 1 pip = $0.001 (0.1 cent)**

With $100 account and 2% risk ($2):
- At 0.01 lot: $2 risk = 2,000 pips SL (impossible for XAUUSD)
- At 0.05 lot: 1 pip = $0.005 -> $2 risk = 400 pips SL
- At 0.1 lot: 1 pip = $0.01 -> $2 risk = 200 pips SL

**ALWAYS verify pip value on YOUR specific broker/account type before trading.**

### Modal Realistis untuk Target $25/bulan

| Modal | Lot | SL (pips) | Risk/trade | Keterangan |
|---|---|---|---|---|
| $100 | 0.05 | 40 | $2 (2%) | Sangat mepet |
| $500 | 0.05 | 100 | $5 (1%) | Comfortable |
| $500 | 0.10 | 50 | $5 (1%) | Lebih banyak opportunity |
| $1000 | 0.10 | 100 | $10 (1%) | Ideal |

---

## Win Rate Reality

| Win Rate | Required RR for Profitability |
|---|---|
| 40% | Need 1:2.5+ RR |
| 50% | Need 1:2+ RR |
| 60% | Need 1:1.5+ RR |
| 70% | Need 1:1+ RR (almost break-even) |

**Formula**: Breakeven win rate = 1 / (1 + RR)

### Backtest vs Live Reality

Backtest ICT: 72% WR. But expect 50-60% in live trading because:
- Backtest uses GC=F futures, not broker XAUUSD spot
- No spread cost included (20-50 pips on Exness)
- No slippage included (worse during news)
- 36 trades = small sample size
- **Forward-test on demo for 2-4 weeks before going live**
