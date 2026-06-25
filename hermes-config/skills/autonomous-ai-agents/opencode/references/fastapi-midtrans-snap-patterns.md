# FastAPI + Midtrans Snap Patterns

Project-specific patterns discovered during SubTrack ID backend development.

## Midtrans Snap Token Generation

`midtransclient.Snap.create_transaction()` returns a **plain string token**, NOT a dict.

```python
# WRONG — will crash with TypeError: string indices must be integers
response = snap.create_transaction(snap_params)
token = response["token"]

# CORRECT — handle both string and dict responses
response = snap.create_transaction(snap_params)
snap_token = response["token"] if isinstance(response, dict) else response
redirect_url = (
    response.get("redirect_url")
    if isinstance(response, dict)
    else f"https://app.sandbox.midtrans.com/snap/vtweb/{snap_token}"
)
```

### Signature Verification (Webhook)

Midtrans webhook signature = `SHA512(order_id + status_code + gross_amount + server_key)`.

```python
import hashlib

def verify_midtrans_signature(data: dict, server_key: str) -> bool:
    order_id = data.get("order_id", "")
    status_code = data.get("status_code", "")
    gross_amount = data.get("gross_amount", "")
    signature_key = data.get("signature_key", "")
    raw = order_id + status_code + gross_amount + server_key
    computed = hashlib.sha512(raw.encode()).hexdigest()
    return hmac.compare_digest(computed, signature_key)
```

**Dev/test safety:** Skip verification when `server_key` is empty or placeholder.

## FastAPI Auth Override Pattern for Testing

Override `get_current_user` dependency in test client:

```python
from app.utils.auth import get_current_user

def override_auth(user):
    async def _override():
        return user
    return _override

# In test setup:
app.dependency_overrides[get_current_user] = override_auth(test_user)

# Cleanup after test:
app.dependency_overrides.pop(get_current_user, None)
```

## SQLite UUID Comparison

SQLAlchemy UUID columns need explicit `cast` for SQLite test compatibility:

```python
# WRONG — SQLite can't compare UUID type with string
subscription = db.query(Subscription).filter(Subscription.id == data.subscription_id).first()

# CORRECT — explicit cast
from uuid import UUID
subscription = db.query(Subscription).filter(Subscription.id == UUID(data.subscription_id)).first()
```

## Webhook Idempotency Pattern

Always check payment status before processing webhook to prevent double-processing:

```python
if payment.status == PaymentStatus.COMPLETED:
    return {"message": "OK"}  # Already processed, skip
```

## Payment Model: order_id = payment.id

When using `payment.id` (UUID) as Midtrans `order_id`, the webhook lookup must convert the incoming string back to UUID:

```python
try:
    payment_id = uuid.UUID(order_id)
except ValueError:
    return {"message": "Payment not found"}

payment = db.query(Payment).filter(Payment.id == payment_id).first()
```

**Test tip:** When creating test payments for webhook tests, explicitly set `id=UUID(order_id)` so the webhook can find them by `Payment.id`.

## Enum Name/Value Consistency (Critical)

PostgreSQL enum values are case-sensitive. Python `str, Enum` member names MUST match the DB enum values exactly:

```python
# CORRECT — DB has lowercase: pending, completed, midtrans
class PaymentStatus(str, Enum):
    pending = "pending"
    completed = "completed"

class PaymentMethod(str, Enum):
    midtrans = "midtrans"

# WRONG — causes AttributeError at runtime
class PaymentMethod(str, Enum):
    MIDTRANS = "midtrans"  # PaymentMethod.MIDTRANS crashes
```

**Symptom:** `AttributeError: MIDTRANS` or `'str' object has no attribute 'hex'` during SQLAlchemy serialize.

**Rule:** Always use lowercase member names matching DB values exactly.
