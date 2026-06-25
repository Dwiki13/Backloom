#!/usr/bin/env python3
"""
Template: Generic Walk-Forward Backtest Engine
Supports multiple strategies on the same dataset with consistent parameters.

Usage:
  1. Define your strategy function that takes (candles, index) -> "BUY", "SELL", or None
  2. Register strategies in the main loop
  3. Run: python backtest_engine.py
"""

import yfinance as yf, statistics, json, sys
from datetime import datetime

# ============================================================
# CONFIGURATION
# ============================================================
TICKER = "GC=F"           # Yahoo Finance ticker
PERIOD = "2y"             # Data period
INTERVAL = "1d"           # daily, 1h, etc.
INITIAL_BALANCE = 150     # Starting capital (USD)
RISK_PCT = 2.0            # Risk per trade (%)
MAX_HOLD = 30             # Max candles before timeout
SL_BUFFER = 30            # Additional SL buffer in points
USE_ATR_SL = True         # Use ATR-based SL instead of fixed
ATR_PERIOD = 14           # ATR lookback
ATR_MULTIPLIER = 1.5      # ATR multiplier for SL distance
RR_RATIO = 2.0            # Risk:Reward ratio (TP = SL * RR)

# ============================================================
# DATA FETCH
# ============================================================
def fetch_data(ticker=TICKER, period=PERIOD, interval=INTERVAL):
    """Fetch OHLCV data from Yahoo Finance via yfinance"""
    t = yf.Ticker(ticker)
    df = t.history(period=period, interval=interval)
    candles = []
    for ts, row in df.iterrows():
        if row['Close'] != row['Close']:  # NaN check
            continue
        candles.append({
            'time': ts.isoformat(),
            'date': ts.strftime('%Y-%m-%d'),
            'open': float(row['Open']),
            'high': float(row['High']),
            'low': float(row['Low']),
            'close': float(row['Close']),
            'volume': float(row['Volume']) if row['Volume'] else 0,
            'dir': 'bull' if row['Close'] > row['Open'] else 'bear',
        })
    return candles

# ============================================================
# INDICATORS
# ============================================================
def calc_ema(prices, period):
    if len(prices) < period: return []
    ema = [statistics.mean(prices[:period])]
    k = 2 / (period + 1)
    for i in range(period, len(prices)):
        ema.append(prices[i] * k + ema[-1] * (1 - k))
    return ema

def calc_rsi(prices, period=14):
    if len(prices) < period + 1: return None
    gains, losses = [], []
    for i in range(1, len(prices)):
        c = prices[i] - prices[i-1]
        gains.append(max(0, c)); losses.append(max(0, -c))
    ag = statistics.mean(gains[-period:])
    al = statistics.mean(losses[-period:])
    if al == 0: return 100
    return 100 - 100 / (1 + ag / al)

def calc_atr(candles, period=14):
    if len(candles) < period + 1: return None
    trs = []
    for i in range(1, len(candles)):
        h, l, pc = candles[i]['high'], candles[i]['low'], candles[i-1]['close']
        trs.append(max(h - l, abs(h - pc), abs(l - pc)))
    return statistics.mean(trs[-period:])

def calc_macd(prices, fast=12, slow=26, sig=9):
    ef = calc_ema(prices, fast)
    es = calc_ema(prices, slow)
    if not ef or not es: return None, None, None
    ml = min(len(ef), len(es))
    off = len(ef) - ml
    macd = [ef[off+i] - es[i] for i in range(ml)]
    sl = calc_ema(macd, sig)
    if not sl: return None, None, None
    return macd[-1], sl[-1], macd[-1] - sl[-1]

def calc_bollinger(prices, period=20, std_mult=2.0):
    if len(prices) < period: return None, None, None
    sma = statistics.mean(prices[-period:])
    std = statistics.stdev(prices[-period:])
    return sma + std_mult * std, sma, sma - std_mult * std

