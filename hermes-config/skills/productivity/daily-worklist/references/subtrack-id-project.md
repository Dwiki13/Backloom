# SubTrack ID — Project Reference

## Project Info
- Repo: https://github.com/Dwiki13/subtrack-id
- Stack: FastAPI backend + Flutter mobile
- Domain: Subscription tracker for Indonesian market

## Constraint: Mobile Code is IMMUTABLE
- KII's Flutter mobile app has been pushed and must NOT be modified by agents
- All "Connect Flutter app" tasks = backend-side work only
- Never edit files under /root/projects/subtrack-id/mobile/ without explicit KII approval

## Deployment
- VPS: 202.10.46.161
- Docker Compose v1 (hyphen syntax)
- Deploy key: ~/.ssh/subtrack_deploy
- Backend port: 8002 (docker-compose.prod.yml)

## Backend API Endpoints (Complete List)

### Auth (`/api/v1/auth`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| POST | `/login` | ✅ | Firebase Bearer token → auto-register if new |
| POST | `/register` | ✅ | Firebase Bearer token → register |
| GET | `/me` | ✅ | Get current user profile |

### Subscriptions (`/api/v1/subscriptions`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| GET | `/` | ✅ | List user subscriptions (limit, offset) |
| POST | `/` | ✅ | Create subscription |
| GET | `/:id` | ❌ | Get single subscription detail |
| PUT | `/:id` | ✅ | Update subscription |
| DELETE | `/:id` | ✅ | Soft-delete (is_active=false) |
| GET | `/stats/summary` | ✅ | Monthly/yearly totals, upcoming, trials |

### Family (`/api/v1/family`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| POST | `/` | ✅ | Create family vault |
| POST | `/join/:code` | ✅ | Join vault via invite code |
| GET | `/my-vaults` | ❌ | List vaults user belongs to |
| GET | `/:id/members` | ❌ | List vault members |
| PUT | `/:id` | ❌ | Update vault name (owner only) |
| DELETE | `/:id` | ❌ | Delete vault (owner only, cascade) |
| POST | `/:id/leave` | ❌ | Leave vault (owner blocked) |
| DELETE | `/:id/members/:user_id` | ❌ | Remove member (owner only) |
| POST | `/:id/transfer-ownership` | ❌ | Transfer vault ownership |

### Payments (`/api/v1/payments`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| POST | `/create` | ✅ | Generate Midtrans Snap token → redirect to payment page |
| GET | `/history` | ❌ | Payment history for current user |
| POST | `/webhook/midtrans` | N/A | Midtrans notification webhook (backend-only) |

### Family Payments (`/api/v1/family/:vault_id/payments`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| POST | `/:vault_id/payments/generate` | ❌ | Generate payment records for all vault members |
| GET | `/:vault_id/payments` | ❌ | List vault payments (owner only) |
| POST | `/:vault_id/payments/:member_id/mark-paid` | ❌ | Member marks own payment as paid |
| PUT | `/:vault_id/payments/:payment_id/confirm` | ❌ | Owner confirms paid payment |
| GET | `/:vault_id/payments/summary` | ❌ | Payment summary (total paid/pending/collected) |

### Detector (`/api/v1/detect`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| POST | `/` | ❌ | Upload PDF/image → OCR → LLM+keyword detect → preview list |
| POST | `/confirm` | ❌ | Bulk-create selected detections into subscriptions |

### Notifications (`/api/v1/notifications`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| POST | `/register-token` | ❌ | Register FCM token |
| POST | `/send-test` | ❌ | Send test push notification |
| GET | `/settings` | ❌ | Get notification settings |
| PUT | `/settings` | ❌ | Update notification settings |

### Admin Scheduler (`/api/v1/admin/scheduler`)
| Method | Path | Mobile Integrated | Description |
|--------|------|-------------------|-------------|
| POST | `/trigger-billing-check` | N/A | Admin only |
| POST | `/trigger-trial-check` | N/A | Admin only |
| GET | `/status` | N/A | Admin only |

## Mobile Integration Status (as of 2026-06-08)

### ✅ Already in `api_service.dart`:
- `login()`, `register()`, `getMe()`
- `getSubscriptions()`, `createSubscription()`, `updateSubscription()`, `deleteSubscription()`
- `getStats()`
- `createFamilyVault()`, `joinFamilyVault()`
- `createPayment()`

