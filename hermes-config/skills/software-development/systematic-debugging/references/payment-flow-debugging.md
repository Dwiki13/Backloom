# Payment Flow Debugging Patterns

## Common Issues and Solutions

### 1. Enum Mismatch Between Model and Database

**Symptom:**
- `LookupError: 'completed' is not among the defined enum values. Enum name: paymentstatus. Possible values: pending, paid, overdue, confirmed`
- `psycopg2.errors.InvalidTextRepresentation: invalid input value for enum payment_status: "PENDING"`

**Root Cause:**
SQLAlchemy model enum values don't match PostgreSQL database enum values exactly (case sensitivity).

**Investigation Steps:**
1. Check actual enum values in database:
   ```sql
   SELECT typname, enumlabel FROM pg_type t 
   JOIN pg_enum e ON t.oid = e.enumtypid 
   WHERE t.typtype = 'e' AND typname IN ('paymentstatus', 'paymentmethod');
   ```

2. Check model enum definitions:
   ```python
   # In app/models/payment.py
   class PaymentStatus(str, enum.Enum):
       pending = "pending"  # lowercase
       completed = "completed"
       # ...
   ```

**Solution:**
- Ensure model enum values match database values exactly (usually lowercase)
- Or use `values_callable` in SQLEnum to map properly:
  ```python
  status = Column(SQLEnum(PaymentStatus, values_callable=lambda x: [e.value for e in x]))
  ```

### 2. Payment Record Creation for Testing

**Symptom:**
- Webhook returns "Payment not found" even when payment exists
- Payment status doesn't update after webhook

**Root Cause:**
Test payment records created via direct SQL/SQLite scripts don't match production schema or are in wrong database.

**Investigation Steps:**
1. Verify payment record exists in correct database:
   ```sql
   SELECT * FROM payments WHERE id = 'your-uuid-here';
   ```

2. Check that all required fields are populated (especially NOT NULL columns):
   - `expires_at` (often missing in test scripts)
   - `external_transaction_id`
   - `transaction_token`
   - Correct enum values

**Solution:**
- Always create payment records via the API endpoint: `POST /api/v1/payments/create`
- If creating directly, ensure:
  - All NOT NULL columns have values
  - Enum values match database exactly (lowercase)
  - Using correct database (PostgreSQL, not SQLite)
  - Proper relationships are set

### 3. Webhook Signature Verification Failures

**Symptom:**
- Webhook returns 200 OK but doesn't update payment status
- Backend logs show signature verification failing

**Root Cause:**
Incorrect signature key in webhook payload or mismatch in signature computation.

**Investigation Steps:**
1. Verify server key from environment:
   ```python
   from app.config import settings
   print(settings.MIDTRANS_SERVER_KEY)
   ```

2. Recompute signature correctly:
   ```python
   import hashlib
   order_id = webhook_data['order_id']  # UUID string
   status_code = webhook_data['status_code']  # e.g., "200"
   gross_amount = webhook_data['gross_amount']  # e.g., "39000.00"
   server_key = settings.MIDTRANS_SERVER_KEY
   
   # Correct format: order_id + status_code + gross_amount + server_key
   signature_string = f"{order_id}{status_code}{gross_amount}{server_key}"
   computed_signature = hashlib.sha512(signature_string.encode()).hexdigest()
   ```

**Solution:**
- Ensure webhook payload includes correct `signature_key`
- Use format: `order_id + status_code + gross_amount + server_key`
- All values as strings, no extra spaces or formatting

### 4. Docker Network Issues When Testing from Containers

**Symptom:**
- `psycopg2.OperationalError: connection to server at "localhost" (127.0.0.1), port 5432 failed: Connection refused`
- Even when database is running on host

**Root Cause:**
Inside a Docker container, `localhost` refers to the container itself, not the host machine.

**Investigation Steps:**
1. Check where the script is running:
   ```python
   import socket
   print(socket.gethostbyname('localhost'))  # Will show container IP, not host
   ```

2. Verify actual database host:
   - From host: `localhost:5432` works
   - From container: need host machine IP or service name

**Solution:**
- When running scripts inside containers:
  - Use host machine's IP address (e.g., `172.17.0.1` on default bridge network)
  - Or better: use docker-compose to run scripts in same network as database
  - Example: `docker-compose run --rm api python script.py`

### 5. Missing Columns After Model Changes

**Symptom:**
- `psycopg2.errors.UndefinedColumn: column "transaction_token" does not exist`

**Root Cause:**
Database schema hasn't been updated to match current models (missing migrations).

**Investigation Steps:**
1. Check current table schema:
   ```sql
   \d payments
   ```

2. Compare with model definition:
   ```python
   # In app/models/payment.py
   transaction_token = Column(String(255))
   ```

**Solution:**
- Run migrations: `alembic upgrade head`
- Or if developing and data loss is acceptable: `alembic revision --autogenerate` then `alembic upgrade head`
- For immediate testing: add column via raw SQL:
  ```sql
  ALTER TABLE payments ADD COLUMN transaction_token VARCHAR(255);
  ```

## Verification Checklist

