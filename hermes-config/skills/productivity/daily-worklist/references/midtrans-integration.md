# Midtrans Snap Integration Reference

## Quick Reference for FastAPI + Midtrans Snap

### Snap Token Generation

```python
import midtransclient

snap = midtransclient.Snap(
    is_production=settings.MIDTRANS_IS_PRODUCTION,
    server_key=settings.MIDTRANS_SERVER_KEY,
)

result = snap.create_transaction({
    "transaction_details": {
        "order_id": str(payment.id),
        "gross_amount": price,
    },
    "customer_details": {
        "email": user.email,
        "first_name": user.display_name or user.email.split("@")[0],
    },
    "item_details": [{
        "id": "pro-monthly",
        "price": price,
        "quantity": 1,
        "name": "SubTrack PRO (monthly)",
    }],
    "expiry": {"unit": "day", "duration": 1},
})

snap_token = result["token"]
redirect_url = result["redirect_url"]
```

### Webhook Signature Verification

```python
import hashlib

def verify_midtrans_signature(data: dict, server_key: str) -> bool:
    order_id = data.get("order_id", "")
    status_code = data.get("status_code", "")
    gross_amount = data.get("gross_amount", "")
    signature_key = data.get("signature_key", "")
    raw = order_id + status_code + gross_amount + server_key
    computed = hashlib.sha512(raw.encode()).hexdigest()
    return computed == signature_key
```

### Idempotent Webhook Handler Pattern

```python
if payment.status == PaymentStatus.COMPLETED:
    return {"message": "OK"}

# capture/settlement -> COMPLETED
# pending -> keep PENDING
# deny/cancel/expire -> FAILED

if payment.plan == "pro":
    user.tier = UserTier.PRO
elif payment.plan == "family":
    user.tier = UserTier.FAMILY
```

### Gotchas Learned

1. create_transaction() returns **dict in real Midtrans API** but **plain string in sandbox/fallback**. Always use isinstance check:
   ```python
   snap_token = result["token"] if isinstance(result, dict) else result
   redirect_url = result.get("redirect_url") if isinstance(result, dict) else f"https://app.sandbox.midtrans.com/snap/vtweb/{snap_token}"
   ```
2. SQLite + UUID comparison: cast explicitly with UUID(data.subscription_id)
3. order_id = payment.id (UUID) must be the primary key
4. Skip signature verification when server_key is empty/placeholder
5. external_transaction_id vs transaction_token — two different fields
6. Method name is create_transaction() not create_transaction_token()

### Sandbox Test Cards
- Success: 4811 1111 1111 1111
- Fail: 4911 1111 1111 1111
- Challenge: 4511 1111 1111 1113

### .env Template
MIDTRANS_SERVER_KEY=YOUR_MIDTRANS_SERVER_KEY
MIDTRANS_CLIENT_KEY=Mid-client-xxxxxxxxxxxx
MIDTRANS_IS_PRODUCTION=false