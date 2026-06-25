# SubTrack ID — Midtrans Payment Integration

> June 14 2026. Apply when working on payment/subscription features in `/root/projects/subtrack-id/`.

## Midtrans Snap Token API

### Correct Method
Use `snap.create_transaction(snap_params)` — **NOT** `create_transaction_token()`. The latter doesn't exist in `midtransclient` v1.4.2.

### Response Format
Returns a **dict** (not string):
```python
result = snap.create_transaction(snap_params)
snap_token = result["token"]          # UUID-like string
redirect_url = result["redirect_url"]  # Full sandbox/prod URL
```

### Sandbox URL Pattern
```
https://app.sandbox.midtrans.com/snap/v4/redirection/{snap_token}
```

### Config
```python
import midtransclient
snap = midtransclient.Snap(
    is_production=settings.MIDTRANS_IS_PRODUCTION,  # False for dev
    server_key=settings.MIDTRANS_SERVER_KEY,
)
```

### order_id Convention
Use `str(payment.id)` (UUID) as `order_id`. This makes webhook lookup simple: `Payment.id == UUID(order_id)`.

## Webhook Signature Verification

### Algorithm
```
signature = SHA512(order_id + status_code + gross_amount + server_key)
```
All four fields are concatenated as strings, then hashed with SHA-512.

### Code Pattern
```python
import hashlib, hmac
def verify_signature(data: dict, server_key: str) -> bool:
    raw = data["order_id"] + data["status_code"] + data["gross_amount"] + server_key
    computed = hashlib.sha512(raw.encode()).hexdigest()
    return hmac.compare_digest(computed, data["signature_key"])
```

### Important: Graceful When Key Empty
In dev/test when `MIDTRANS_SERVER_KEY` is placeholder, signature will never match. Return `{"message": "OK"}` (acknowledge but don't process) so Midtrans doesn't retry — don't raise 400.

## Webhook Status Mapping

| Midtrans Status | Payment Status | Action |
|----------------|----------------|--------|
| `settlement` | `COMPLETED` | Upgrade tier |
| `capture` + `fraud_status=accept` | `COMPLETED` | Upgrade tier |
| `capture` + `fraud_status=challenge` | `FAILED` | — |
| `pending` | `PENDING` | No action (VA/transfer unpaid) |
| `deny` | `FAILED` | — |
| `cancel` | `CANCELLED` | — |
| `expire` | `FAILED` | — |

## Idempotency
Midtrans may send duplicate webhooks. Always check before processing:
```python
if payment.status == PaymentStatus.COMPLETED:
    return {"message": "OK"}  # already processed
```

## Webhook Lookup
**order_id = Payment.id (UUID)**, not `external_transaction_id`. If the `order_id` is not a valid UUID, the payment won't be found — that's by design (ignores foreign order IDs).

## SQLite Test Pitfalls

### UUID Comparison in Routes
SQLite can't compare UUID columns with raw strings. Always cast:
```python
from uuid import UUID
# In route handlers:
subscription = db.query(Subscription).filter(Subscription.id == UUID(data.subscription_id)).first()
payment = db.query(Payment).filter(Payment.id == UUID(data.payment_id)).first()
```

### Test Fixture Pattern
When creating test payments that webhooks will look up, the `Payment.id` must match the `order_id` used in the webhook signature:
```python
from uuid import uuid4, UUID
order_id = str(uuid4())
pay = Payment(
    id=UUID(order_id),      # <-- matches order_id
    external_transaction_id=order_id,
    ...
)
```

### Signature in Tests
Compute against the **actual** `settings.MIDTRANS_SERVER_KEY`, not a hardcoded value. During tests the key comes from `.env`.

## Secret .env File Rule

**NEVER attempt to read `.env` files.** They are blocked by security policy. When the user provides API keys:
1. Tell them the path and let them edit manually
2. Verify the key loaded by checking prefix only: `settings.SOME_KEY[:10]`
3. Do NOT log, print, or echo the full key value

## Sandbox Testing

### Test Card (Success)
- Number: `4811 1111 1111 1111` (VISA)
- Expiry: `01/26` (must be future date — `01/25` fails as expired)
- CVV: `123`

### Test Card (Fail)
- Number: `4911 1111 1111 1111`

### Sandbox Gotchas
- GoPay/QRIS in sandbox redirects to QRIS scan — cannot scan with real payment apps. Use Credit Card or Virtual Account for reliable sandbox testing.
- QRIS simulator only works via Midtrans Dashboard, not via payment page.
- Sandbox VA (BCA, Mandiri, BNI) works — click "Pay" and it auto-settles.

### Local Webhook Testing via Ngrok
When backend runs on localhost and Midtrans can't reach it:
```bash
ngrok http 8002
# Use the https URL as webhook URL in Midtrans Dashboard
# URL changes on restart — always verify with: curl http://127.0.0.1:4040/api/tunnels
```
Ngrok requires a free account — sign up at dashboard.ngrok.com, get authtoken, run `ngrok config add-authtoken <token>`.

## Production Checklist
- [ ] `MIDTRANS_IS_PRODUCTION=true` in `.env`
- [ ] Production server/client keys (not `YOUR_MIDTRANS_SERVER_KEY...` sandbox prefix)
- [ ] Webhook URL set in Midtrans Dashboard → Settings → Configuration
- [ ] SSL on API domain (https required for production webhooks)
- [ ] Signature verification enforced (not skipped)
