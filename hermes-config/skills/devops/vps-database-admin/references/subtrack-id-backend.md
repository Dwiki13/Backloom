# SubTrack ID — Project-Specific Reference

This is the project-specific companion to the VPS Database Admin skill. It covers SubTrack ID's Docker workflow, DB schema, Midtrans integration, task ownership, and family vault payment flow.

## Project Structure
- `/root/projects/subtrack-id/backend/` — FastAPI + SQLAlchemy + PostgreSQL
- Docker Compose: `api` (FastAPI on port 8000→host 8002), `postgres` (port 5432)
- DB: user `hermes`, password `hermes`, database `hermesdb` (prod) / `subtrack` (older)
- Firebase Auth for user authentication (firebase-credentials.json in backend/)

## Docker Workflow — SubTrack Specific

### ⚠️ `docker cp` + `restart` NOT Enough When Image Has Stale Code
If you edit code on host, `docker cp` into container, and `restart`, but get `ImportError` for classes/enum values that **exist in the host file but not in the image**, the Docker image itself is stale.

**Symptoms:**
- `ImportError: cannot import name 'X' from 'app.models.Y'` — but the class IS in the host file
- `docker cp` succeeds but error persists after `restart`
- The file inside container (`docker exec subtrack-api cat /app/app/models/Y.py`) shows correct content, but import still fails

**Root cause:** Old `.pyc` bytecode cache in `__pycache__/` or the image's `COPY . .` layer is from before the model changes.

**Fix — Full rebuild:**
```bash
cd /root/projects/subtrack-id/backend
docker-compose down          # remove old container (avoids ContainerConfig KeyError)
docker-compose build --no-cache api
docker-compose up -d
```

**If `KeyError: 'ContainerConfig'` during `up -d` (docker-compose v1 bug):**
```bash
docker-compose stop api      # stop the running container
docker-compose rm -f api     # force remove old container (avoids stale ContainerConfig)
docker-compose up -d api     # recreate from existing image + code
```

**Full rebuild when model/enum changes:**
```bash
cd /root/projects/subtrack-id/backend
docker-compose stop api
docker-compose rm -f api
docker-compose build --no-cache api
docker-compose up -d
```

**Prevention**: After ANY model change (new class, renamed enum, new import), always do full rebuild instead of `docker cp` + `restart`.

### 🔧 Backend-Frontend API Alignment
When updating backend endpoints to match frontend models:
1. **Create a serialization helper function** that maps all DB fields to frontend-expected format
2. **Include computed properties** (monthly_cost, yearly_cost, has_price_increased) using the same logic as frontend
3. **Handle datetime conversion** with `.isoformat()` for JSON serialization
4. **Handle enum values** with `.value` when needed
5. **Apply to both list and single item endpoints** for consistency

### ⚠️ Test Update Pattern
When changing endpoint behavior (status values, required fields, removed endpoints):
1. **Always update existing tests** — check for hardcoded status strings like `"paid"` → `"awaiting_confirm"`
2. **Add `files=proof_file`** to all `mark-paid` test calls (proof is now required)
3. **Remove tests for deleted endpoints** (e.g. `test_generate_payments_*`)
4. **Update route registration tests** — remove deleted routes from expected routes list
5. **Run full suite**: `python -m pytest tests/ -v --tb=short`

### ⚠️ Test: Hardcoded Domain in Assertions
When tests assert `proof_url` or other domain-dependent URLs, do NOT hardcode `localhost:8000`. The `DOMAIN` config in test environment may differ from production. Use flexible assertions:
```python
# Bad:
assert p["proof_url"] == "https://localhost:8000/app/uploads/proofs/test.jpg"

# Good:
assert "app/uploads/proofs/test.jpg" in p["proof_url"]
```

### ⚠️ Adding New Endpoints — Pattern
When adding new endpoints to existing routers:
1. Add Pydantic request schema (if needed) near other request schemas
2. Add endpoint function with proper decorators
3. Use `current_user: User = Depends(get_current_user)` for auth
4. Use `db: Session = Depends(get_db)` for DB access
5. Return the standard response model (e.g., `UserResponse`)
6. Run full test suite after adding
7. Copy file to container + restart (no full rebuild needed for route-only changes)
8. Commit & push