### ❌ NOT yet in `api_service.dart` (need to add):
- `getSubscription(id)` — GET `/api/v1/subscriptions/:id`
- `getMyVaults()` — GET `/api/v1/family/my-vaults`
- `getVaultMembers(id)` — GET `/api/v1/family/:id/members`
- `updateVault(id, name)` — PUT `/api/v1/family/:id`
- `deleteVault(id)` — DELETE `/api/v1/family/:id`
- `leaveVault(id)` — POST `/api/v1/family/:id/leave`
- `removeMember(vaultId, userId)` — DELETE `/api/v1/family/:id/members/:user_id`
- `transferOwnership(vaultId, newOwnerId)` — POST `/api/v1/family/:id/transfer-ownership`
- `getPaymentHistory()` — GET `/api/v1/payments/history`
- `uploadDetection(file)` — POST `/api/v1/detect` (multipart upload)
- `confirmDetection(items)` — POST `/api/v1/detect/confirm` (bulk-create)
- `registerFcmToken(token)` — POST `/api/v1/notifications/register-token`
- `sendTestNotification()` — POST `/api/v1/notifications/send-test`
- `getNotificationSettings()` — GET `/api/v1/notifications/settings`
- `updateNotificationSettings(enabled)` — PUT `/api/v1/notifications/settings`

## OCR Detector — Implementation & Flow

