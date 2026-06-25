# Midtrans E2E Test Recipe

## Compute a Valid Webhook Signature for Testing

When hitting the webhook with `curl` or from `docker exec`, the signature must match or the handler silently returns `{"message": "OK"}` without processing anything.

```python
import hashlib

server_key = "your-server-key-here"  # from .env MIDTRANS_SERVER_KEY
order_id = "54b1f01f-e5be-439d-bfc9-8ed55d262315"  # str(payment.id)
status_code = "200"
gross_amount = "39000.00"

raw = f"{order_id}{status_code}{gross_amount}{server_key}"
signature = hashlib.sha512(raw.encode()).hexdigest()
```

**Rules:**
- Raw string concatenation, NO separators
- `gross_amount` must match exactly what Midtrans sends (string with cents, e.g. `"39000.00"`)
- `server_key` is the actual key value, not the env var name

## Create Payment Record for Webhook Testing

When creating a payment record manually (to then hit the webhook), all NOT NULL fields must be set:

```python
from datetime import datetime, timedelta
from app.models.payment import Payment, PaymentMethod, PaymentStatus

payment = Payment(
    user_id=user.id,
    amount=39000,
    currency="IDR",
    method=PaymentMethod.midtrans,
    status=PaymentStatus.pending,
    plan="pro",
    period="monthly",
    expires_at=datetime.utcnow() + timedelta(days=30),  # REQUIRED - NOT NULL
)
db.add(payment)
db.commit()
db.refresh(payment)
```

## Docker Exec Pattern for Testing

```bash
# Run Python inside container
docker exec subtrack-api python3 -c "..."

# Hit internal endpoint from container
docker exec subtrack-api python3 -c "
import httpx, asyncio
async def test():
    async with httpx.AsyncClient() as client:
        r = await client.post('http://localhost:8000/api/v1/payments/webhook/midtrans', json=payload)
        print(r.status_code, r.text)
asyncio.run(test())
"

# Check DB state
docker exec subtrack-api python3 -c "
from app.database import SessionLocal
from app.models.payment import Payment, PaymentStatus
from app.models.user import User, UserTier
db = SessionLocal()
# ... query and verify
db.close()
"
```

## Notes
- `snap.create_transaction()` returns a **dict** in current midtransclient (not bare string). Use `result["token"]` primarily but keep isinstance guard.
- `transaction_token` column on Payment is set by the `/create` endpoint but **not used by webhook** — webhook looks up by `Payment.id == UUID(order_id)`.
- Backend runs via `docker-compose up -d` in `backend/` directory. Port 8000 inside container, mapped to 8002 on host.