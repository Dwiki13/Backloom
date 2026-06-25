---
name: subtrack-id-backend
description: SubTrack ID backend project reference — Docker workflow, DB gotchas, Midtrans integration, task ownership
---

# SubTrack ID — Backend Project Reference

## Project Structure
- `/root/projects/subtrack-id/backend/` — FastAPI + SQLAlchemy + PostgreSQL
- Docker Compose: `api` (FastAPI on port 8000→host 8002), `postgres` (port 5432)
- DB: user `hermes`, password `hermes`, database `hermesdb` (prod) / `subtrack` (older)
- Firebase Auth for user authentication (firebase-credentials.json in backend/)

## Docker Workflow
- **NEVER** `docker-compose restart api` alone — it reuses old image layers
- **Correct rebuild**: `cd /root/projects/subtrack-id/backend && docker-compose build --no-cache api && docker-compose up -d`
- **After code edit**: `docker cp <file> subtrack-api:/<container_path> && docker-compose restart api`
- Container name: `subtrack-api`, DB container: `postgres`
- Network: `backend_net` (api + postgres), `npm_default` (for SSL)

### ⚠️ `docker cp` + `restart` NOT Enough When Image Has Stale Code
If you edit code on host, `docker cp` into container, and `restart`, but get `ImportError` for classes/enum values that **exist in the host file but not in the image**, the Docker image itself is stale. The container's Python process may cache old `.pyc` files or the image's `COPY . .` layer predates the changes.

**Symptoms:**
- `ImportError: cannot import name 'X' from 'app.models.Y'` — but the class IS in the host file
- `docker cp` succeeds but error persists after `restart`
- The file inside container (`docker exec subtrack-api cat /app/app/models/Y.py`) shows correct content, but import still fails

**Root cause:** Old `.pyc` bytecode cache in `__pycache__/` or the image's `COPY . .` layer is from before the model changes.

**Fix — Full rebuild (same as correct rebuild above):**
```bash
cd /root/projects/subtrack-id/backend
docker-compose down          # remove old container (avoids ContainerConfig KeyError)
docker-compose build --no-cache api
docker-compose up -d
```

**If `KeyError: 'ContainerConfig'` during `up -d` (docker-compose v1 bug)**:
```bash
docker-compose stop api      # stop the running container
docker-compose rm -f api     # force remove old container (avoids stale ContainerConfig)
docker-compose up -d api     # recreate from existing image + code
```
NOTE: `docker-compose down` followed by `up -d --build` can ALSO trigger `ContainerConfig` KeyError on older docker-compose versions. The `stop → rm -f → up -d` sequence is more reliable. Do NOT use `up -d --build` — it triggers the bug. Use `build --no-cache` separately, then `stop → rm -f → up -d`.

**Full rebuild when model/enum changes**:
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

Example pattern added to `family.py`:
```python
def _serialize_subscription(s):
    billing_multipliers_monthly = {
        BillingCycle.WEEKLY: 4.33,
        BillingCycle.MONTHLY: 1,
        BillingCycle.QUARTERLY: 1 / 3,
        BillingCycle.YEARLY: 1 / 12,
    }
    billing_multipliers_yearly = {
        BillingCycle.WEEKLY: 52,
        BillingCycle.MONTHLY: 12,
        BillingCycle.QUARTERLY: 4,
        BillingCycle.YEARLY: 1,
    }
    monthly_cost = s.price * billing_multipliers_monthly[s.billing_cycle]
    yearly_cost = s.price * billing_multipliers_yearly[s.billing_cycle]
    has_price_increased = bool(s.previous_price and s.previous_price < s.price)

    return {
        "id": str(s.id),
        "name": s.name,
        "description": s.description,
        "price": s.price,
        "currency": s.currency,
        "billing_cycle": s.billing_cycle.value if s.billing_cycle else None,
        "category": s.category.value if s.category else None,
        "next_billing_date": s.next_billing_date.isoformat() if s.next_billing_date else None,
        "is_trial": s.is_trial,
        "trial_ends_at": s.trial_ends_at.isoformat() if s.trial_ends_at else None,
        "previous_price": s.previous_price,
        "icon_url": s.icon_url,
        "website_url": s.website_url,
        "is_active": s.is_active,
        "notify_days_before": s.notify_days_before,
        "monthly_cost": monthly_cost,
        "yearly_cost": yearly_cost,
        "has_price_increased": has_price_increased,
        "created_at": s.created_at.isoformat() if s.created_at else None,
        "updated_at": s.updated_at.isoformat() if s.updated_at else None,
        "vault_id": str(s.vault_id),
    }
```

