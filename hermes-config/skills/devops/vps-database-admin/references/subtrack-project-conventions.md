# SubTrack ID Project — Patterns & Conventions

## Project Structure

```
/root/projects/subtrack-id/
├── .hermes/plans/           # Plan markdown files (write before coding)
├── backend/
│   ├── app/
│   │   ├── models/          # SQLAlchemy models
│   │   ├── schemas/         # Pydantic schemas
│   │   ├── routes/          # FastAPI route handlers
│   │   ├── services/        # Business logic (detector, LLM, etc.)
│   │   ├── utils/           # Auth, helpers
│   │   ├── config.py        # Settings (pydantic-settings)
│   │   └── database.py      # SQLAlchemy engine/session
│   ├── alembic/             # Migrations
│   ├── docker-compose.yml   # NOT .prod.yml for KII's setup
│   └── .env                 # DB credentials (masked by Hermes)
```

**Important:** Path is `backend/app/...` NOT `app/...`. OpenCode may guess wrong path — always verify.

## Coding Workflow (KII's Pattern)

1. **Write plan.md** to `.hermes/plans/<feature>.md` FIRST — never code without plan
2. **Run OpenCode** via: `/root/.opencode/bin/opencode run "<task>" --model opencode/deepseek-v4-flash-free`
3. **Review** OpenCode output — check syntax, imports, logic
4. **Test** locally: `python3 -m py_compile` + import test
5. **Commit** from repo root: `cd /root/projects/subtrack-id && git add -A && git commit -m "..."`
6. **Push:** `git pull --rebase && git push`
7. **KII deploys manually** — never auto-deploy to VPS

## OpenCode Tips

- OpenCode reads ALL existing files first before coding — this is normal
- If OpenCode fails to find a file at `app/services/X`, it will glob for `**/X` and find the right path
- If edit fails with "multiple matches", the `old_string` needs more surrounding context
- OpenCode may reject reading `.env` files (permission) — provide DB credentials in the prompt

## DB Credentials

- User: `hermes`
- Password: `hermespassword`
- Host: `postgres` (Docker network only, NOT reachable from host as `localhost`)
- Port: `5432`
- Database: `subtrack`

**Migrations must run inside the Docker container:**
```bash
docker-compose exec -T api alembic upgrade head
```

**⚠️ Always use `-T` flag** — `docker-compose exec` without `-T` fails with `the input device is not a TTY` in non-interactive contexts.

## Deployment: Container Does NOT Bind-Mount Source Code

**Critical:** The SubTrack API container does NOT bind-mount source code from the host. Editing files on the host has NO effect on the running container.

**After ANY Python file edit, you MUST:**
```bash
# Option 1: Copy file to container + restart
docker cp backend/<path>/file.py subtrack-api:/app/<path>/file.py
docker-compose restart api

# Option 2: Rebuild (cleaner but slower)
docker-compose up -d --build api
```

**This applies to ALL file changes:** models, routes, migrations, services, utils — everything.

**Verify file is updated in container:**
```bash
docker exec subtrack-api python3 -c "import <module>; print(<module>.__file__)"
```

## Detector Service Architecture

- **Hybrid approach:** LLM (OpenRouter) as primary, regex as fallback
- **Price extraction:** `_find_nearest_price()` scans outward from keyword line (up and down), returns first price found — no fixed window
- **SKIP_KEYWORDS:** Per-line check only (not full-text) — if no subscription keywords in entire text → skip all; if subscription keywords exist → detect regardless of transfer context
- **LLM prompt:** Must explicitly say "DO NOT include one-time transfers" to avoid false positives
- **Response format:** LLM returns `{is_subscription, confidence, reason, items[{name, price}]}`

## Common Pitfalls

1. **Forgot `from typing import Optional`** — causes `NameError` at import time, all routes 500
2. **Enum type name conflict** — two tables with same `name='paymentstatus'` in `sa.Enum()` → PostgreSQL conflict. Fix: use unique names like `family_paymentstatus`
3. **FK cascade chain** — all FKs in delete chain need `ondelete="CASCADE"` (DB-level, not just SQLAlchemy relationship)
4. **`backend/alembic.ini`** — gets accidentally staged by git, causes no harm but noisy; `git reset HEAD backend/alembic.ini`
5. **Docker build cache** — after adding new folders, use `docker-compose build --no-cache` then `up -d`
6. **`psql` not in app container** — use `docker exec -it postgres psql -U hermes -d subtrack` (postgres container), NOT the api container

## Migration: Dropping Unknown FK Constraint Names

**⚠️ NEVER use `try/except` with `op.drop_constraint()` in Alembic.** If one drop fails, PostgreSQL aborts the entire transaction (`InFailedSqlTransaction`) and all subsequent statements fail too.

**Correct approach — Dynamic SQL with `IF EXISTS`:**

```python
def upgrade() -> None:
    op.execute("""
        DO $$
        BEGIN
            FOR con IN
                SELECT constraint_name
                FROM information_schema.table_constraints
                WHERE table_name = 'family_members'
                  AND constraint_type = 'FOREIGN KEY'
            LOOP
                EXECUTE format('ALTER TABLE family_members DROP CONSTRAINT IF EXISTS %I', con.constraint_name);
            END LOOP;

            FOR con IN
                SELECT constraint_name
                FROM information_schema.table_constraints
                WHERE table_name = 'family_payments'
                  AND constraint_type = 'FOREIGN KEY'
            LOOP
                EXECUTE format('ALTER TABLE family_payments DROP CONSTRAINT IF EXISTS %I', con.constraint_name);
            END LOOP;
        END $$;
    """)

    # Now safe to recreate with CASCADE
    op.create_foreign_key('family_members_vault_id_fkey', 'family_members', 'family_vaults',
        ['vault_id'], ['id'], ondelete='CASCADE')
    # ... etc
```

**Rules:**
- `DECLARE RECORD;` is NOT needed in PostgreSQL `DO` blocks — `FOR con IN ...` auto-declares
- Always query `information_schema.table_constraints` to discover actual names
- `DROP CONSTRAINT IF EXISTS` inside `DO $$` won't abort the transaction

**If table was created manually (via psql) but migration not stamped:**
```bash
docker-compose exec -T api alembic stamp <revision_id>
docker-compose exec -T api alembic upgrade head
```

## Debugging: Container Up But Exec Returns Empty / No Logs

When `docker-compose ps` shows container Up but `docker-compose exec` returns empty output:

**Diagnostic steps:**
```bash
# 1. Check if process is running inside container
docker-compose exec -T api ps aux

# 2. Test health from inside container
docker-compose exec -T api curl -s http://localhost:8000/health

# 3. Force restart to clear stuck state
docker-compose restart api

# 4. Full rebuild if restart doesn't help
docker-compose down && docker-compose up -d --build api

# 5. Run migrations after rebuild
docker-compose exec -T api alembic upgrade head
```

## Git: `alembic.ini` Keeps Getting Staged

`backend/alembic.ini` frequently gets accidentally staged by git. Always unstage before committing:

```bash
git reset HEAD backend/alembic.ini
```

Or add to `.gitignore` if it's not already tracked:
```bash
git rm --cached backend/alembic.ini
echo "backend/alembic.ini" >> .gitignore
```
