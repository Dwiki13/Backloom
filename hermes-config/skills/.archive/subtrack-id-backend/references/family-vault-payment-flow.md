# Family Vault Payment Flow — Endpoint Mapping

## Flow End-to-End

```
1. Owner bikin vault
   → POST /api/v1/family

2. Owner link langganan
   → POST /api/v1/family/{vault_id}/subscriptions

3. Member join
   → POST /api/v1/family/join/{code}
   → Response: payment_eligible=false, first_payment_month="2026-11"

4. Tanggal 1 → Celery auto-generate
   → FamilyPayment status PENDING dibuat

5. Member lihat tagihan
   → GET /api/v1/family/{vault_id}/payments
   → Status: PENDING

6. Member bayar + upload bukti
   → POST /api/v1/family/{vault_id}/payments/{member_id}/mark-paid
   → Status: AWAITING_CONFIRM
   → Notify owner

7. Owner lihat bukti
   → GET /api/v1/family/{vault_id}/payments
   → Lihat proof_url

8. Owner konfirmasi
   → PUT /api/v1/family/{vault_id}/payments/{payment_id}/confirm
   → Status: CONFIRMED
   → Notify member

9. Owner tolak (optional)
   → PUT /api/v1/family/{vault_id}/payments/{payment_id}/reject
   → Status: PENDING
   → Notify member upload ulang

10. History
    → GET /api/v1/family/{vault_id}/payments/history

11. Auto-confirm (Celery tiap 6 jam)
    → Reminder ke owner kalau AWAITING_CONFIRM > 6 jam
    → Auto CONFIRMED kalau > 24 jam
```

## Endpoint → Flow Mapping

| # | Endpoint | Method | Handle Flow |
|---|----------|--------|-------------|
| 1 | `/api/v1/family` | POST | Owner bikin vault |
| 2 | `/api/v1/family/join/{code}` | POST | Member join — return first_payment_month + payment_eligible |
| 3 | `/api/v1/family/{vault_id}/subscriptions` | POST | Owner link langganan |
| 4 | `/api/v1/family/{vault_id}/subscriptions` | GET | List langganan vault (full fields) |
| 5 | `/api/v1/family/{vault_id}/payments` | GET | List tagihan — owner lihat semua, member lihat sendiri |
| 6 | `/api/v1/family/{vault_id}/payments/history` | GET | History pembayaran — paginated |
| 7 | `/api/v1/family/{vault_id}/payments/summary` | GET | Ringkasan — total paid, pending, awaiting, overdue |
| 8 | `/api/v1/family/{vault_id}/payments/{member_id}/mark-paid` | POST | Member bayar + upload bukti (wajib) → AWAITING_CONFIRM |
| 9 | `/api/v1/family/{vault_id}/payments/{payment_id}/confirm` | PUT | Owner konfirmasi → CONFIRMED |
| 10 | `/api/v1/family/{vault_id}/payments/{payment_id}/reject` | PUT | Owner tolak → PENDING |
| 11 | *(Celery beat)* | — | Auto-generate tagihan tiap tanggal 1 |
| 12 | *(Celery beat)* | — | Auto-confirm + reminder tiap 6 jam |

## Status Enum

```
PENDING → AWAITING_CONFIRM → CONFIRMED
                   ↓
                 PENDING (if rejected)
```

## Key Decisions

- **1 vault = 1 subscription** — multiple subscriptions need separate vaults
- **Manual generate removed** — prevents double-billing confusion
- **Proof upload required** — no payment without proof
- **Auto-confirm after 24h** — with 6h reminders to owner
- **Member can view own payments** — not just owner

## ⚠️ Known Gotchas

### `joined_at` vs `created_at` in generate_family_payments
The `generate_family_payments` Celery task filters members by join date to implement Opsi C (skip if joined same month). The column is `joined_at` on `FamilyMember`, NOT `created_at`.

**Bug**: Task referenced `member.created_at` → evaluates to `None`/`AttributeError` → all members skipped → no payments generated.

**Fix**: Use `member.joined_at` or a defensive `hasattr` check:
```python
join_date = member.joined_at if hasattr(member, 'joined_at') and member.joined_at else (member.created_at if hasattr(member, 'created_at') else None)
```

**Real case (June 15 2026)**: Manual trigger of `generate_family_payments` produced 0 payments because all members had `joined_at` in the current month and the task was checking `created_at` (which doesn't exist on the model). After fix, members who joined in the same month are still skipped (correct Opsi C behavior), but the task correctly reads the date field.
