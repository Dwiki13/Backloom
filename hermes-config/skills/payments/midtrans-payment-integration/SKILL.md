---
name: midtrans-payment-integration
description: Midtrans Snap API integration patterns — sandbox testing, webhook handling, signature verification, and end-to-end payment flow debugging.
tags: [payments, midtrans, e2e-testing, webhook, snap-api]
---

# Midtrans Payment Integration

Payment integration patterns for Midtrans Snap API — sandbox testing, webhook handling, and end-to-end verification.

## Sandbox Testing Setup

### Generate Snap Token (server-side)

```python
import midtransclient
from app.config import settings

snap = midtransclient.Snap(
    is_production=settings.MIDTRANS_IS_PRODUCTION,
    server_key=settings.MIDTRANS_SERVER_KEY,
)
result = snap.create_transaction(snap_params)
snap_token = result["token"] if isinstance(result, dict) else result
redirect_url = result.get("redirect_url") if isinstance(result, dict) else f"https://app.sandbox.midtrans.com/snap/vtweb/{snap_token}"
```

**Important:** `snap.create_transaction()` returns a dict with `token` and `redirect_url` in production, but can return a plain string in some SDK versions. Always handle both:
```python
snap_token = result["token"] if isinstance(result, dict) else result
```

### Sandbox Payment Page (browser)

- Payment page URL: `https://app.sandbox.midtrans.com/snap/v4/redirection/<token>`
- Snap tokens expire in 1 day — generate fresh tokens immediately before testing
- **GoPay/ShopeePay redirect to QRIS** which can't be scanned with regular e-wallet apps in sandbox
- **Credit Card** test numbers don't reliably work in Midtrans sandbox
- **BCA Virtual Account** is the most reliable sandbox method — but has no "Pay" button; must settle from dashboard
- **Dana/OVO** — e-wallet options that may appear in sandbox

### Sandbox-to-Webhook Testing via ngrok

When backend runs on localhost, Midtrans can't reach it. Use ngrok:

```bash
# Start ngrok
ngrok http 8002

# Check URL
curl -s http://127.0.0.1:4040/api/tunnels | python3 -c "
import sys,json
d=json.load(sys.stdin)
for t in d.get('tunnels',[]):
    print('URL:', t['public_url'])
"
```

Set the ngrok URL as webhook in [Midtrans Dashboard](https://dashboard.sandbox.midtrans.com) → Settings → Configuration → Payment Notification URL.

**Ngrok requires an account.** Free tier needs signup at dashboard.ngrok.com.

## Webhook Implementation

### Signature Verification (mandatory for production)

```python
import hashlib, hmac

def verify_midtrans_signature(data: dict, server_key: str) -> bool:
    order_id = data.get("order_id", "")
    status_code = data.get("status_code", "")
    gross_amount = data.get("gross_amount", "")
    signature_key = data.get("signature_key", "")
    raw = order_id + status_code + gross_amount + server_key
    computed = hashlib.sha512(raw.encode()).hexdigest()
    return hmac.compare_digest(computed, signature_key)
```

**Dev bypass:** Skip signature verification when `MIDTRANS_SERVER_KEY` is empty/placeholder to allow local testing.

### Webhook Status Mapping

| Midtrans Status | Action |
|----------------|--------|
| `capture` + `fraud_status=accept` | COMPLETED |
| `capture` + `fraud_status=challenge` | Keep PENDING |
| `settlement` | COMPLETED |
| `pending` | Keep PENDING |
| `deny` / `expire` | FAILED |
| `cancel` | FAILED or CANCELLED |

### Idempotency

Always check `payment.status == PaymentStatus.COMPLETED` before processing to prevent double-upgrade.

### order_id Convention

Use `str(payment.id)` (UUID) as `order_id` — simple, traceable. Webhook handler must try `uuid.UUID(order_id)` and handle `ValueError` for non-UUID order IDs.

## Testing Patterns

### End-to-end test script structure

```python
# 1. Generate token
result = snap.create_transaction(params)
token = result["token"] if isinstance(result, dict) else result

# 2. Create payment record in DB with matching id
payment = Payment(id=uuid.UUID(order_id), status=PENDING, ...)
db.commit()

# 3. Build webhook signature
raw = order_id + status_code + gross_amount + server_key
sig = hashlib.sha512(raw.encode()).hexdigest()

# 4. Call webhook
resp = await client.post("/webhook/midtrans", json={...})

# 5. Verify
assert payment.status == PaymentStatus.COMPLETED
assert user.tier == UserTier.PRO  # upgraded
```

### Common Pitfalls

1. **Webhook returns 200 OK even when signature fails** — If `verify_midtrans_signature` doesn't match, handler returns `{"message": "OK"}` early without processing the payment. The response looks like success but no status update happens. Always log or surface signature failures in dev so silent no-ops are visible.
2. **UUID comparison in SQLite** — SQLite can't compare UUID type with string. Use explicit `UUID()` cast in queries.
3. **Payment.id must equal webhook order_id** — if tests generate random order_id but DB auto-generates payment.id, webhook won't find the payment.
4. **ngrok URL changes on restart** — free tier ngrok URLs are ephemeral. Always check current URL before testing.
5. **Midtrans sandbox card validation** — sandbox rejects most test card numbers. Use VA or e-wallet for reliable testing.
6. **Token expiry** — snap tokens expire in 24h. Generate immediately before browser test.
7. **SQLAlchemy enum name must match DB value** — Python enum `.name` (e.g. `MIDTRANS`) must equal the PostgreSQL enum value (e.g. `midtrans`) exactly. If they differ, reads fail with `LookupError: 'midtrans' is not among the defined enum values`. Fix: use lowercase names matching DB values (`midtrans = "midtrans"`), then rebuild container. See vps-database-admin skill → references/sqlalchemy-enum-mismatch.md.
8. **`expires_at` is NOT NULL** — the `payments` table requires `expires_at`. Always set it (e.g. `datetime.utcnow() + timedelta(days=30)`) when creating payment records manually for testing.
9. **Route files location** — SubTrack ID routes live in `app/routes/` (not `app/routers/` or `app/api/v1/endpoints/`). The main payments route is `app/routes/payments.py`.
10. **`docker-compose` command** — use `docker-compose` (hyphen) not `docker compose` (space) on this project. Compose file is at `backend/docker-compose.yml`. Networks: `backend_net` for internal, `npm_default` for nginx-proxy-manager access. DATABASE_URL in `.env` uses `postgres` (container name), not `localhost`.

## Sandbox Testing Quick Reference

- **Test card**: `4811 1111 1111 1111` (VISA), expiry `12/28`, CVV `123`
- **Preferred method**: Credit Card (QRIS can't be scanned in sandbox; VA has no "Pay" button)
- **Token generation**: see `references/sandbox-test-guide.md` for the one-liner script
- **Webhook URL**: `https://<ngrok-or-domain>/api/v1/payments/webhook/midtrans`
- **Common pitfalls**: expiry must be future date; ngrok dies frequently — restart before testing; `expires_at` is NOT NULL in DB
- **Route location**: `app/routes/payments.py` (not `app/routers/`)

See `references/sandbox-test-guide.md` for the full sandbox test card details, common errors, and token generation script.
See `references/e2e-test-recipe.md` for signature computation, payment record creation, docker exec patterns, and gotchas for end-to-end testing.

## Trigger Conditions

Use this skill when:
- Implementing or modifying Midtrans Snap payment flow
- Debugging payment webhook issues
- Setting up sandbox testing environment
- Testing end-to-end payment flows
