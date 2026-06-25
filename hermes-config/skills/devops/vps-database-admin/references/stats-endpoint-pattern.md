# Stats Endpoint Pattern & Backend Fixes (June 2026)

## Stats Endpoint Pattern

### Problem
`GET /api/v1/subscriptions/stats/summary` didn't accept query params (`period`, `month`, `year`) and didn't return `monthly_trend` data. Clients had to call a separate endpoint for trend data.

### Solution
1. **Accept filter params**: `period` (monthly/yearly), `month` (1-12), `year` (2020-2100)
2. **Return trend inline**: Include `monthly_trend` (12 months) in the same response — don't force clients to call a separate endpoint
3. **Wrap in sub-object**: Use `"summary": {...}` wrapper to avoid breaking existing clients when adding new top-level fields
4. **Use `pattern` not `regex`**: FastAPI deprecated `regex` parameter in favor of `pattern`

### Response Shape
```json
{
  "period": "monthly",
  "month": null,
  "year": null,
  "summary": {
    "total_subscriptions": 5,
    "total_monthly": 250000,
    "total_yearly": 3000000,
    "by_category": { "streaming": 150000 },
    "upcoming_billing": 2,
    "trials_ending": 1,
    "price_increases": 0
  },
  "monthly_trend": [
    {"month": 1, "year": 2026, "total": 200000},
    {"month": 2, "year": 2026, "total": 220000}
  ]
}
```

### Test Pattern for Auth Fixture
When testing endpoints that use `auth_client` fixture, ALWAYS:
1. Create user → `set_auth_user(user)` → try/finally with `clear_auth()` + `db.close()`
2. Without `set_auth_user`, requests return 403

```python
@pytest.mark.asyncio
async def test_stats_with_auth(self, auth_client):
    db = TestingSessionLocal()
    user = create_user(db, tier=UserTier.FREE, email="test@test.com", firebase_uid="uid_test")
    set_auth_user(user)
    try:
        resp = await auth_client.get("/api/v1/subscriptions/stats/summary")
        assert resp.status_code == 200
        data = resp.json()
        assert "summary" in data
        assert "monthly_trend" in data
        assert len(data["monthly_trend"]) == 12
    finally:
        clear_auth()
        db.close()
```

## Proof URL Fix (June 2026)

### Problem
`save_proof_file()` returned local filesystem path (`/app/uploads/payment_proofs/xxx.jpg`) instead of HTTP URL. Mobile app's `Image.network()` couldn't load the image.

### Solution
1. Mount static files in `main.py`: `app.mount("/uploads", StaticFiles(directory="/app/uploads"))`
2. Update `save_proof_file()` to return URL path: `/uploads/payment_proofs/{payment_id}/{filename}`
3. Update `delete_proof_file()` to handle URL paths (strip `/uploads/` prefix, prepend `/app/` for filesystem operations)
4. Update all endpoints returning `proof_url`/`file_url` to prepend `https://{DOMAIN}`
5. Add `DOMAIN` config to `app/config.py` (default: `localhost:8000`)

### Data Migration
Old proof records in DB had full filesystem path. Run migration:
```sql
UPDATE payment_proofs 
SET file_url = REPLACE(file_url, '/app/uploads/payment_proofs/', '/uploads/payment_proofs/')
WHERE file_url LIKE '/app/uploads/%';
```

## Delete Proof Permission Fix (June 2026)

### Problem
`DELETE /{vault_id}/payments/{payment_id}/proof` only allowed the payment owner to delete. Vault owner couldn't delete proofs.

### Solution
Changed permission check to allow BOTH payment owner AND vault owner:
```python
is_payment_owner = member and member.user_id == current_user.id
is_vault_owner = vault.owner_id == current_user.id
if not is_payment_owner and not is_vault_owner:
    raise HTTPException(status_code=403, detail="You are not allowed to delete this proof")
```

## Proof Upload/Delete Status Check Fix (June 17 2026)

### Problem
Upload proof and delete proof endpoints used `not in (PENDING, PAID)` to check if action is allowed. This blocked actions on `AWAITING_CONFIRM` status — but member should be able to delete/re-upload proof as long as owner hasn't confirmed.

### Solution
Changed both endpoints to only block `CONFIRMED` status:
```python
# Before (wrong):
if payment.status not in (FamilyPaymentStatus.PENDING, FamilyPaymentStatus.PAID):
    raise HTTPException(status_code=400, detail="Cannot upload/delete proof for confirmed payment")

# After (correct):
if payment.status == FamilyPaymentStatus.CONFIRMED:
    raise HTTPException(status_code=400, detail="Cannot upload/delete proof for confirmed payment")
```

### Affected Endpoints
- `POST /{vault_id}/payments/{payment_id}/proof` (upload_proof)
- `DELETE /{vault_id}/payments/{payment_id}/proof` (delete_proof)

### Test Added
- `test_delete_proof_awaiting_confirm` — verifies delete works when status is AWAITING_CONFIRM
- 115 tests passing after fix

## Removed Endpoint (June 2026)

`GET /{vault_id}/subscriptions/{sub_id}` — removed because Flutter already uses `SubscriptionDetailScreen` which hits `GET /subscriptions/{id}`.

## Files Changed
- `app/routes/subscriptions.py` — added query params + monthly_trend to stats/summary, added /stats/trend endpoint
- `app/services/stats_service.py` — new file with `get_monthly_trend()` logic
- `app/routes/family.py` — fixed delete proof permission, removed getVaultSubscriptionDetail
- `app/main.py` — added Firebase init + static files mount
- `app/config.py` — added DOMAIN config
- `tests/test_endpoints.py` — added 3 new tests for stats endpoint
- All 114 tests passing after fixes
