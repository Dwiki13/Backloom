# Trend Filter Discussion - June 2026

## Problem
The trend filter in the XAUUSD bot is too sensitive, blocking profitable counter-trend setups.

## Evidence from June 1, 2026
- Market was in uptrend (detected HH+HL structure)
- Bot generated 7 signals (all SELL, counter-trend)
- Results: 2 wins (+800c), 1 loss (-200c), 4 breakeven (0c)
- Despite being counter-trend, the signals were profitable due to large winners

## Current Behavior (June 2, 2026)
- Signals 15:00-18:00: 2 signals processed (#13 BE no-entry, #14 SELL active)
- Signals 19:00-23:00: All blocked by trend filter (detected uptrend)
- No notifications sent for blocked signals

## Recommended Solution
Change trend filter from blocking to warning-only:
- Add `[TREND-FOLLOW]` tag when signal aligns with trend
- Add `[COUNTER-TREND]` tag when signal opposes trend
- Send notification every hour regardless
- Let operator decide whether to take the signal

## Implementation Notes
- Modify `filter_by_trend()` function in `xauusd_multi_session.py`
- Instead of returning False to block, return True and add tag to signal message
- Update Telegram message format to include the tag

## References
- June 1 signal data: 7 signals, 2W 1L 4BE, +600c net
- Journal shows manual profit of +62.7c not included in stats
- Balance updated to 2183.53c after manual profit