### ⚠️ Test Update Pattern
When changing endpoint behavior (status values, required fields, removed endpoints):
1. **Always update existing tests** — check for hardcoded status strings like `"paid"` → `"awaiting_confirm"`
2. **Add `files=proof_file`** to all `mark-paid` test calls (proof is now required)
3. **Remove tests for deleted endpoints** (e.g. `test_generate_payments_*`)
4. **Update route registration tests** — remove deleted routes from expected routes list
5. **Run full suite**: `python -m pytest tests/ -v --tb=short`

### 🐛 Common Backend Bugs to Watch For
**Member ID Field Bug**: `FamilyMember` model uses `id` field, not `member_id`. Using `member.member_id` causes `AttributeError`.

**Fix**: Always verify the correct field name when referencing `FamilyMember` fields:
- ❌ `member.member_id` → ✅ `member.id`
- This bug appeared in `family_billing_service.py` lines 73 and 84, causing Celery task failures.

**Prevention**: After writing code that references model fields, verify against the actual model definition:
```bash
grep -A 5 "class FamilyMember" /root/projects/subtrack-id/backend/app/models/family.py
```

**joined_at vs created_at Bug**: `FamilyMember` model uses `joined_at` (not `created_at`). Celery tasks referencing `member.created_at` will get `AttributeError` or `None`.

**Fix**: Use `member.joined_at` for member join date, or use a defensive pattern:
```python
join_date = member.joined_at if hasattr(member, 'joined_at') and member.joined_at else (member.created_at if hasattr(member, 'created_at') else None)
```

**Real-world case**: `generate_family_payments` task referenced `member.created_at` but the column is `joined_at`. This caused all members to be skipped (join_date evaluates to falsy), so payments were never generated. **Fix**: already applied defensive pattern in `family_billing_service.py` line ~65.

**Prevention**: Always check model definition before writing date-based filtering logic in tasks. Verify with:
```bash
grep -A 10 "class FamilyMember" app/models/family.py
grep -A 10 "class FamilyPayment" app/models/family_payment.py
```
Common pitfall: `FamilyMember` uses `id`, not `member_id`.

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

## Midtrans Integration
- Sandbox mode: `MIDTRANS_IS_PRODUCTION=false`
- Webhook signature: SHA512 of `{order_id}{status_code}{gross_amount}{server_key}`
- `order_id` = payment UUID (string), must be valid UUID format
- Webhook returns 200 even if payment not found (by design, prevents Midtrans retry)
- Ngrok for local webhook testing: `ngrok http 8002`

## Deploy Workflow (VPS)

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
- This runs the code that was `COPY . .` into the image at build time, with `docker cp` overriding specific files
- Image rebuild (`docker-compose build --no-cache api`) is NOT done on VPS deploy — too slow
- `docker-compose up -d --build` on VPS can trigger `ContainerConfig` KeyError — avoid it

## Git Workflow
- **Always commit before push**: KII prefers explicit commits with clear messages, then explicit push
- **Review before push**: KII says "push sekarang ya" — he wants control over when changes go live
- **Untracked files**: `.hermes/plans/` and `alembic.ini` are local-only, don't push

## OpenCode Workflow
When KII says "pakai OpenCode" or "workflow coding opencode":
1. **Write a plan first** — create `.hermes/plans/<feature>.md` with numbered steps
2. **Hand off to OpenCode** with `--model opencode/deepseek-v4-flash-free`:
   ```bash
   /root/.opencode/bin/opencode run "<task description>" --model opencode/deepseek-v4-flash-free
   ```
3. **ALWAYS verify the diff before committing** — OpenCode may make unintended destructive changes:
   - Check `git diff` for deleted endpoints, removed functions, or unexpected changes
   - Verify all expected endpoints still exist: `grep -n "def <endpoint_name>" app/routes/<file>.py`
   - **OpenCode may delete endpoints it considers "duplicate" or "unnecessary"** — e.g., when asked to add proof fields to payment list, it deleted `mark_paid`, `confirm_payment`, `reject_payment`, and `get_payment_summary`. Always restore from `git checkout HEAD -- <file>` and re-apply only the needed changes manually.
   - If OpenCode deleted something, restore and apply changes manually
