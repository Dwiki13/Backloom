# HFM Cent Account Specifications for XAUUSD Trading

## Key Trading Parameters
- **Account Type**: HFM Cent Account
- **Minimum Lot Size**: 0.01 lots
- **Price Format**: 2 decimal places (e.g., 4439.50)
- **Typical Spread**: 35 points (3.5 pips) for XAUUSD
- **Point Definition**: 1 point = 0.01 price movement (since 2 decimal format)
- **Pip Definition**: 1 pip = 10 points = 0.10 price movement

## Pip Value Calculations (Critical for Risk Management)
For XAUUSD on HFM Cent with 0.01 lot:
- **1 point** = $0.0001 profit/loss
- **1 pip** (10 points) = $0.001 profit/loss = 0.1 cent
- **Standard lot** (1.00 lots): 1 pip = $0.10 profit/loss

## Practical Examples
**Account Balance**: $10 (equivalent to 1000 cents)
**Risk per Trade**: 2% = $0.20

| Lot Size | Value per Point | Value per Pip (10 pts) | SL (100 pips) | Risk % of $10 |
|----------|-----------------|------------------------|---------------|---------------|
| 0.01     | $0.0001         | $0.001                 | $0.10         | 1.0%          |
| 0.02     | $0.0002         | $0.002                 | $0.20         | 2.0%          |
| 0.05     | $0.0005         | $0.005                 | $0.50         | 5.0%          |
| 0.10     | $0.0010         | $0.010                 | $1.00         | 10.0%         |

## Spread Impact on Trading
With typical HFM Cent spread of 35 points:
- Entry price already includes half-spread cost
- To break even, price must move 17.5 points in your favor
- Effective SL distance = nominal SL points + spread points
- Example: Intended 100 pip SL = 1000 points
  Actual at risk = 1000 + 35 = 1035 points = $0.2035 (2.035% for 0.02 lot)

## Recommended Settings for $10 Balance Account
- **Lot Size**: 0.02 lots (provides exactly 2% risk with 100 point SL)
- **Risk per Trade**: $0.20 (2.0% of balance)
- **Stop Loss**: 100 points (10 pips) = $0.20
- **Take Profit 1**: 200 points (20 pips) = $0.40 (1:2 RR)
- **Take Profit 2**: 300 points (30 pips) = $0.60 (1:3 RR)
- **Maximum Daily Trades**: 2-3 trades
- **Consecutive Loss Limit**: Stop after 2 losses

## Data Sources and Usage
1. **Historical Analysis (for strategy development)**:
   - Use `yfinance` with ticker `GC=F` (Gold Futures)
   - Note: GC=F typically trades at ~$24 premium to spot XAUUSD
   - Reliable for trend analysis, pattern recognition, ICT concepts

2. **Execution Price (for actual trading)**:
   - Always check HFM app or MT5 for real-time execution price
   - Signal bot provides points-based SL/TP to apply to current market price
   - Never rely solely on GC=F prices for order placement

## Risk Management Rules (Non-negotiable)
1. **Position Sizing**: Never risk more than 2% per trade
2. **Trade Frequency**: Maximum 2-3 trades per day
3. **Loss Limits**: Stop trading for the day after 2 consecutive losses
4. **Session Timing**: Only trade during London/NY overlap (13:00-22:00 UTC)
5. **News Avoidance**: Avoid trading during high-impact news (NFP, CPI, FOMC)
6. **Stop Loss Discipline**: Always use stop loss - no exceptions, no mental stops

## Strategy Development Notes
- ICT (Inner Circle Trader) strategies showed excellent performance on GC=F data:
  - Win Rate: 72.2%
  - Profit Factor: 9.07
  - Max Drawdown: 9.6%
- However, always validate strategies on real HFM Cent account conditions
- Account for spread in backtesting by adding spread points to SL distance