# ============================================================
# BACKTEST ENGINE
# ============================================================
def run_backtest(name, signal_fn, candles, params=None):
    """Run walk-forward backtest for a given strategy function.
    
    signal_fn(candles, index) should return "BUY", "SELL", or None.
    """
    p = params or {}
    ib = p.get('initial_balance', INITIAL_BALANCE)
    rp = p.get('risk_pct', RISK_PCT)
    mh = p.get('max_hold', MAX_HOLD)
    slb = p.get('sl_buffer', SL_BUFFER)
    uatr = p.get('use_atr_sl', USE_ATR_SL)
    atrm = p.get('atr_multiplier', ATR_MULTIPLIER)
    rr = p.get('rr_ratio', RR_RATIO)
    
    trades = []
    balance = ib
    peak = ib
    max_dd = 0
    wins = losses = 0
    consecutive_wins = consecutive_losses = 0
    max_cons_w = max_cons_l = 0
    
    start_idx = max(60, p.get('min_idx', 60))
    
    for i in range(start_idx, len(candles) - 1):
        signal = signal_fn(candles, i)
        if signal not in ("BUY", "SELL"):
            continue
        
        entry = candles[i]['close']
        
        # Calculate SL distance
        atr = calc_atr(candles[:i+1]) if uatr else None
        if atr:
            sl_dist = atr * atrm
        else:
            sl_dist = p.get('fixed_sl', 150)
        
        tp_dist = sl_dist * rr
        
        if signal == "BUY":
            sl = entry - sl_dist
            tp = entry + tp_dist
        else:
            sl = entry + sl_dist
            tp = entry - tp_dist
        
        # Simulate trade outcome
        outcome = "UNKNOWN"
        pnl_points = 0
        
        for j in range(i + 1, min(i + mh + 1, len(candles))):
            if signal == "BUY":
                if candles[j]['low'] <= sl:
                    outcome = "SL"
                    pnl_points = -(entry - sl)
                    break
                if candles[j]['high'] >= tp:
                    outcome = "TP"
                    pnl_points = tp - entry
                    break
            else:
                if candles[j]['high'] >= sl:
                    outcome = "SL"
                    pnl_points = -(sl - entry)
                    break
                if candles[j]['low'] <= tp:
                    outcome = "TP"
                    pnl_points = entry - tp
                    break
        
        if outcome == "UNKNOWN":
            exit_p = candles[min(i + mh, len(candles)-1)]['close']
            pnl_points = (exit_p - entry) if signal == "BUY" else (entry - exit_p)
            outcome = "TIMEOUT"
        
        # Calculate USD PnL
        risk_amt = balance * rp / 100
        lot = max(0.01, risk_amt / max(abs(entry - sl) * 10, 1))
        pnl_usd = -risk_amt if outcome == "SL" else pnl_points * lot * 10
        
        balance += pnl_usd
        peak = max(peak, balance)
        dd = (peak - balance) / max(peak, 1) * 100
        max_dd = max(max_dd, dd)
        
        if pnl_usd > 0:
            wins += 1
            consecutive_wins += 1; consecutive_losses = 0
            max_cons_w = max(max_cons_w, consecutive_wins)
        else:
            losses += 1
            consecutive_losses += 1; consecutive_wins = 0
            max_cons_l = max(max_cons_l, consecutive_losses)
        
        trades.append({
            'date': candles[i]['date'],
            'dir': signal,
            'entry': round(entry, 1),
            'outcome': outcome,
            'pnl': round(pnl_usd, 2),
            'balance': round(balance, 2),
        })
    
    total = len(trades)
    wr = wins / total * 100 if total > 0 else 0
    gp = sum(t['pnl'] for t in trades if t['pnl'] > 0)
    gl = abs(sum(t['pnl'] for t in trades if t['pnl'] < 0))
    pf = gp / gl if gl > 0 else float('inf')
    roi = (balance - ib) / ib * 100
    
    return {
        'name': name, 'trades': total, 'wins': wins, 'losses': losses,
        'win_rate': round(wr, 1), 'profit_factor': round(pf, 2),
        'net_profit': round(balance - ib, 2), 'final_balance': round(balance, 2),
        'roi': round(roi, 1), 'max_drawdown': round(max_dd, 1),
        'max_cons_wins': max_cons_w, 'max_cons_losses': max_cons_l,
        'trades_list': trades,
    }