### Current Implementation (2026-06-12)
- PDF: `pdfplumber` → extract text per page from `BytesIO(content)`
- Image: `PIL.Image.open(BytesIO(content))` → `pytesseract.image_to_string()`
- **LLM-first detection**: `detect_subscriptions_with_llm()` via OpenRouter — primary detector
- **Keyword fallback**: `detect_from_text(text)` from `services/detector.py` — used when LLM returns empty (no API key, timeout, or parse failure)
- LLM model: `openrouter/owl-alpha` (configurable via `OPENROUTER_API_KEY` in `.env.production`)
- LLM response parser strips markdown code blocks (```` ```json ````) before JSON parse
- Free tier: 5x detect limit; Pro tier: unlimited
- Env verified: tesseract 5.3.4, pdfplumber, pytesseract, Pillow all OK

### Flow (KII approved 2026-06-12)
```
1. User uploads PDF/image → POST /api/v1/detect
   → OCR extract text → LLM detect → keyword fallback
   → Returns preview list [{name, category, price, confidence, source_line}]
2. Flutter shows preview → user checks which subscriptions to save
3. User taps "Save Selected" → POST /api/v1/detect/confirm
   → Backend bulk-inserts selected items into subscriptions table
```

**Why LLM first?** OCR text is often noisy (typos, merged words). LLM handles fuzzy matching better than keyword lookup.
**Why keyword fallback?** LLM requires API key + network. Keyword matching works offline.
**Why not auto-save?** OCR isn't always accurate — user must review first.
**Why bulk confirm?** 10 detected subs = 1 API call, not 10.

### OCR Keywords (27 services)
- **Entertainment**: NETFLIX, SPOTIFY, DISNEY, HOTSTAR, YOUTUBE, VIDIO, VIU, WE TV, IQIYI
- **Productivity**: CANVA, ICLOUD, GOOGLE ONE, CHATGPT, OPENAI, MIDJOURNEY, ADOBE, MICROSOFT, DROPBOX, GITHUB, FIGMA, NOTION, GRAMMARLY
- **Shopping**: TOKOPEDIA, BUKALAPAK, SHOPEE, LAZADA

## Backend TODOs (as of 2026-06-14)
1. ✅ OCR Detector — implemented and pushed (2026-06-08)
2. ✅ Family Vault CRUD — all 9 endpoints done (2026-06-12)
3. ✅ OCR detect/confirm — POST /api/v1/detect/confirm bulk-create (2026-06-12)
4. ✅ FREE tier OCR — 5x detect limit for beta testing (2026-06-12)
5. ✅ Endpoint auth tests — 55 tests passing (2026-06-14)
6. ✅ LLM fallback — OpenRouter owl-alpha primary, keyword fallback (2026-06-12)
7. ✅ Midtrans Snap integration — token generation + webhook handler (2026-06-14)
8. ✅ Family payment tracking — 5 endpoints: generate, list, mark-paid, confirm, summary (2026-06-14)
9. ❌ Alembic migrations verify
10. ❌ Celery/Beat workers — not running on VPS, alerts don't work
11. ❌ SSL/Domain via NPM + Let's Encrypt
12. ❌ Flutter API integration — new endpoints (family payments, detector) not yet in `api_service.dart`

## Production Deployment State (as of 2026-06-12)

| Component | Container | Status |
|-----------|-----------|--------|
| API | `subtrack-api` | ✅ Running, port 8002→8000 |
| PostgreSQL | `postgres` | ✅ Running |
| Redis | `backend_redis_1` + `redis` | ✅ Both running |
| NPM | `npm_npm_1` | ✅ Running |
| Celery Worker | `subtrack-celery-worker` | ❌ NOT running |
| Celery Beat | `subtrack-celery-beat` | ❌ NOT running |
| SSL | — | ❌ NOT set up |
| Midtrans | — | Sandbox mode |

## Deploy Workflow
KII rebuilds manually — never auto-deploy. VPS: 202.10.46.161.
If container recreate fails with `ContainerConfig` error:
```
docker compose -f backend/docker-compose.prod.yml down subtrack-api
docker compose -f backend/docker-compose.prod.yml up -d --build subtrack-api
```
### Go-Public Readiness
- **For beta testers (10-20 people)**: Possible NOW if SSL is set up (30 min via NPM + Let's Encrypt). Payment flow READY (Midtrans Snap integrated 2026-06-14). Push notifications won't work without Celery. OCR detect+confirm+LLM is DONE. Family vault + payments DONE.
- **For real public launch**: Need SSL + Celery = ~1 day work. Core features (OCR, family vault, payments) are DONE.

## 🔴 CRITICAL: Payment API Keys — Manual Setup Only

**NEVER put real API keys (Midtrans, Firebase, Stripe, etc.) into `.env` via agent session.** Keys can leak in logs, git history, or session transcripts.

When KII provides real keys:
1. Acknowledge receipt
2. Give the exact manual steps (edit .env + restart)
3. Do NOT apply via agent — let KII run the commands himself
4. After KII confirms, run tests to verify the integration works

This is a security rule, not just a preference.

The SubTrack repo root is `/root/projects/subtrack-id/` and the backend code lives in `/root/projects/subtrack-id/backend/`. These are the SAME repo (not submodules), but running git commands from `backend/` causes path issues:

- Files like `docs/plans/` live in the repo root, NOT in `backend/`
- Running `git add docs/plans/...` from `backend/` fails with "pathspec did not match"
- Running `git stash` from `backend/` may not stash changes in root-level files

**Always use absolute paths or run git from repo root:**
```bash
# ✅ Correct — use absolute paths
git -C /root/projects/subtrack-id add docs/plans/somefile.md

# ✅ Correct — cd to repo root first
cd /root/projects/subtrack-id && git add .

# ❌ Wrong — running from backend/ with relative paths
cd backend && git add docs/plans/somefile.md  # FAILS
```

## ⚠️ CRITICAL PITFALL: SQLEnum `values_callable` for PostgreSQL-native enums

When using `SQLEnum(SomeEnum)` with PostgreSQL, if the enum type was created manually in DB (e.g. `CREATE TYPE familyrole AS ENUM ('ADMIN', 'MEMBER')`), SQLAlchemy may fail to map values correctly. Add `values_callable` to ensure SQLAlchemy stores the `.value` strings:

```python
# ✅ Correct — tells SQLAlchemy to use .value for DB storage
role = Column(SQLEnum(FamilyRole, values_callable=lambda x: [e.value for e.x]), default=FamilyRole.MEMBER)

# ❌ Wrong — may try to store enum name instead of value
role = Column(SQLEnum(FamilyRole), default=FamilyRole.MEMBER)
```

This applies to ANY `SQLEnum` column where the PostgreSQL enum type was created manually via raw SQL or migration.

## ⚠️ CRITICAL PITFALL: SQLAlchemy Enum Value Mismatch (NOTE: now UPPERCASE)

**Symptom:** HTTP 500 on any endpoint that loads a User from DB (e.g. `GET /api/v1/auth/me`).
**Root cause:** Enum values in Python code must match DB values EXACTLY. SQLAlchemy/SQLEnum does NOT auto-convert case.

**Current state (as of commit 41db392):** `UserTier` enum values are now UPPERCASE (`FREE`, `PRO`, `FAMILY`) to match PostgreSQL enum type. DB values must also be uppercase.

**How it happens:**
- KII manually updates tier in DB: `UPDATE users SET tier = 'family' WHERE ...`
- Python `UserTier` enum has `FAMILY = "FAMILY"` (uppercase)
- SQLAlchemy tries to construct `UserTier("family")` → fails because `"family" ∉ {"FREE", "PRO", "FAMILY"}`

**Fix:** Always use UPPERCASE when manually updating enum columns:
```sql
-- ✅ Correct
UPDATE users SET tier = 'FAMILY' WHERE email = '...';
-- ❌ Wrong
UPDATE users SET tier = 'family' WHERE email = '...';
```

**General rule:** For any `str, enum.Enum` + `SQLEnum` column, the stored DB value is whatever the `.value` is — currently UPPERCASE for `UserTier`, `FamilyRole`, `BillingCycle`, `Category`, `PaymentStatus`, `PaymentMethod`. Always match the exact case when manually updating DB enum columns.

## ⚠️ CRITICAL PITFALL: Firebase Auth Token vs FCM Token

Two completely different tokens in Firebase — never confuse them:

| | Firebase Auth Token (ID Token) | FCM Registration Token |
|---|---|---|
| **Source** | `FirebaseAuth.instance.currentUser.getIdToken()` | `FirebaseMessaging.instance.getToken()` |
| **Format** | JWT (3 segments, dots) | Long random string |
| **Expires** | 1 hour (auto-refresh) | Long-lived, can change |
| **Auth header** | `Authorization: Bearer <token>` | Not used in headers |
| **Backend verify** | `verify_firebase_token()` in `auth.py` | Stored via `POST /notifications/register-token` |
| **Used for** | Authenticate API requests | Send push notifications |

**Common mistake:** Passing FCM token as Bearer, or vice versa. Backend will return 401 for wrong token type.
