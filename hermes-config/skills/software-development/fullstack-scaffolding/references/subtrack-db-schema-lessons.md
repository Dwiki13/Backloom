# SubTrack ID — DB Schema & Deployment Lessons (June 2026)

## SQL Column Names Must Match Model Attributes Exactly

When manually writing `CREATE TABLE` SQL for an existing SQLAlchemy model,
**column names must match Python attribute names exactly** — not just types.

### What went wrong (June 8, 2026)

Manually wrote `create_tables.sql` with column names from initial brainstorm,
then coded SQLAlchemy model with DIFFERENT names. Mismatches found:

| SQL column | Model attribute | Error |
|---|---|---|
| `amount` (DECIMAL) | `price` (Float) | ColumnNotFoundError |
| `renewal_date` (DATE) | `next_billing_date` (DateTime) | ColumnNotFoundError |
| `reminder_days` (Integer) | `notify_days_before` (Integer) | ColumnNotFoundError |
| `logo_url` (VARCHAR) | `icon_url` (VARCHAR) | ColumnNotFoundError |
| `member_limit` (Integer) | `max_members` (Integer) | ColumnNotFoundError |
| `subscription_id` FK (present in SQL) | NOT in model | Extra column, ignored |
| `share_percentage` (missing from SQL) | `share_percentage` (Float) | Returns NULL |

### Root Cause

SQLAlchemy maps model attributes to DB columns by name. If the name doesn't
match, the column is silently missing from ORM queries — no startup error,
but 500 on endpoints that reference the column.

### Fix: Derive SQL from the Model

```bash
docker exec <container> python -c "
from app.database import engine
from app.models import Base
Base.metadata.create_all(engine)
"
```

Verify column names:
```bash
docker exec <container> python -c "
from app.models.subscription import Subscription
print([c.name for c in Subscription.__table__.columns])
"
```

## Enum Values: Case Must Match Between Python and DB

Python enum values must exactly match PostgreSQL ENUM type values.

Check current DB enum values:
```sql
SELECT enum_range(NULL::billing_cycle);
SELECT enum_range(NULL::category);
SELECT enum_range(NULL::user_tier);
```

## Postgres Volume Data Overrides POSTGRES_PASSWORD

When a Postgres container uses an existing volume (data directory already
initialized), the `POSTGRES_PASSWORD` env var is IGNORED. The init script
only runs on first startup with an empty data directory.

Symptom: `password authentication failed` even though `.env` is correct.

Fix: Update password manually inside running container:
```bash
docker exec <pg_container> psql -U postgres -c "ALTER USER hermes PASSWORD 'Hermes123!';"
```

## FK Cascade Chains: All Links Must Have ondelete

### Problem (June 13, 2026)

Added `family_payments` table with FK to `family_members.id` (CASCADE). Delete
vault failed because `family_members.vault_id` FK to `family_vaults.id` was
missing `ondelete="CASCADE"` — only had SQLAlchemy relationship cascade
(`cascade="all, delete-orphan"`), not DB-level FK cascade.

### Cascade Chain

```
family_vaults.id ←── family_members.vault_id ←── family_payments.member_id
                     (FK, needs ondelete CASCADE)    (FK, has ondelete CASCADE)
```

When PostgreSQL deletes a vault row, it needs to cascade through the chain.
If ANY FK in the chain is missing `ondelete="CASCADE"`, the delete fails
with a foreign key violation.

### Rule

**Every FK in a cascade chain must have `ondelete="CASCADE"` at the DB level.**
SQLAlchemy relationship `cascade` is NOT sufficient for DB-level deletes —
it only works when SQLAlchemy issues the DELETE statements itself. Direct
`db.delete(vault)` + `db.commit()` may not trigger SQLAlchemy's ORM-level
cascade if the DB blocks it first.

### Fix Pattern

```python
# Model FK — always add ondelete
vault_id = Column(UUID, ForeignKey("family_vaults.id", ondelete="CASCADE"))

# Relationship — keep both for defense in depth
members = relationship("FamilyMember", backref="vault", cascade="all, delete-orphan")
```

### Migration Pattern for Adding ondelete to Existing FKs

```python
def upgrade():
    op.drop_constraint('family_members_vault_id_fkey', 'family_members', type_='foreignkey')
    op.create_foreign_key(
        'family_members_vault_id_fkey',
        'family_members', 'family_vaults',
        ['vault_id'], ['id'],
        ondelete='CASCADE',
    )
```

### Audit Checklist Before Adding New FK Tables

When creating a new table with FKs to existing tables:
1. Check ALL existing FKs in the chain have `ondelete="CASCADE"`
2. Check the new table's FKs have appropriate `ondelete` (CASCADE or SET NULL)
3. Test delete of parent record after migration
4. Run migration from inside container: `docker-compose exec backend alembic upgrade head`

1. `CREATE EXTENSION IF NOT EXISTS pgcrypto;`
2. Create enum types matching Python enum values exactly
3. Create tables with column names matching model attributes exactly
4. Insert test user with known `firebase_uid`
5. Restart API container, verify logs, test health endpoint
6. Test full auth flow: Firebase login -> POST /auth/login -> GET /auth/me

## UUID Columns in SQLite Tests

When using SQLAlchemy models with `UUID(as_uuid=True)` primary/foreign keys
and running pytest with an in-memory SQLite test DB, **UUID comparisons with
string parameters fail**.

### Error

```
AttributeError: 'str' object has no attribute 'hex'
```

SQLAlchemy's SQLite UUID type tries to call `.hex` on the comparison value,
but a plain string doesn't have that method.

### Cause

When a route handler receives a string ID (from path params or JSON body) and
queries a UUID column:

```python
# Route receives str, model has UUID column → SQLite crash
subscription = db.query(Subscription).filter(Subscription.id == data.subscription_id).first()
```

### Fix

Explicitly cast to `UUID` before comparing:

```python
from uuid import UUID
subscription = db.query(Subscription).filter(Subscription.id == UUID(data.subscription_id)).first()
```

This applies to ALL UUID column comparisons in route handlers that might be
tested with SQLite. In production (PostgreSQL) the cast is harmless — PostgreSQL
handles UUID comparison natively.

### Where to apply

- Route handlers that query by ID received from request (path params, JSON body)
- Any `db.query(Model).filter(Model.id == some_string_value)` pattern
- Common in: payment generation, subscription lookups, any entity-by-ID endpoint
