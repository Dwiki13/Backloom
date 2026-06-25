# SubTrack ID — Docker & Database Troubleshooting

## Common Docker Issues

### KeyError: 'ContainerConfig' during docker-compose up -d
Old docker-compose versions (v1.29) fail with `KeyError: 'ContainerConfig'` when trying to recreate a container that has stale config.

**Reliable rebuild sequence**:
```bash
cd /root/projects/subtrack-id/backend
docker-compose stop api
docker-compose rm -f api
docker-compose build --no-cache api
docker-compose up -d
```

**Quick restart without full rebuild** (when only route/service code changed, no model changes):
```bash
docker-compose stop api
docker-compose rm -f api
docker-compose up -d api
```

**Avoid**: `docker-compose down && docker-compose up -d --build` on old docker-compose — can trigger same ContainerConfig error.

### Container tidak rebuild setelah code edit
`docker-compose restart saja TIDAK cukup` — dia pakai image lama.
Solusi:
```bash
cd /root/projects/subtrack-id/backend
docker-compose build --no-cache api
docker-compose up -d
```

### Port mapping hilang setelah rebuild
Setelah `up -d`, container bisa jalan tanpa port mapping ke host.
Solusi: pastikan `docker-compose.yml` punya `ports: - "8000:8000"`, lalu `docker-compose down && docker-compose up -d`.

### Container bisa connect tapi query error
Biasanya karena env var `DATABASE_URL` terbaca dari file yang salah (volume mount vs .env).
Cek: `docker exec subtrack-api env | grep DATABASE`

### Old container masih jalan
`docker ps` → cek ada container lama dengan nama sama. Hapus: `docker rm -f subtrack-api`

## Database Schema Reference

### Enums (lowercase!)

Two Payment Status enums — DO NOT MIX UP:

| Enum | Name | Values | Used In |
|------|------|--------|---------|
| `PaymentStatus` | `payment_status` | pending, completed, failed, refunded, cancelled | `payments` table (subscription payments) |
| `FamilyPaymentStatus` | `family_paymentstatus` | PENDING, PAID, OVERDUE, CONFIRMED | `family_payments` table (family vault payments) |

**Common bug**: Importing `PaymentStatus` from `payment.py` and aliasing as `FamilyPaymentStatus`. This causes enum value mismatches — the two enums have DIFFERENT values and DIFFERENT meanings.

Correct: `FamilyPaymentStatus` is defined in `family_payment.py`, imported directly:
```python
from app.models.family_payment import FamilyPayment, FamilyPaymentStatus
```

| Enum Type | Values |
|-----------|--------|
| `payment_status` | pending, completed, failed, refunded, cancelled |
| `family_paymentstatus` | pending, awaiting_confirm, paid, overdue, confirmed |
| `payment_method` | midtrans, stripe, manual |
| `family_role` | admin, member |
| `user_tier` | FREE, PRO, FAMILY |
| `billing_cycle` | weekly, monthly, quarterly, yearly |
| `category` | entertainment, productivity, health, education, finance, shopping, food, other |

**⚠️ Enum Migration Gotcha**: When adding new enum values (e.g. `AWAITING_CONFIRM`), old data with removed values causes `LookupError` on query. Always check and clean stale values BEFORE deploying code with new enum definition:
```sql
SELECT DISTINCT status FROM family_payments WHERE status NOT IN ('pending','awaiting_confirm','paid','overdue','confirmed');
UPDATE family_payments SET status = 'confirmed' WHERE status = 'completed';
```

### Key Tables
- **users** — id (UUID PK), email, firebase_uid, tier, display_name
- **subscriptions** — id, user_id (FK), name, website_url, price, currency, billing_cycle, category, next_billing_date (NOT NULL!), is_trial, trial_ends_at, is_active
- **family_vaults** — id, name, owner_id (FK→users), invite_code (UNIQUE), max_members
- **family_members** — id, vault_id (FK cascade), user_id (FK), role (admin/member), share_percentage
- **family_payments** — id, vault_id (FK cascade), member_id (FK cascade), subscription_id (FK SET NULL), amount, amount_paid, month (int), year (int), status (FamilyPaymentStatus), paid_at, confirmed_by
- **payments** — id, user_id (FK), amount, currency, method, status (PaymentStatus), plan, period, external_transaction_id, transaction_token, completed_at, expires_at (NOT NULL!), created_at
- **payment_proofs** — id, payment_id (FK), member_id (FK), file_url, file_type, amount, note, created_at
- **notifications** — id, user_id (FK), title, body, data, is_read, created_at

### Cached DB workspace
Cache DB accessible via: `docker exec subtrack-api psql -U hermes -d hermesdb`
Has separate `test.db`, `test_endpoints.db`, `test_migration.db` SQLite files (not prod).

### Critical Column Name Differences

| What you want | Wrong column | Correct column | Table |
|---|---|---|---|
| Member join date | `created_at` | `joined_at` | `family_members` |
| Member PK | `member_id` | `id` | `family_members` |

**Real bug**: `generate_family_payments` Celery task referenced `member.created_at` but column is `joined_at`. Caused all members to be skipped (falsy value), so no payments were ever generated. Fix: use defensive pattern `getattr(member, 'joined_at', None) or getattr(member, 'created_at', None)`.

### Ngrok free plan gotcha
Free plan restarts give **new URLs**. Always re-check output of `ngrok http 8002`.
If webhook stops working after a restart, check if URL changed — update Midtrans Dashboard.

### Firebase API key invalid (June 14)
Cannot exchange custom tokens via REST API — `identitytoolkit.googleapis.com` returns 400 "API key not valid".
Workaround: create payment records directly in PostgreSQL for testing, or use existing user tokens from the Flutter app.

## Midtrans Testing Pattern

### Create payment → Webhook → Tier upgrade
1. Create Payment object in DB directly (via Python script in container)
2. Generate valid SHA512 signature_key: `hashlib.sha512(f"{order_id}{status_code}{gross_amount}{server_key}".encode()).hexdigest()`
3. POST to `localhost:8000/api/v1/payments/webhook/midtrans` with signature
4. Verify: payment.status → completed, user.tier → PRO/FAMILY

### Ngrok for webhook
```bash
ngrok http 8002  # exposes localhost:8002
```
URL set in: Midtrans Dashboard → Settings → Webhook URL