4. **Run tests after OpenCode changes** — `python -m pytest tests/ -v --tb=short`
5. **Commit, rebase if needed, push** — same git workflow as above

**Known OpenCode behavior**: OpenCode may aggressively "refactor" by removing code it considers duplicate or unnecessary. **Always review diff before committing.** When the task is narrow (e.g., "add field to response"), explicitly list which endpoints must NOT be modified in the prompt.

## Ngrok Gotcha
- Free plan restarts give NEW URLs — always re-check `ngrok http 8002` output
- webhook URL in Midtrans Dashboard must be updated when ngrok changes

## FCM Push Notifications

**FCM tokens go stale**: When testing push notifications and they don't arrive, the most likely cause is stale FCM tokens in the database. FCM tokens expire or become invalid when:
- App is uninstalled/reinstalled
- Firebase project credentials change
- Token refresh hasn't been synhed to backend

**Debug steps**:
1. Check tokens exist: `SELECT id, fcm_token FROM users WHERE id = '<user_id>';`
2. Verify token is non-null and looks valid (long string starting with project-specific prefix)
3. Test send directly via `send_push_notification(token, title, body)` from container
4. If token invalid → app needs to re-register via `POST /api/v1/notifications/register-token`

**Firebase initialization order matters**: `firebase_admin.initialize_app()` must be called BEFORE any module imports `firebase_admin.messaging`. If `fcm.py` or `fcm_service.py` imports `messaging` at module level before `auth.py` runs `initialize_app()`, FCM calls will fail with "The default Firebase app does not exist".

**Fix**: Initialize Firebase in `app/main.py` before any route imports:
```python
import firebase_admin
from firebase_admin import credentials
from app.config import settings

try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)
```
Then in `fcm.py` and `fcm_service.py`, just `from firebase_admin import messaging` — no need for their own `initialize_app()` calls.

**Verify FCM works**: Test from container:
```python
import app.main  # triggers initialize_app
from app.utils.fcm import send_fcm_notification
import asyncio
result = asyncio.run(send_fcm_notification('TOKEN_HERE', 'Test', 'Body'))
# Should return True, not "default Firebase app does not exist"
```

**Notification types implemented**:
- `member_joined` — owner notified when someone joins vault
- `payment_paid` — owner notified when member uploads proof
- `payment_confirmed` — member notified when owner confirms
- `payment_rejected` — member notified when owner rejects
- `payment_awaiting_confirmation_reminder` — owner reminded after 6h (auto-confirm task)
- `payment_auto_confirmed` — member notified when auto-confirmed after 24h

**Realtime listener not available**: FCM notifications are push-based. The Flutter app must call `GET /api/v1/notifications` to fetch in-app notification history. Push FCM handles the real-time alert.

## Task Ownership (June 15 2026)
- **Backend (Python/FastAPI)**: OWL's domain — API, DB, migrations, tests
- **Flutter/Mobile**: KII's domain — KII handles all Flutter code himself, never auto-generate
- **Alembic verify**: read-only audit only — check model vs DB, list differences, KII decides fixes
- **Test count**: 109 tests passing (as of June 15 2026)
  - `test_endpoints.py` (~40), `test_payment_proofs.py` (10), `test_notifications.py` (~7)
  - `test_billing.py` (6), model tests (~24 total)
  - `test_family_payments.py` (17) — covers history/reject/summary/member-scope/proof-view
  - `test_auto_confirm.py` (7) — dual-threshold reminder + auto-confirm
  - Full suite: `python -m pytest tests/ -v --tb=short`

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

### New Enum Value
- `FamilyPaymentStatus.AWAITING_CONFIRM = "awaiting_confirm"` — between PENDING and PAID
- Added to `app/models/family_payment.py`

### Proof Upload (mark-paid)
- `proof_file` is **required** (not optional) — returns 400 if missing
- Stores file via `save_proof_file()` + `PaymentProof` model
- Returns `proof_url`, `proof_type`, `proof_size` in response

