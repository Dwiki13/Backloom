# Cent Account Math Reference

## Price Conversion (USD → Cent)

For cent accounts, broker prices are displayed as USD × 100.

```
usd_to_cent(usd) = round(usd * 100)

Examples:
  $3500.50 → 350050c
  $4439.00 → 443900c
```

## Points ↔ Cent Price Conversion

**1 point = 1 cent directly** for HFM Cent XAUUSD.

Why: 1 point = 0.01 USD, and 0.01 USD × 100 = 1 cent.

```
SL_price_cent  = entry_cent - sl_points    # BUY
TP1_price_cent = entry_cent + tp1_points   # BUY
TP2_price_cent = entry_cent + tp2_points   # BUY

# For SELL, flip signs:
SL_price_cent  = entry_cent + sl_points
TP1_price_cent = entry_cent - tp1_points
TP2_price_cent = entry_cent - tp2_points
```

## Pip Value & Risk Calculation

### HFM Cent XAUUSD (Confirmed by KII)

| Value | Amount |
|-------|--------|
| pip_value_001 | 0.1 cent per pip per 0.01 lot |
| 1 pip (10 pts) | 0.1 cent at lot 0.01 |
| 10 pips at lot 0.01 | **1 cent** (user confirmed) |

### Correct Risk Formula

```python
pip_value_001 = 0.1   # cent per pip per 0.01 lot

risk_cent = (lot / 0.01) * sl_pips * pip_value_001
tp1_cent  = (lot / 0.01) * tp1_pips * pip_value_001
tp2_cent  = (lot / 0.01) * tp2_pips * pip_value_001
```

### WRONG Formula (Common Bug)

```python
# lot × pips × pip_value gives WRONG tiny values
risk_cent = lot * sl_pips * pip_value_001    # 0.01 * 10 * 0.1 = 0.01 ← WRONG!
```

The division by 0.01 normalizes lot to the base lot size.

## Lot Size Reference (HFM Cent, pip_value_001 = 0.1)

| Lot | 1 pip | 10 pips | 50 pips | 100 pips |
|-----|-------|---------|---------|----------|
| 0.01 | 0.1c | 1c | 5c | 10c |
| 0.02 | 0.2c | 2c | 10c | 20c |
| 0.05 | 0.5c | 5c | 25c | 50c |
| 0.10 | 1c | 10c | 50c | 100c |

## Fixed-Lot Position Sizing (Recommended for Cent Micro Accounts)

For small accounts where calculated lots would be too large:

```python
lot = 0.01  # Always minimum
risk_cent = (0.01 / 0.01) * sl_pips * 0.1  # = sl_pips * 0.1
```

## Signal Output Format (Cent Account)

```
🟢 BUY XAUUSD 🔥 HIGH
💰 Entry: ~350500 cent (HFM app)
🛑 SL: ~350400c (10.0 pips) = 1.0c
🎯 TP1: ~350700c (20.0 pips) = 2.0c
🎯 TP2: ~350800c (30.0 pips) = 3.0c
📦 Lot: 0.01
💰 Balance: 1000c | Risk: ~1.0c
```

## Journal Commands

```bash
python3 journal.py W          # Mark latest open signal as WIN
python3 journal.py L          # Mark latest open signal as LOSS
python3 journal.py BE         # Mark latest open signal as BREAKEVEN
python3 journal.py SHOW       # Show full journal
python3 journal.py SUMMARY    # Show summary only
```

## PnL Convention

- WIN = +tp1_cent (conservative — count only TP1)
- LOSS = -sl_cent
- BE = 0