Example — adding `PUT /auth/profile`:
```python
class UpdateProfileRequest(BaseModel):
    display_name: str | None = None
    photo_url: str | None = None

@router.put("/profile", response_model=UserResponse)
async def update_profile(
    body: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if body.display_name is not None:
        current_user.display_name = body.display_name
    if body.photo_url is not None:
        current_user.photo_url = body.photo_url
    current_user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(current_user)
    return current_user
```
When tests assert `proof_url` or other domain-dependent URLs, do NOT hardcode `localhost:8000`. The `DOMAIN` config in test environment may differ from production. Use flexible assertions:
```python
# Bad:
assert p["proof_url"] == "https://localhost:8000/app/uploads/proofs/test.jpg"

# Good:
assert "app/uploads/proofs/test.jpg" in p["proof_url"]
```

### 🐛 Common Backend Bugs to Watch For

**Member ID Field Bug**: `FamilyMember` model uses `id` field, not `member_id`. Using `member.member_id` causes `AttributeError`.

**joined_at vs created_at Bug**: `FamilyMember` model uses `joined_at` (not `created_at`). Celery tasks referencing `member.created_at` will get `AttributeError` or `None`.

**Enum value migration**: When adding new enum values to existing PostgreSQL enum types, old data with removed values will cause `LookupError` on query. Always check for stale enum values in DB after changing enum definitions:
```sql
SELECT DISTINCT status FROM family_payments WHERE status NOT IN ('pending','awaiting_confirm','paid','overdue','confirmed');
```
Fix stale values before querying:
```sql
UPDATE family_payments SET status = 'confirmed' WHERE status = 'completed';
```

- **FamilyPayment fields**: uses `month` (int) + `year` (int), NOT `period` (string); needs `subscription_id` FK
- **FamilyMember roles**: only `admin` and `member` — no `owner` (owner is `owner_id` on vault)
- **Subscription fields**: `website_url` (not `url`), `description` (nullable), `currency` (default IDR)
- **FamilyMember `first_payment_month`**: Schema returns `Optional[int]` (month as int 1-12), NOT `Optional[str]`. Route computes via `.month` (int), not `.strftime('%Y-%m')`. Fixed on 2026-06-20 to match Flutter's `int?` type.

## Midtrans Integration — SubTrack Specific
- Sandbox mode: `MIDTRANS_IS_PRODUCTION=false`
- Webhook signature: SHA512 of `{order_id}{status_code}{gross_amount}{server_key}`
- `order_id` = payment UUID (string), must be valid UUID format
- Webhook returns 200 even if payment not found (by design, prevents Midtrans retry)
- Ngrok for local webhook testing: `ngrok http 8002`

## Deploy Step-by-Step (KII's Preferred Format)

When KII asks for deploy steps, give concise numbered steps:

```bash
# Step 1: Pull latest code
cd /root/projects/subtrack-id/backend && git pull origin main

# Step 2: Copy changed files to container
docker cp app/routes/<file>.py subtrack-api:/app/app/routes/<file>.py
# Copy ALL changed files before restarting

# Step 3: Restart container
docker-compose restart api

# Step 4: Check logs
docker-compose logs -f api

# Step 5: Test endpoint
curl -X <METHOD> https://api.subtrack.devlokal.id/api/v1/<path> \
  -H "Authorization: Bearer *** \
  -H "Content-Type: application/json" \
  -d '<body>'
```

**Important:** Copy ALL changed files BEFORE restarting. Never restart between copies.

KII deploys to VPS via SSH with this sequence:
```bash
# On VPS:
cd /root/projects/subtrack-id/backend
git pull
docker cp app/models/<file>.py subtrack-api:/app/app/models/<file>.py
docker cp app/routes/<file>.py subtrack-api:/app/app/routes/<file>.py
# ... copy all changed files ...
docker-compose restart api
sleep 5
docker logs --tail=30 subtrack-api
```

**Important**: 
- Copy ALL changed files before restarting
- Always check logs after restart
- Image rebuild (`docker-compose build --no-cache api`) is NOT done on VPS deploy — too slow
- `docker-compose up -d --build` on VPS can trigger `ContainerConfig` KeyError — avoid it

## Git Workflow
- **Always commit before push**: KII prefers explicit commits with clear messages, then explicit push
- **Review before push**: KII says "push sekarang ya" — he wants control over when changes go live
- **Untracked files**: `.hermes/plans/` and `alembic.ini` are local-only, don't push
- **Pull before push**: When KII deploys directly on VPS, remote may be ahead. Always `git pull origin main --rebase` before `git push origin main` to avoid "fetch first" errors.

