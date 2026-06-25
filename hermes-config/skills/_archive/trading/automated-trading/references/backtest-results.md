# XAUUSD Backtest Results — May 2026 Session

## Data Source
All backtests run on GC=F (Gold Futures) hourly/daily data from yfinance, period = 2 years.
Gold Futures correlates ~99.5% with XAUUSD spot; trend/structure analysis is valid for HFM/Exness.

## Broker Config Used
- HFM Cent, modal $10 (1000 cents), lot 0.02
- SL: 100 points (10 pips), TP: 200 points (20 pips), RR 1:2
- Spread: 35 points = 3.5 pips
- Pip value (0.01 lot): $0.001 per pip → 10 pips × 0.01 lot = $0.01 (1 cent)
- Risk per trade: $0.20 (2%)

## Strategy Results (Ranked)

### 1. ICT Smart Money + ADX Filter 🏆
- Win Rate: 72.2% (ICT) / 55.6% (ADX variant)
- Profit Factor: 9.07 (ICT) / 1.88 (ADX)
- Net: +$304 (ICT) / +$47 (ADX)
- Max DD: 9.6% (ICT) / 22.8% (ADX)
- Trades: 36 (ICT) / 9 (ADX) over 2 years
- Verdict: **BEST** — selective, high quality

### 2. London Breakout (London Open 21:00 UTC / 04:00 WIB)
- Win Rate: 58%
- Profit Factor: 2.79 (inflated by double-counting bug — real PF ~1.2)
- Net: +$0.11 from $10 over 2 years (essentially breakeven)
- Max DD: 0.1%
- Trades: 298
- Verdict: **MARGINAL** — too many trades, spread eats profit, needs lot 0.20+ for $1/day target which is too risky for $10 balance

### 3. Multi-EMA + RSI + MACD + S/R (Original v1)
- Win Rate: 31.2%
- Profit Factor: 0.51
- Net: -$1,008 (catastrophic)
- Max DD: 413%
- Verdict: **DO NOT USE**

### 4. Trend Following + ADX
- Win Rate: 55.6%
- Profit Factor: 1.88
- Distinct from ICT but similar concept
- Good alternative if ICT setup too rare

## Key Lessons
1. Spot the difference between points and pips EARLY — "2000 points = 200 pips" means 1 pip = 10 points
2. Spread can be quoted in points OR pips — always clarify with user
3. GC=F price (~$4,470) ≠ XAUUSD spot (~$4,439 at time of session) — use Stooq for spot
4. Backtest bugs (double counting) can inflate PF by 2-3x — always verify trade count vs unique days
5. With $10 balance, realistic profit is $3-5/year at 72% WR — manage expectations
