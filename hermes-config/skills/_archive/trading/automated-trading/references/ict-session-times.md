# ICT Killzones + Pivots [TFO] — Session Reference

## Default Session Times (UTC)

| Session | UTC | WIB (UTC+7) | Description |
|---------|-----|-------------|-------------|
| Asia | 20:00-00:00 | 03:00-07:00 | Asian session range |
| London Killzone | 02:00-05:00 | 09:00-12:00 | London AM killzone |
| NY AM | 09:30-11:00 | 16:30-18:00 | New York AM session |
| NY Lunch | 12:00-13:00 | 19:00-20:00 | Lunch (avoid) |
| NY PM | 13:30-16:00 | 20:30-23:00 | New York PM session |

## Opening Price Sessions (UTC)

| Input | UTC | WIB | Name |
|-------|-----|-----|------|
| h1 | 00:00-00:01 | 07:00-07:01 | True Day Open |
| h2 | 06:00-06:01 | 13:00-13:01 | London Open |
| h3 | 10:00-10:01 | 17:00-17:01 | NY AM Open |
| h4 | 14:00-14:01 | 21:00-21:01 | NY PM Open |

## Market Structure Detection (Implemented May 29 2026)

The bot now analyzes market structure to filter signals against the trend:

### Swing Detection
- Lookback: 20 candles
- Swing High: candle where high is greater than 2 candles on each side
- Swing Low: candle where low is less than 2 candles on each side

### Trend Classification
| Condition | Classification |
|-----------|---------------|
| Higher High + Higher Low | UPTrend (HH+HL) |
| Lower High + Lower Low | DOWNTrend (LH+LL) |
| Otherwise | Ranging |

### Filter Rules
- Block SELL signals during UPTrend
- Block BUY signals during DOWNTrend
- Allow all signals during Ranging

### Loss Review
- Triggered when >=2 recent losses in same direction
- Cross-references with market structure
- Generates actionable correction advice

Example:
LOSS REVIEW: Market UPTrend (HH+HL) | SELL loss 4x | Fokus BUY dalam uptrend