## OpenCode Workflow
When KII says "pakai OpenCode" or "workflow coding opencode":
1. **Write a plan first** — create `.hermes/plans/<feature>.md` with numbered steps
2. **Hand off to OpenCode** with `--model opencode/deepseek-v4-flash-free`:
   ```bash
   /root/.opencode/bin/opencode run "<task description>" --model opencode/deepseek-v4-flash-free
   ```
3. **ALWAYS verify the diff before committing** — OpenCode may make unintended destructive changes
4. **Run tests after OpenCode changes** — `python -m pytest tests/ -v --tb=short`
5. **Commit, rebase if needed, push** — same git workflow as above

**Known OpenCode behavior**: OpenCode may aggressively "refactor" by removing code it considers duplicate or unnecessary. **Always review diff before committing.**

## Task Ownership (June 15 2026)
- **Backend (Python/FastAPI)**: OWL's domain — API, DB, migrations, tests
- **Flutter/Mobile**: KII's domain — KII handles all Flutter code himself, never auto-generate
- **Alembic verify**: read-only audit only — check model vs DB, list differences, KII decides fixes
- **Test count**: 120 tests passing (as of June 20 2026, after first_payment_month fix + test domain fix)

## Family Vault Payment Flow (June 2026)

### Architecture: 1 Vault = 1 Subscription
- Each Family Vault links to exactly ONE subscription
- If owner wants to bill for multiple subscriptions → create separate vaults
- Auto-billing via Celery beat (`generate_family_payments`) runs on the 1st of each month
- Manual generate endpoint (`POST /{vault_id}/payments/generate`) was REMOVED to prevent double-billing confusion

### Payment Lifecycle
```
Celery (1st of month) → PENDING
Member uploads proof → AWAITING_CONFIRM
Owner confirms → CONFIRMED
Owner rejects → PENDING (re-upload)
No owner action 24h → auto-CONFIRMED (with 6h reminders to owner)
```

### Key Endpoints
| Endpoint | Method | Who | Flow |
|----------|--------|-----|------|
| `/family/{id}/subscriptions` | POST | Owner | Link subscription to vault |
| `/family/{id}/subscriptions` | GET | Any member | List vault subscriptions (full fields) |
| `/family/{id}/payments` | GET | Owner/Member | List payments (member sees own only) |
| `/family/{id}/payments/history` | GET | Owner/Member | Paginated all-months history |
| `/family/{id}/payments/summary` | GET | Owner only | Totals: paid, pending, awaiting, overdue |
| `/family/{id}/payments/{member_id}/mark-paid` | POST | Member (own) | Upload proof → AWAITING_CONFIRM |
| `/family/{id}/payments/{payment_id}/confirm` | PUT | Owner only | AWAITING_CONFIRM → CONFIRMED |
| `/family/{id}/payments/{payment_id}/reject` | PUT | Owner only | AWAITING_CONFIRM → PENDING |

### Proof Upload (mark-paid)
- `proof_file` is **required** (not optional) — returns 400 if missing
- Stores file via `save_proof_file()` + `PaymentProof` model
- Returns `proof_url`, `proof_type`, `proof_size` in response
- **Upload allowed** for PENDING, PAID, and AWAITING_CONFIRM — only CONFIRMED is blocked
- **Delete proof** follows same rule: only CONFIRMED blocks deletion
- **Delete proof reverts status**: if status was AWAITING_CONFIRM, it reverts to PENDING (no proof = not awaiting confirmation)
- Logic: `if payment.status == FamilyPaymentStatus.CONFIRMED` (NOT `not in (PENDING, PAID)`)
- **KII's rule**: member must be able to delete/re-upload proof as long as owner hasn't confirmed yet

### Stats Endpoints
- `GET /api/v1/subscriptions/stats/summary` — accepts `period` (monthly/yearly), `month` (1-12), `year` query params; returns `monthly_trend` (12 months) + `summary` object
- `GET /api/v1/subscriptions/stats/trend` — returns 12-month spending data for bar chart

### Auto-Confirm + Reminder (Celery)
- Task `auto_confirm_awaiting_payments` runs every 6 hours
- >6h: sends reminder notification to vault owner
- >24h: auto-confirms payment (sets CONFIRMED), notifies member