After fixing payment flow issues, verify:

1. [ ] Payment record created via API has all required fields populated
2. [ ] Enum values in database match model expectations (use lowercase)
3. [ ] Webhook endpoint returns 200 OK with correct signature
4. [ ] Payment status updates from `pending` to `completed` on settlement
5. [ ] Related entities update correctly (e.g., user tier FREE → PRO)
6. [ ] Timestamp fields like `completed_at` are populated
7. [ ] No regressions in related functionality (subscription payments, family payments)

## 6. SQLAlchemy UndefinedColumn Despite Column Existing in DB

**Symptom:**
- `psycopg2.errors.UndefinedColumn: column subscriptions_1.vault_id does not exist`
- Column **does exist** in the database (verified via `information_schema.columns`)
- Migration is at `head` and includes the column addition
- Model definition includes the column

**Root Cause:**
The API container's SQLAlchemy metadata cache is stale. When a migration adds a column while the API container is running, the running process may still use old metadata that doesn't include the new column. SQLAlchemy's `SELECT` explicitly lists all columns (including the new one), causing the DB to reject the query.

**Investigation Steps:**
1. Check DB schema directly (via docker network, not from host):
   ```bash
   docker run --rm --network <net> python:3.11-slim bash -c "
   pip install psycopg2-binary -q 2>/dev/null
   python3 -c \"import psycopg2; conn=psycopg2.connect(host='<db-host>',port=5432,user='<u>',password='<p>',dbname='<db>'); cur=conn.cursor(); cur.execute('SELECT column_name FROM information_schema.columns WHERE table_name=%s ORDER BY ordinal_position',('<table_name>',)); print([r[0] for r in cur.fetchall()]); conn.close()\"
   "
   ```
2. Check alembic version in container:
   ```bash
   docker exec <api-container> python3 -c "from sqlalchemy import text; from app.database import engine; conn=engine.connect(); r=conn.execute(text('SELECT version_num FROM alembic_version')); print(r.fetchone()[0]); conn.close()"
   ```
3. Compare container uptime vs migration time:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}" | grep api
   ```
   If container was running since before the migration → stale metadata.

**Solution:**
```bash
# Restart the API container to refresh SQLAlchemy metadata
docker-compose restart api

# Or full rebuild if needed
docker-compose up -d --build api
```

**Corollary — Stale Error Logs:**
If the error log timestamp is OLDER than the migration apply time, the error may already be resolved. Check log timestamps before investigating.

**Prevention:**
- Always restart API container after running migrations in production
- For zero-downtime: rolling restart or blue-green deployment
- Verify column exists AND container has restarted before testing endpoints

## Example Test Script

```python
import hashlib
import httpx
import asyncio
from app.database import SessionLocal
from app.models.user import User
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from datetime import datetime, timedelta

async def test_payment_flow():
    db = SessionLocal()
    try:
        # Get test user
        user = db.query(User).filter(User.email == 'test123@gmail.com').first()
        if not user:
            print("ERROR: Test user not found")
            return False
            
        # Create payment via model (simulating API)
        payment = Payment(
            user_id=user.id,
            amount=39000,
            currency="IDR",
            method=PaymentMethod.midtrans,
            status=PaymentStatus.pending,
            plan="pro",
            period="monthly",
            expires_at=datetime.utcnow() + timedelta(days=30)
        )
        db.add(payment)
        db.commit()
        db.refresh(payment)
        
        # Verify payment created
        assert payment.status == PaymentStatus.pending
        print(f"✓ Payment created: {payment.id}")
        
        # Prepare webhook with correct signature
        server_key = 'YOUR_MIDTRANS_SERVER_KEY'  # from .env
        order_id = str(payment.id)
        status_code = '200'
        gross_amount = '39000.00'
        
        signature_string = f"{order_id}{status_code}{gross_amount}{server_key}"
        signature_key = hashlib.sha512(signature_string.encode()).hexdigest()
        
        # Test webhook endpoint
        async with httpx.AsyncClient() as client:
            response = await client.post(
                'http://localhost:8000/api/v1/payments/webhook/midtrans',
                json={
                    'order_id': order_id,
                    'transaction_status': 'settlement',
                    'gross_amount': gross_amount,
                    'transaction_id': 'test-txn-001',
                    'status_code': status_code,
                    'payment_type': 'bank_transfer',
                    'fraud_status': 'accept',
                    'signature_key': signature_key
                }
            )
            
            assert response.status_code == 200
            assert response.json()['message'] == 'OK'
            print("✓ Webhook returned 200 OK")
        
        # Verify payment updated
        db.refresh(payment)
        assert payment.status == PaymentStatus.completed
        assert payment.completed_at is not None
        print("✓ Payment status updated to completed")
        
        # Verify user tier updated
        db.refresh(user)
        assert user.tier == 'PRO'  # or UserTier.PRO
        print("✓ User tier upgraded to PRO")
        
        return True
        
    finally:
        # Cleanup
        if 'payment' in locals():
            db.delete(payment)
            db.commit()
        db.close()

# Run test
# asyncio.run(test_payment_flow())
```