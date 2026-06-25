# Bot Setup Summary — Template & Rules

## When to Send

Send this summary whenever the user asks for:
- "Bot Setup Summary"
- "Summary"
- "Cek cronjob"
- "Update bot"
- Any request for a comprehensive bot status overview

## Rules

1. ALWAYS query the journal for fresh data — never hardcode numbers.
2. Send to `telegram:-1003966561389:334` (Topic Trading).
3. Format must match the template below exactly (user specified this format).

## Data Query

```bash
cd /root/projects/trading/xauusd-bot && python3 -c "
import json
with open('trading_journal.json') as f:
    j = json.load(f)
st = j['stats']
bal = j.get('balance_cent', 0)
total = st.get('total_signals', st.get('total', 0))
wins = st['wins']
losses = st['losses']
be = st['be']
wr = f'{wins/(wins+losses)*100:.0f}%' if (wins+losses) > 0 else 'N/A'
pnl = st['pnl_cent']
existing_ids = [s['id'] for s in j['signals']]
next_id = max(existing_ids, default=0) + 1
last = j['signals'][-1]
strat_data = {}
for s in j['signals']:
    if s.get('result') not in ('W','L','BE'):
        continue
    sn = s['strategy']
    if sn not in strat_data:
        strat_data[sn] = {'W':0,'L':0,'BE':0,'pnl':0}
    strat_data[sn][s['result']] += 1
    strat_data[sn]['pnl'] += s.get('pnl_cent', 0)
print(f'Total:{total} W:{wins} L:{losses} BE:{be} WR:{wr}')
print(f'PnL:{pnl:+.1f}c Balance:{bal:.2f}c')
print(f'Next:#{next_id} Last:#{last[\"id\"]}')
for sn, sv in strat_data.items():
    swr = f'{sv[\"W\"]/(sv[\"W\"]+sv[\"L\"])*100:.0f}%' if (sv['W']+sv['L']) > 0 else 'N/A'
    print(f'{sn}: W:{sv[\"W\"]} L:{sv[\"L\"]} BE:{sv[\"BE\"]} WR:{swr} PnL:{sv[\"pnl\"]:+.0f}c')
"
```

## Template

```
📊 XAUUSD BOT SETUP SUMMARY

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⏰ CRON JOBS:
• Signal Bot → jam 15-23 WIB (9x/hari), termasuk weekend
• Daily Summary → jam 00:00 WIB
  - Ada signal belum feedback → ⚠️ peringatan
  - Semua closed → full summary (yesterday + day-before)

🤖 STRATEGY:
• London Breakout (15:00 WIB range → breakout 16:00+)
• NY Open Momentum (20:00 WIB → follow first candle)
• Asian Range Breakout (00:00-08:00 range → breakout 15:00+)

🔧 CONFIG:
• Broker: HFM Cent | SL: 100p | TP1: 150p | TP2: 200p
• Lot min: 0.01 | Spread: 3.5 pips
• Daily target: $1-2 (100-200c)

📤 SIGNAL FORMAT:
{emoji} {direction} XAUUSD — {strategy}
Confidence: 🔥 HIGH | WR: {strategy_wr}% | ⏰ {time} WIB

💰 Entry Area: {entry_lo} - {entry_hi} (±20p)
🛑 SL: {sl_dir}{sl_pips}p = {sl_price}
🎯 TP1: {tp1_dir}{tp1_pips}p = {tp1_price}
🎯 TP2: {tp2_dir}{tp2_pips}p = {tp2_price}

📦 Lot ref (risk per lot)
  0.01 → risk {risk_001}c | TP1 +{tp1_001}c | TP2 +{tp2_001}c
  0.02 → risk {risk_002}c | TP1 +{tp1_002}c | TP2 +{tp2_002}c
  0.05 → risk {risk_005}c | TP1 +{tp1_005}c | TP2 +{tp2_005}c

💰 Balance: {balance}c (${balance_usd})

📝 Setup → kenapa signal muncul
🔮 Context → last W/L, warning, recent WR
📒 Journal → stats keseluruhan

💡 FEATURES:
• WR tampil di header signal
• 🔮 Context: last W/L + warning + recent WR
• 📊 Trend tag di setiap signal (warning-only)
• Weekend: kirim market structure + stats
• Daily summary otomatis jam 00:00 WIB
• Warning ada signal belum di-feedback

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 PERFORMANCE

🏆 ALL-TIME
• Signals: {total} | W:{wins} L:{losses} BE:{be} | WR: {wr}
• PnL: {pnl}c (${pnl_usd})
• Balance: {balance}c (${balance_usd})
• Next signal: #{next_id}

📈 BY STRATEGY
{strategy lines, one per line}

📍 Delivery: Topic Trading (334)
```