### Proof Delete Reverts Status to PENDING
When a proof is deleted (by member or owner), if the payment status was `AWAITING_CONFIRM`, it **reverts to `PENDING`**. This is correct behavior: no proof = not awaiting confirmation. Member must re-upload proof to move back to `AWAITING_CONFIRM`.

### ⚠️ Flutter Client-Side Estimation vs Backend Amount Mismatch
Flutter's `_buildEstimateText()` in `family_screen.dart` calculates estimated billing client-side:
- Takes `totalVaultMonthly` from `vaultSubscriptions`
- Divides by `memberCount` (split rata) or uses `share_percentage`
- **Problem:** This doesn't match backend billing — backend currently uses full subscription price per member
- **Decision (June 2026):** Flutter should NOT estimate — only display `payment.amount` from backend
- Before payment is generated, show "Belum ada tagihan bulan ini" instead of a fake estimate
- `share_percentage` field exists in `FamilyMember` model (Float, default=50.0) but is NOT used in billing logic

### Billing Model: Full Price vs Split Rata (June 2026 Design Decision)
- **Current behavior:** Full price — each member pays the full subscription price
- **Planned change:** Add `billing_type` field to `FamilyVault` (`full_price` or `split_equal`)
- `full_price`: amount = subscription.price (each member pays full)
- `split_equal`: amount = subscription.price / member_count (equal split)
- **Not implementing `share_percentage` for billing** — field exists in DB but decided to keep it simple with just the two options
- Flutter side: remove `_buildEstimateText()` entirely, show backend data only
- Pending implementation — plan written but not yet coded (KII said to use OpenCode workflow)
- Also add `billing_type` to `FamilyPayment` model to preserve historical billing type at time of generation

### ⚠️ `total_collected` Always Returns 0 (Known Bug)
The `GET /{vault_id}/payments/summary` endpoint computes `total_collected` from `payment.amount_paid`, but `amount_paid` is **never set** in the current payment flow (mark-paid uploads proof, confirm sets CONFIRMED — neither sets `amount_paid`). `total_collected` will always be 0 on the Flutter stats card. Fix: change the computation to use `payment.amount` instead of `payment.amount_paid` for CONFIRMED/PAID status payments.

### ⚠️ Summary Only Counts Current Month
`GET /{vault_id}/payments/summary` filters payments by `month == now.month && year == now.year`. Payments from previous months (e.g., overdue from last month) are NOT counted in the summary. This is by design but can be confusing — the Flutter stats card only reflects the current month's billing cycle.

### ⚠️ Flutter-Member Cannot See Payment Summary
Both backend (403 for non-owner) and Flutter (`if (isOwner)` gate on `loadPaymentSummary`) restrict payment summary to vault owner only. If KII wants members to see a summary in the future, both sides need updating.

### ⚠️ Model Field Reference
Always verify field names against model definition:
```bash
grep -A 10 "class FamilyMember" app/models/family.py
grep -A 10 "class FamilyPayment" app/models/family_payment.py
```
Common pitfalls:
- `FamilyMember` uses `id`, not `member_id`
- `FamilyMember` does NOT have `payment_eligible` or `first_payment_month` fields in DB model — those are schema-only additions (computed at route level)
- When creating `FamilyMember` in tests, only use fields that exist in the model

### ⚠️ Test Import Pattern for uuid
When creating `FamilyMember` in tests with `uuid.uuid4()`, you need `import uuid` (module-level import). The existing test file already has `from uuid import uuid4` — but that only imports the function, not the module. Add `import uuid` separately to use `uuid.uuid4()`. Alternatively, use `uuid4()` directly (already imported).

### ⚠️ Async Test DB Refresh Pattern
When testing async FastAPI endpoints that modify DB state, `db.refresh(obj)` does NOT work across the async boundary (the endpoint commits in a separate transaction). Use:
```python
db.expire_all()
obj = db.query(Model).filter(Model.id == obj.id).first()
```
This forces SQLAlchemy to re-read from the DB on next access.

## FCM Push Notifications

**FCM tokens go stale**: When testing push notifications and they don't arrive, the most likely cause is stale FCM tokens in the database.

**Firebase initialization order matters**: `firebase_admin.initialize_app()` must be called BEFORE any module imports `firebase_admin.messaging`. Initialize in `app/main.py` before any route imports.