### Proof Viewing (Owner)
- `GET /{vault_id}/payments` — includes `proof_url`, `proof_type`, `proof_size` for each payment (join from `payment_proofs` table)
- `GET /{vault_id}/payments/history` — same proof fields included
- Owner can see all members' proofs; member can only see their own payment's proof
- Uses `joinedload(FamilyPayment.proof)` + `back_populates` relationship (not `backref`)

### Join Response Enhancement
- `POST /family/join/{code}` now returns `first_payment_month` (YYYY-MM) and `payment_eligible` (bool)
- New members always get `payment_eligible=False` (first bill next month)

### Auto-Confirm + Reminder (Celery)
- Task `auto_confirm_awaiting_payments` runs every 6 hours
- >6h: sends reminder notification to vault owner
- >24h: auto-confirms payment (sets CONFIRMED), notifies member

### ⚠️ Test Update Pattern
When changing endpoint behavior (status values, required fields, removed endpoints):
1. **Always update existing tests** — check for hardcoded status strings like `"paid"` → `"awaiting_confirm"`
2. **Add `files=proof_file`** to all `mark-paid` test calls (proof is now required)
3. **Remove tests for deleted endpoints** (e.g. `test_generate_payments_*`)
4. **Update route registration tests** — remove deleted routes from expected routes list
5. **Run full suite**: `python -m pytest tests/ -v --tb=short`

### 🧪 Test Creation for New Endpoints
When adding new endpoints, create tests in the appropriate test file:
- **New family payment endpoints** → `tests/api/v1/endpoints/test_family_payments.py`
- **New Celery tasks** → `tests/tasks/test_<task_name>.py`
- **New proof/notification endpoints** → matching `test_<feature>.py` in `tests/api/v1/endpoints/`

**Test structure pattern** (follow existing conventions):
1. Use `sqlite:///./test_<feature>.db` as test DB URL
2. Create `engine`, `TestingSessionLocal`, `override_get_db()` — same pattern as existing test files
3. Use `app.dependency_overrides[get_db]` and `app.dependency_overrides[get_current_user]`
4. Helper functions: `create_user()`, `create_vault()`, `create_subscription()`, `create_family_payment()`, `add_vault_member()`
5. Use `set_auth_user()` / `clear_auth()` in try/finally blocks
6. Always call `engine.dispose()` in fixture teardown to release SQLite file locks

**For Celery task tests**:
- Patch `get_session` and external services (FCM, notifications)
- Use `MagicMock()` for DB query chains
- Test both the happy path and edge cases (empty results, wrong status, missing FCM token)

**⚠️ Dual-threshold pitfall**: When a Celery task has multiple time thresholds (e.g. 6h reminder + 24h auto-confirm), a payment older than BOTH thresholds will trigger BOTH actions in a single run. In tests, use `call_count` and `call_args_list` instead of `assert_called_once()`:
```python
# ❌ Wrong — fails when both thresholds fire
mock_fcm.assert_called_once()

# ✅ Correct — check total calls and filter for specific call
assert mock_fcm.call_count == 2
member_call = [c for c in mock_fcm.call_args_list if c.kwargs.get('token') == "member_fcm_token"]
assert len(member_call) == 1
```

### ⚠️ Model Field Reference
Always verify field names against model definition:
```bash
grep -A 10 "class FamilyMember" app/models/family.py
grep -A 10 "class FamilyPayment" app/models/family_payment.py
```
Common pitfall: `FamilyMember` uses `id`, not `member_id`.

## See Also
- `references/database-gotchas.md` — Docker troubleshooting, DB schema, enum values, Midtrans testing pattern
- `references/alembic-audit-checklist.md` — Read-only DB audit procedure (model vs DB comparison)
- `references/test-fixture-isolation.md` — SQLite test fixture isolation pattern (engine.dispose, import order, dependency_overrides)
- `references/family-vault-payment-flow.md` — Full payment flow spec and endpoint mapping
- `references/git-diff-workflow.md` — How to check and report uncommitted local changes (KII frequently asks this)
- `references/test-files-index.md` — Index of all test files, what each covers, and creation patterns
- `references/opencode-workflow-lessons.md` — OpenCode delegation pitfalls and relationship patterns
- `references/firebase-init-order.md` — Firebase initialization order lesson (FCM fix, June 2026)