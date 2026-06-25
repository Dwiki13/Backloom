#!/usr/bin/env python3
"""
Google Ads Scaling Analysis Template
- Input: current_clicks_daily, cpc, deal_value, conversion_rates
- Output: scaling table, break-even, CPC sensitivity, phased roadmap
- Usage: Run via execute_code with updated parameters
"""

import math

def scaling_analysis(current_clicks_daily: float, cpc: int, deal_value: int,
                     click_to_lead: float = 0.05, lead_to_deal: float = 0.10):
    """Full scaling analysis for Google Ads budget planning."""
    
    click_to_deal = click_to_lead * lead_to_deal
    current_monthly = current_clicks_daily * 30
    
    print("=" * 60)
    print("📊 SCALING ANALYSIS")
    print("=" * 60)
    print(f"  Current: {current_clicks_daily:.0f} clicks/hari (~{current_monthly:.0f}/bln)")
    print(f"  CPC: Rp {cpc:,} | Deal value: Rp {deal_value:,}")
    print(f"  Conversion: {click_to_lead*100:.0f}% click→lead × {lead_to_deal*100:.0f}% lead→deal = {click_to_deal*100:.2f}% click→deal")
    
    # Scaling table
    print(f"\n{'Scale':>6} | {'Clicks/d':>8} | {'Clicks/m':>10} | {'Spend/m':>12} | {'Deals':>6} | {'Revenue':>12} | {'ROAS':>5}")
    print("-" * 75)
    
    for m in [1, 1.5, 2, 2.5, 3, 4, 5]:
        cd = current_clicks_daily * m
        cm = cd * 30
        spend = cm * cpc
        deals = cm * click_to_deal
        rev = deals * deal_value
        roas = rev / spend if spend > 0 else 0
        marker = " <- NOW" if m == 1 else ""
        print(f"  {m:>4}x  | {cd:>7.0f}  | {cm:>9.0f}  | Rp {spend/1000:>8.0f}K | {deals:>5.1f}  | Rp {rev/1000:>8.0f}K | {roas:>4.1f}x{marker}")
    
    # Break-even
    be_rate = cpc / deal_value
    print(f"\n⚖️  Break-even: {be_rate*100:.2f}% click-to-deal = 1 deal per {1/be_rate:.0f} clicks")
    for m in [1, 2, 3, 4, 5]:
        cm = current_clicks_daily * 30 * m
        spend = cm * cpc
        be_deals = spend / deal_value
        print(f"  {m}x ({cm:.0f} clicks, Rp {spend/1000:.0f}K): B/E = {be_deals:.1f} deals/bln")
    
    # CPC sensitivity at 3x
    print(f"\n📉 CPC Sensitivity at 3x (~{current_clicks_daily*30*3:.0f} clicks/bln):")
    base_clicks = current_clicks_daily * 30 * 3
    for mult in [1.0, 1.1, 1.2, 1.3, 1.5]:
        adj_cpc = cpc * mult
        spend = base_clicks * adj_cpc
        deals = base_clicks * click_to_deal
        rev = deals * deal_value
        profit = rev - spend
        roi = (profit / spend) * 100
        print(f"  CPC Rp {adj_cpc:>6,.0f} ({mult:.1f}x): Spend Rp {spend/1000:>5.0f}K → Profit Rp {profit/1000:>7.0f}K (ROI {roi:>+4.0f}%)")

# === CONFIGURE HERE ===
if __name__ == "__main__":
    scaling_analysis(
        current_clicks_daily=12.2,
        cpc=5000,           # KII's CPC max
        deal_value=2_500_000,  # DevLokal avg deal
        click_to_lead=0.08,    # Optimis: 8%
        lead_to_deal=0.15,     # Optimis: 15%
    )