**Notification types implemented**:
- `member_joined` — owner notified when someone joins vault
- `payment_paid` — owner notified when member uploads proof
- `payment_confirmed` — member notified when owner confirms
- `payment_rejected` — member notified when owner rejects
- `payment_awaiting_confirmation_reminder` — owner reminded after 6h (auto-confirm task)
- `payment_auto_confirmed` — member notified when auto-confirmed after 24h

### Auth Endpoints
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/auth/register` | POST | Firebase | Register new user |
| `/auth/login` | POST | Firebase | Login, return JWT |
| `/auth/me` | GET | JWT | Get current user profile |
| `/auth/profile` | PUT | JWT | Update display_name & photo_url (added 2026-06-21) |

### Auth Profile Update (PUT /auth/profile)
- Request body: `{"display_name": "...", "photo_url": "..."}` (both optional)
- Returns: `UserResponse`
- Updates `updated_at` timestamp
## Current Status (June 21 2026)
- **Backend:** 100% complete — all endpoints (including PUT /auth/profile), migrations, SSL, 120 tests passing
- **Flutter:** ~95% complete — all models synced, all endpoints integrated (44 endpoints, 0 mismatches)
- **Integration:** v5 check passed — 0 critical, 0 mismatches, 2 expected unused (admin/webhook)
- **Remaining:** Build APK + deploy to Play Store (KII handles manually)

## Current Status (June 21 2026)
- **Backend:** 100% complete — all endpoints implemented, migrations, SSL, 120 tests passing
- **Flutter:** ~95% complete — all models synced, all endpoints integrated (44 endpoints, 0 mismatches)
- **Integration:** v5 check passed — 0 critical, 0 mismatches, 2 expected unused (admin/webhook)
- **Remaining:** Build APK + deploy to Play Store (KII handles manually)

## New Endpoints (June 21 2026)

### Auth Profile Update — PUT /api/v1/auth/profile
- Request body: `{"display_name": "...", "photo_url": "..."}` (both optional)
- Returns: `UserResponse`
- Updates `updated_at` timestamp
- Added: June 21, 2026

### Upload Profile Photo — POST /api/v1/auth/upload-photo
- `multipart/form-data` with `file` field
- Validates extension: jpg, jpeg, png, webp
- Max file size: 5MB
- Saves to `/app/uploads/profile_photos/{user_id}.{ext}`
- Photo URL: `https://{DOMAIN}/uploads/profile_photos/{user_id}.{ext}`
- Static files already mounted at `/uploads` → `/app/uploads` in main.py
- Old file with same name is overwritten (same user_id)
- Returns: `UserResponse` with updated `photo_url`
- Added: June 21, 2026

### Cancel Subscription — POST /api/v1/payments/cancel
- Cancel user's active paid subscription
- Tier stays until expiry, then reverts to free
- Deactivates all active subscriptions
- Returns: `{"message": "...", "tier": "..."}`
- Error 400 if already on free tier
- Added: June 21, 2026

### Downgrade Subscription — POST /api/v1/payments/downgrade
- Body: `{"target_tier": "free"}`
- Immediately downgrades to free tier
- Deactivates all active subscriptions
- Returns: `{"message": "...", "previous_tier": "...", "current_tier": "free"}`
- Error 400 if already on free tier or invalid target
- Added: June 21, 2026

## Smart Detector
- **Free tier limit:** 3 detects total (changed from 5 on June 21 2026)
- **Pro/Family:** unlimited detects
- **LLM model:** `openrouter/owl-alpha` via OpenRouter
- **Timeout:** 10 seconds
- **Fallback:** returns empty list on failure (regex still works)

## See Also
- `references/database-gotchas.md` — Docker troubleshooting, DB schema, enum values, Midtrans testing pattern
- `references/alembic-audit-checklist.md` — Read-only DB audit procedure (model vs DB comparison)
- `references/test-fixture-isolation.md` — SQLite test fixture isolation pattern
- `references/family-vault-payment-flow.md` — Full payment flow spec and endpoint mapping
- `references/git-diff-workflow.md` — How to check and report uncommitted local changes
- `references/test-files-index.md` — Index of all test files, what each covers, and creation patterns
- `references/opencode-workflow-lessons.md` — OpenCode delegation pitfalls and relationship patterns
- `references/firebase-init-order.md` — Firebase initialization order lesson (FCM fix, June 2026)
