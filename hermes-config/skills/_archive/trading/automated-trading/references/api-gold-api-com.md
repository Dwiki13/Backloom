# gold-api.com API Reference

Base URL: `https://api.gold-api.com`

## Endpoints

### GET /price/XAU/USD — Real-time Spot Price
- **Auth:** None
- **Rate limit:** None (but cache 30s to prevent IP block — docs explicitly warn)
- **Price delay:** ~5-10 minutes. Acceptable for swing/day trading, NOT for scalping.
- **Response:** { "price": 4377.60, "currency": "USD", "symbol": "XAU", "updatedAt": "..." }

### GET /ohlc/XAU — Aggregated OHLC (NOT per-candle!)
- **Auth:** API key (x-api-key header)
- **Rate limit:** 10 req/hr free tier
- **CRITICAL:** Returns AGGREGATED OHLC for the ENTIRE period, NOT individual candles
- **Min window:** ~12 hours (1-6h windows return 404)
- **NOT suitable** for intraday breakout detection — use yfinance 1H candles instead
- **OK for:** Daily/weekly range analysis
- **Params:** startTimestamp, endTimestamp (Unix)

### GET /history — Historical Price History
- **Auth:** API key (x-api-key header)
- **Rate limit:** 10 req/hr free tier
- **Params:** symbol (required), startTimestamp (required), endTimestamp (required), groupBy (year/month/week/day), aggregation (max/min/avg)
- **groupBy=hour/minute:** Premium only
- **Response:** [{ "day": "2026-05-28 00:00:00", "max_price": "4458.30" }]

## API Keys
- **/price:** No key needed
- **/ohlc, /history:** `2d06619eb3675df1759ce59e5ea21a4091446382b42c292e0e693458368ce972` (10 req/hr each)

## Recommended Usage
1. Every cron tick: /price for spot (cache 30s, no rate limit)
2. Intraday OHLC: yfinance GC=F 1H (unlimited, per-candle granularity)
3. Historical: /history groupBy=day sparingly (within 10 req/hr budget)

## Test Results (May 28, 2026)
| Endpoint | Window | Result |
|----------|--------|--------|
| /price/XAU/USD | Real-time | OK, $4377.60 |
| /ohlc/XAU | 5 days | OK, aggregated OHLC |
| /ohlc/XAU | 1 hour | 404 (too granular) |
| /history groupBy=day | 30 days | OK, 31 entries |