def print_results(result):
    """Pretty-print backtest results"""
    r = result
    print(f"\n{'='*60}")
    print(f"📊 {r['name']}")
    print(f"{'='*60}")
    print(f"  Trades: {r['trades']} (W:{r['wins']} L:{r['losses']})")
    print(f"  Win Rate: {r['win_rate']}%")
    print(f"  Profit Factor: {r['profit_factor']}")
    print(f"  Net Profit: ${r['net_profit']} ({r['roi']}% ROI)")
    print(f"  Final Balance: ${r['final_balance']}")
    print(f"  Max Drawdown: {r['max_drawdown']}%")
    print(f"  Max Cons Wins: {r['max_cons_wins']} | Max Cons Losses: {r['max_cons_losses']}")
    print(f"{'='*60}")

# ============================================================
# EXAMPLE STRATEGIES (replace with your own)
# ============================================================

def strategy_ema_crossover(candles, i):
    """EMA 8/21/50 crossover with RSI filter"""
    closes = [c['close'] for c in candles[:i+1]]
    if len(closes) < 55: return None
    
    ema8 = calc_ema(closes, 8)
    ema21 = calc_ema(closes, 21)
    ema50 = calc_ema(closes, 50)
    rsi = calc_rsi(closes)
    
    if not ema8 or not ema21 or not ema50 or rsi is None: return None
    
    p = closes[-1]
    
    if (ema8[-1] > ema21[-1] and ema8[-2] <= ema21[-2] and
        p > ema50[-1] and 40 < rsi < 70):
        return "BUY"
    
    if (ema8[-1] < ema21[-1] and ema8[-2] >= ema21[-2] and
        p < ema50[-1] and 30 < rsi < 60):
        return "SELL"
    
    return None

def strategy_mean_reversion(candles, i):
    """RSI extreme + Bollinger Band bounce"""
    closes = [c['close'] for c in candles[:i+1]]
    if len(closes) < 25: return None
    
    upper, mid, lower = calc_bollinger(closes)
    rsi = calc_rsi(closes)
    
    if upper is None or rsi is None: return None
    
    p = closes[-1]
    
    if rsi < 25 and p <= lower: return "BUY"
    if rsi > 75 and p >= upper: return "SELL"
    
    return None

# ============================================================
# MAIN - Define your strategies here
# ============================================================
if __name__ == "__main__":
    print(f"Fetching {TICKER} data...")
    candles = fetch_data()
    print(f"  Got {len(candles)} candles")
    print(f"  Range: {candles[0]['date']} to {candles[-1]['date']}")
    print(f"  Price: ${min(c['low'] for c in candles):.0f} - ${max(c['high'] for c in candles):.0f}")
    
    strategies = [
        ("EMA Crossover (8/21/50) + RSI", strategy_ema_crossover),
        ("Mean Reversion (RSI Ext + BB)", strategy_mean_reversion),
        # Add more strategies here...
    ]
    
    results = []
    for name, fn in strategies:
        r = run_backtest(name, fn, candles)
        results.append(r)
        print_results(r)
    
    # Comparison table
    results.sort(key=lambda x: x['net_profit'], reverse=True)
    print(f"\n{'='*80}")
    print("📊 STRATEGY COMPARISON (sorted by net profit)")
    print(f"{'='*80}")
    print(f"{'#':<4} {'Strategy':<40} {'Trades':>6} {'WR':>6} {'PF':>6} {'Net':>10} {'DD':>7}")
    print("-"*80)
    for i, r in enumerate(results):
        emoji = "🟢" if r['profit_factor'] > 1.2 else ("🟡" if r['profit_factor'] > 1.0 else "🔴")
        print(f"{emoji} {i+1}. {r['name'][:38]:<38} {r['trades']:>5} {r['win_rate']:>5.1f}% {r['profit_factor']:>5.2f} ${r['net_profit']:>8} {r['max_drawdown']:>5.1f}%")
    print("-"*80)
    print(f"\n🏆 Best: {results[0]['name']}")
    print(f"\n⚠️  DISCLAIMER: Backtest = hypothetical. Past ≠ future.")
