# SQLAlchemy SQLEnum vs PostgreSQL Enum Value Mismatch

## Problem

Two distinct failure modes when Python enum names differ from PostgreSQL enum values:

### Failure Mode 1: Write-time — `InvalidTextRepresentation` on INSERT

When a Python enum uses `str, enum.Enum` with lowercase values but uppercase names:

```python
class FamilyRole(str, enum.Enum):
    ADMIN = "admin"
    MEMBER = "member"
```

SQLAlchemy's `SQLEnum` **defaults to using `.name`** (uppercase `ADMIN`, `MEMBER`), NOT `.value` (lowercase `admin`, `member`). PostgreSQL rejects the insert:

```
sqlalchemy.exc.DataError: (psycopg2.errors.InvalidTextRepresentation)
invalid input value for enum family_role: "ADMIN"
```

### Failure Mode 2: Read-time — `LookupError` on SELECT

Even if writes succeed (e.g., via raw SQL with lowercase values), **reads fail** because SQLAlchemy tries to match the DB value against enum `.name`:

```
LookupError: 'midtrans' is not among the defined enum values.
Enum name: paymentmethod. Possible values: MIDTRANS, STRIPE, MANUAL
```

This happens when:
- DB has `midtrans` (lowercase, from raw SQL insert or different model version)
- Python model has `MIDTRANS = "midtrans"` (name is uppercase)

SQLAlchemy's `SQLEnum._object_value_for_elem()` looks up by `.name`, not by `.value`.

## Root Cause

SQLAlchemy `SQLEnum` uses Python enum `.name` as the canonical key for both writes AND reads by default. `values_callable` only affects DDL generation (CREATE TABLE), NOT the Python-side value mapping at read/write time.

## Fix — The Only Reliable Approach

**Make Python enum names match the PostgreSQL enum values exactly (lowercase):**

```python
# BEFORE (broken — name mismatch):
class PaymentMethod(str, enum.Enum):
    MIDTRANS = "midtrans"   # name=MIDTRANS, value=midtrans
    STRIPE = "stripe"

# AFTER (fixed — name matches value):
class PaymentMethod(str, enum.Enum):
    midtrans = "midtrans"    # name=midtrans, value=midtrans
    stripe = "stripe"
```

This works because Python enum `.name` == `.value` == DB enum value at every layer.

**Rule: Python enum `.name` MUST equal the PostgreSQL enum value.** They are the same string at three points:
- Python: `PaymentMethod.midtrans.name` = `"midtrans"`
- Python: `PaymentMethod.midtrans.value` = `"midtrans"`
- PostgreSQL: `SELECT unnest(enum_range(NULL::payment_method))` → `midtrans`

## What About `values_callable`?

`values_callable=lambda x: [e.value for e in x]` is still needed when values differ from names, but it ONLY fixes DDL (CREATE TABLE enum labels). It does NOT fix:

1. **Write-time**: SQLAlchemy still sends `.name` to the DB unless `values_callable` is set — but even then, reads use `.name`.
2. **Read-time**: SQLAlchemy maps DB values back to enum members by `.name`, not by `.value`.

**Bottom line**: `values_callable` is necessary but not sufficient. The only complete fix is to make `.name` == DB value.

## Real-World Example (SubTrack, June 14 2026)

### Case 1: PaymentMethod table
- **DB**: `payment_method` enum with values `midtrans, stripe, manual` (lowercase)
- **Model (broken)**:
  ```python
  class PaymentMethod(str, enum.Enum):
      MIDTRANS = "midtrans"  # name=MIDTRANS ≠ DB value "midtrans"
  ```
- **Error on read**: `LookupError: 'midtrans' is not among the defined enum values. Possible values: MIDTRANS, STRIPE, MANUAL`
- **Fix**: Changed to `midtrans = "midtrans"` (name matches value)
- **Rebuild required**: YES — `docker rm -f subtrack-api && cd backend && docker-compose up -d --build api`

### Case 2: PaymentStatus table
- **DB**: `payment_status` enum with values `pending, completed, failed, refunded, cancelled` (lowercase)
- **Model (broken)**:
  ```python
  class PaymentStatus(str, enum.Enum):
      PENDING = "pending"  # name=PENDING ≠ DB value "pending"
  ```
- **Error on read**: `LookupError: 'pending' is not among the defined enum values. Possible values: PENDING, COMPLETED, ...`
- **Fix**: Changed to `pending = "pending"` (name matches value)
- **Cascading fix**: All references to `PaymentStatus.PENDING` in routes must change to `PaymentStatus.pending`

## Diagnosis Checklist

```python
# 1. Check DB enum values
# docker exec postgres psql -U hermes -d subtrack -c "SELECT unnest(enum_range(NULL::payment_method));"

# 2. Check Python enum names vs values
from app.models.payment import PaymentMethod
for e in PaymentMethod:
    print(f"name={e.name!r}, value={e.value!r}")
    assert e.name == e.value, f"MISMATCH: {e.name} != {e.value}"

# 3. Test read from DB
from app.database import SessionLocal
db = SessionLocal()
pay = db.query(Payment).first()  # If this raises LookupError → enum mismatch
db.close()
```

## Fix Workflow

1. Update model: change enum `.name` to match DB value (lowercase)
2. Update all references in routes/schemas: `PaymentMethod.MIDTRANS` → `PaymentMethod.midtrans`
3. Use `sed` for bulk replace: `sed -i 's/PaymentMethod\.MIDTRANS/PaymentMethod.midtrans/g' app/routes/payments.py`
4. Rebuild container: `docker rm -f subtrack-api && cd backend && docker-compose up -d --build api`
5. Wait 5-8s for startup, then test

## Pattern Reference

The `subscription.py` model already does this correctly with `values_callable` — but that only works when names match values OR when you accept that reads will use `.name` as the key. For new code, always use lowercase names matching DB values.
