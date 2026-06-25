# SubTrack Billing Simplification (June 2026)

## What Changed
- **`billing_type` field REMOVED** from both `FamilyVault` and `FamilyPayment` models
- **Billing is now split-rata only**: `amount = round(subscription.price / member_count)`
- **`payment_info` (Text, nullable)** added to `FamilyVault` — owner sets bank/e-wallet instructions for members
- Migration `f4a5b6c7d8e9` drops `billing_type` columns, adds `payment_info` to `family_vaults`

## Why
Initially planned two billing types (`full_price` and `split_equal`) but decided to keep it simple. The `share_percentage` field on `FamilyMember` exists in DB but is NOT used for billing.

## Current Billing Logic
```python
# generate_family_payments in family_billing_service.py
member_count = len(members)
amount = round(subscription.price / member_count)
```

## Flutter Implications
- Remove `_buildEstimateText()` from `family_screen.dart`
- Display `payment.amount` from backend directly
- Before payment generated: show "Belum ada tagihan bulan ini"
- `payment_info` field: display as bank/e-wallet instructions on payment screen
