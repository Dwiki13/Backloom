# SubTrack ID — Schema & Webhook Details

## family_payments Table

### Status Column
- **DB type**: `varchar` (NOT enum) — `family_payment_status` enum does NOT exist in PostgreSQL
- **Model**: Uses `PaymentStatus` enum (shared with `payments` table) via `SQLEnum(PaymentStatus, values_callable=lambda x: [e.value for e in x])`
- **Import**: `from app.models.family_payment import FamilyPayment, PaymentStatus as FamilyPaymentStatus`
- **Values**: `pending`, `completed`, `failed`, `refunded`, `cancelled` (same as `payments.status`)
- **Pitfall**: Do NOT create a separate `FamilyPaymentStatus` enum — it will conflict with `payment_status` enum in PostgreSQL (same type name, different values)

### Columns
| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| id | uuid | NO | gen_random_uuid() |
| vault_id | uuid | NO | — |
| member_id | uuid | NO | — |
| subscription_id | uuid | YES | — |
| amount | float | NO | — |
| amount_paid | float | YES | 0 |
| month | integer | NO | — |
| year | integer | NO | — |
| status | varchar | YES | 'pending' |
| paid_at | timestamp | YES | — |
| confirmed_by | uuid | YES | — |

### Relationships
- `vault` → `FamilyVault` (backref: `payments`, passive_deletes=True)
- `member` → `FamilyMember` (backref: `payments`, passive_deletes=True)
- `subscription` → `Subscription` (backref: `family_payments`)
- `confirmer` → `User` (backref: `confirmed_payments`)

## payments Table

### Status Column
- **DB type**: `payment_status` enum (USER-DEFINED)
- **Model**: `SQLEnum(PaymentStatus, values_callable=lambda x: [e.value for e in x])`
- **Values**: `pending`, `completed`, `failed`, `refunded`, `cancelled`

### transaction_token Column
- **Added manually** via `ALTER TABLE payments ADD COLUMN transaction_token VARCHAR;`
- **Not in Alembic migration** — was added via raw SQL for Midtrans Snap integration
- If rebuilding DB from scratch, add to migration

## Midtrans Webhook Signature Verification

### Algorithm
```
signature = SHA512(order_id + status_code + gross_amount + server_key)
```

### Python Implementation
```python
import hashlib

def verify_midtrans_signature(data: dict, server_key: str) -> bool:
    order_id = data.get("order_id", "")
    status_code = data.get("status_code", "")
    gross_amount = data.get("gross_amount", "")
    signature_key = data.get("signature_key", "")
    
    computed = hashlib.sha512(
        f"{order_id}{status_code}{gross_amount}{server_key}".encode()
    ).hexdigest()
    
    return computed == signature_key
```

### Testing Webhook Signature
```python
import hashlib
server_key = "your-server-key"
order_id = "uuid-here"
sig = hashlib.sha512(f"{order_id}20039000.00{server_key}".encode()).hexdigest()
```

### Webhook Returns 200 Even on Missing Payment
By design — prevents Midtrans from retrying. Always return `{"message": "OK"}`.

## Alembic Migration Chain (as of 2026-06-14)

```
a581483d9ec5 → b89515fc83b6 → c1d2e3f4a5b6 → d2e3f4a5b6c7 → f3a4b5c6d7e8 → a1b2c3d4e5f6 (head)
```

| Revision | Description |
|----------|-------------|
| a581483d9ec5 | add ocr_detect_count to users |
| b89515fc83b6 | add family_payments table |
| c1d2e3f4a5b6 | add ondelete cascade to family_members FKs |
| d2e3f4a5b6c7 | fix all FK constraints for vault delete cascade |
| f3a4b5c6d7e8 | force recreate all constraints for vault delete |
| a1b2c3d4e5f6 | fix family_payments and FK constraints (head) |

### Verify Chain
```bash
docker-compose exec -T api alembic history --verbose
```

### Check Current Head
```bash
docker-compose exec -T api alembic current
```

## Docker Compose Rebuild Pattern (When Container on Wrong Network)

When `docker-compose up -d --build` doesn't pick up code changes because the container is on a different network or using a cached image:

```bash
# Step 1: Remove old container
docker rm -f subtrack-api

# Step 2: Rebuild without cache
cd /root/projects/subtrack-id/backend
docker-compose build --no-cache api

# Step 3: Start (attaches to networks defined in docker-compose.yml)
docker-compose up -d api

# Step 4: Verify network attachment
docker inspect subtrack-api --format '{{json .NetworkSettings.Networks}}'
```

### Network Requirements
- `subtrack-api` must be on `backend_net` (to reach `postgres`) and `npm_default` (to reach NPM proxy)
- `postgres` is on `backend_net` and `npm_default`
- If container is on `bridge` (default), it CANNOT reach `postgres` by name

## Database Credentials (Dev/Staging)

| Setting | Value |
|---------|-------|
| Host | postgres (container name) / localhost (from host) |
| Port | 5432 |
| User | hermes |
| Password | hermespassword |
| Database | subtrack (dev) / hermesdb (prod) |

> ⚠️ These are development credentials. Production uses different values set in `.env.production`.
