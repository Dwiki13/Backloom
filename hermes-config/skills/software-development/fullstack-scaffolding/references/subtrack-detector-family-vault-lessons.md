# SubTrack ID: Detector OCR Extraction & Family Vault Payment Lessons

## Price Extraction from OCR — Expanding Nearest-Line Search

### Problem
When an OCR keyword (e.g., "NETFLIX") is found on a line without a price, using `extract_price(entire_text)` returns the first price in the document — often the wrong price (e.g., account balance instead of subscription cost).

### Solution: Expanding outward search from keyword line

```python
def _find_nearest_price(lines: list[str], keyword_idx: int) -> float | None:
    offset = 1
    while keyword_idx - offset >= 0 or keyword_idx + offset < len(lines):
        if keyword_idx - offset >= 0:
            price = extract_price(lines[keyword_idx - offset])
            if price:
                return price
        if keyword_idx + offset < len(lines):
            price = extract_price(lines[keyword_idx + offset])
            if price:
                return price
        offset += 1
    return None
```

### Why fixed window fails
A fixed window (e.g., +-3 lines) fails when keyword is on the last line and price is 8+ lines above — common in transfer proofs where "Bayar Netflix" appears in the notes section at the bottom.

---

## SKIP_KEYWORDS: Per-Line vs Full-Text Check

### Problem with full-text check
Checking skip keywords ("transfer", "kirim", etc.) against the entire OCR text breaks family vault flow: members pay subscriptions via transfer, so "transfer" appears in every proof → all subscriptions flagged `is_subscription: false`.

### Solution: Per-line check only

```python
for item in results:
    source = item.get("source_line", "").lower()
    if any(skip.lower() in source for skip in SKIP_KEYWORDS):
        item["is_subscription"] = False
        item["confidence"] = 0.3
```

### Result matrix
| Scenario | is_subscription |
|----------|----------------|
| "Bayar Netflix" (no transfer on same line) | true |
| "Transfer Netflix Rp 59.000" (same line) | false |
| "Transfer ke Budi" + "Bayar Netflix" (separate lines) | true (Netflix detected) |

---

## Family Vault + Subscription Relationship

### Architecture
- Subscription is per-user (user_id FK), NOT per-family-vault
- Each family member who pays gets their own subscription record
- Family vault = grouping container for members only
- Payment tracking = separate `family_payments` table

### Payment status lifecycle
1. Record created (owner via generate endpoint or cron) → status: `pending`
2. Member marks paid → status: `paid`
3. Owner confirms → status: `confirmed`
4. Cron detects past-due → status: `overdue`

### Generate Payments Endpoint

`POST /{vault_id}/payments/generate` — Owner selects subscription, system auto-creates payment records for all members.

**Request:**
```json
{
  "subscription_id": "uuid",
  "custom_amounts": { "member_uuid": 15000 }
}
```
- `subscription_id` — required
- `custom_amounts` — optional override per member (key = member_id)
- Default: equal split (price / member_count)

**Response:**
```json
{
  "generated": 5,
  "subscription_name": "Netflix",
  "amount_per_member": 11800
}
```

### Complete Family Vault Endpoint List (14 total)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/family` | Create vault |
| POST | `/api/v1/family/join/{code}` | Join vault |
| GET | `/api/v1/family/my-vaults` | List my vaults |
| GET | `/api/v1/family/{id}/members` | List members |
| PUT | `/api/v1/family/{id}` | Update vault (owner) |
| DELETE | `/api/v1/family/{id}` | Delete vault (owner) |
| POST | `/api/v1/family/{id}/leave` | Leave vault |
| DELETE | `/api/v1/family/{id}/members/{uid}` | Kick member (owner) |
| POST | `/api/v1/family/{id}/transfer-ownership` | Transfer ownership |
| GET | `/api/v1/family/{id}/payments` | List payments (owner) |
| POST | `/api/v1/family/{id}/payments/generate` | Generate payment records (owner) |
| POST | `/api/v1/family/{id}/payments/{mid}/mark-paid` | Mark as paid (self) |
| PUT | `/api/v1/family/{id}/payments/{pid}/confirm` | Confirm payment (owner) |
| GET | `/api/v1/family/{id}/payments/summary` | Payment summary (owner) |

---

## Alembic: Handling Existing Table Drift in Autogenerate

### Problem
Alembic `--autogenerate` detects changes to existing tables (enum renames, index changes) that are NOT from your new model. Caused by Python model definitions slightly differing from actual DB state.

### Solution
1. Create migration file manually with raw SQL instead of `--autogenerate`
2. Use `op.create_table()` / `op.drop_table()` directly
3. Set `down_revision` to the last known good migration ID
4. Only include YOUR new table, ignore existing table drift
5. Run migration from inside container: `docker-compose exec backend alembic upgrade head`
