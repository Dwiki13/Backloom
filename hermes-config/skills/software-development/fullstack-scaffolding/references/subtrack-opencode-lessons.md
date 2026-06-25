# SubTrack ID — OpenCode Workflow & Project Rules (Supplement)

> June 2026 lessons. Apply when working on `/root/projects/subtrack-id/`.

## OpenCode Import Pitfall

**OpenCode frequently forgets Python imports.** Always verify after OpenCode edits.

Common missing imports: `from typing import Optional, List, Dict`, `from datetime import datetime`, `from sqlalchemy.orm import joinedload`.

**Symptom:** `NameError: name 'Optional' is not defined` — breaks ALL endpoints at once.

**Fix:** Add missing import manually. For future OpenCode runs, add "verify all imports" to the prompt.

## Alembic: Manual Migrations Only

**Never use `--autogenerate`** — it detects unrelated existing table changes (enum case differences, index rebuilds, FK re-creations).

**Fix:** Create migrations manually with raw SQL `op.create_table(...)`. KII runs on VPS: `docker-compose exec backend alembic upgrade head`

## DB Credentials (NEVER CHANGE)

- User: `hermes` / Password: `hermespassword` / Database: `subtrack` / Host: `postgres`

KII's rule: "password db jangan diganti-ganti lagi"

## Family Vault: Complete Feature Set

All 14 endpoints now implemented (9 CRUD + 5 payment tracking). The generate endpoint (`POST /{vault_id}/payments/generate`) was the last missing piece — owner can now auto-create payment records for all members from a subscription.

## Midtrans Payment Integration (June 14)

### Snap Token
- `snap.create_transaction(snap_params)` returns dict `{"token": "...", "redirect_url": "..."}`
- `create_transaction_token()` does NOT exist — don't use it
- `order_id` convention: `str(payment.id)` (UUID) — simple webhook lookup

### Webhook Handler
- Signature: `SHA512(order_id + status_code + gross_amount + server_key)` — use `hmac.compare_digest`
- When server_key is empty/placeholder: return `{"message": "OK"}` (don't raise 400 — Midtrans retries)
- Lookup payment by `Payment.id == UUID(order_id)` — not `external_transaction_id`
- Idempotent: skip if `payment.status == COMPLETED`
- Settlement/capture → upgrade user tier (pro→PRO, family→FAMILY)

### Secret .env Files
- `.env` is a secret-bearing file — agent CANNOT read it
- When user provides keys: instruct manual edit → `nano .env` → save → `docker-compose restart api`
- Verify by prefix only: `settings.KEY[:10]`

### SQLite UUID Pitfall
- Routes that compare UUID columns with string params must explicitly cast: `UUID(data.param)`
- Test fixtures: set `Payment.id = UUID(order_id)` so webhook lookup matches

### Testing Pattern
- Write plan → OpenCode implements → fix test assertions → run tests → commit
- Test creates DB session → creates Payment → computes signature with `settings.MIDTRANS_SERVER_KEY` → hits webhook → asserts

## Deploy Rules

- Never auto-deploy. Push to GitHub, ask KII: "mau aku deploy?"
- **Preferred deploy**: `docker cp <file> subtrack-api:/app/<path> && docker restart subtrack-api` — faster than rebuild
- Full rebuild (when needed): `docker-compose up -d --build api`
- Path convention: `backend/app/...` not `app/...`
- VPS uses `docker-compose` (v1), not `docker compose` (v2)
- After rebuild, run migrations from inside container: `docker-compose exec backend alembic upgrade head`
