# HFM Cent Account Specifications

## Key Parameters
- **Account Type**: Cent Account
- **Minimum Lot Size**: 0.01 lots
- **Price Format**: 2 decimal places (e.g., 4439.50)
- **Spread**: Typically 35 points (3.5 pips) for XAUUSD
- **Point Definition**: 1 point = 0.01 price (since 2 decimal format)
- **Pip Definition**: 1 pip = 10 points = 0.10 price movement

## Pip Value Calculations
For XAUUSD on HFM Cent:
- **1 point** = $0.0001 per 0.01 lot = $0.01 per 0.10 lot
- **1 pip** (10 points) = $0.001 per 0.01 lot = $0.10 per 0.10 lot
- **Standard lot** (1.00): 1 pip = $1.00

## Example Calculations
**Balance**: $10 (1000 cents)
**Risk per trade**: 2% = $0.20

| Lot Size | 1 Pip Value | 10 Pip Value | 100 Pip Value | SL (100 pips) |
|----------|-------------|--------------|---------------|----------------|
| 0.01     | $0.001      | $0.01        | $0.10         | $0.10 (1%)     |
| 0.02     | $0.002      | $0.02        | $0.20         | $0.20 (2%)     |
| 0.05     | $0.005      | $0.05        | $0.50         | $0.50 (5%)     |
| 0.10     | $0.010      | $0.10        | $1.00         | $1.00 (10%)    |

## Spread Impact
With 35 point spread:
- **Effective SL distance** = SL points + spread points
- Example: Intended 100 pip SL = 1000 points
- Actual risk = 1000 + 35 = 1035 points = $0.2035 (2.035% for 0.02 lot)

## Recommended Settings for $10 Balance
- **Lot Size**: 0.02 lots
- **Risk per trade**: $0.20 (2%)
- **SL Distance**: 100 points (10 pips) = $0.20
- **TP1**: 200 points (20 pips) = $0.40 (1:2 RR)
- **TP2**: 300 points (30 pips) = $0.60 (1:3 RR)
- **Max Daily Trades**: 2-3
- **Consecutive Loss Limit**: 2 trades

## Data Sources
- **Historical Analysis**: Use `yfinance` with `GC=F` (Gold Futures)
  - Note: GC=F typically trades at ~$24 premium to spot XAUUSD
  - Use for trend analysis, pattern recognition
- **Execution Price**: Check HFM app/MT5 for actual execution price
  - Signal bot provides points-based SL/TP to apply to current market price

## Risk Management Rules
1. Never risk more than 2% per trade
2. Maximum 2-3 trades per day
3. Stop trading for the day after 2 consecutive losses
4. Only trade during London/NY session overlap (13:00-22:00 UTC)
5. Avoid trading during high-impact news (NFP, CPI, FOMC decisions)
6. Always use stop loss - no exceptions