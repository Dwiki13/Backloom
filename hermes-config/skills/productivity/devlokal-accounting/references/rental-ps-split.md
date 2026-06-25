# Rental PS — Profit Split Reference

## Profit Split Structure

- **Partner (friend): 70%** of gross monthly revenue
- **KII: 30%** of gross monthly revenue
- **Bagi hasil date: 25th of every month**

## Fixed Monthly Costs (deducted from KII's 30% share)

| Cost | Amount |
|---|---|
| Electricity (PLN) | Rp 82.000 |
| Maintenance/repair fund (uang kas) | Rp 100.000 |
| **Total fixed costs** | **Rp 182.000** |

## KII's Net Income Formula

KII_net = (30% x gross_monthly_revenue) - Rp 182.000

## Recording Steps (on the 25th)

1. Record GROSS rental revenue for the month -> income.json (category: rental-fee)
2. Record partner's 70% payout -> expenses.json (category: payout-partner)
3. Record fixed costs -> expenses.json (categories: electricity, maintenance-fund)
4. KII's net = automatically calculated from the above

## Example

Gross revenue Juni 2026 = Rp 5.000.000
- Partner 70% = Rp 3.500.000 (expense: payout-partner)
- KII 30% = Rp 1.500.000 (income)
- Fixed costs = Rp 182.000 (expenses)
- KII net = Rp 1.318.000

## Important Notes

- Always record GROSS revenue first, never just KII's share
- The 70% partner payout is recorded as an expense distribution
- Fixed costs are separate expenses under their own categories
- If KII says "rental dapet Rp X today", record as GROSS income (not split yet)
- Split happens once monthly on the 25th
