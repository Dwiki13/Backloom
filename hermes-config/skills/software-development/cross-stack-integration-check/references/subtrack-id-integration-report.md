# SubTrack ID Integration Report — 2026-06-25

## Project Layout
- **Backend:** `/root/projects/subtrack-id/backend` — FastAPI + PostgreSQL + Celery
- **Frontend:** `/root/projects/subtrack-id/mobile` — Flutter/Dart + Dio HTTP client
- **API prefix:** `/api/v1/`
- **Production API:** `https://api.subtrack.devlokal.id` (SSL via Nginx Proxy Manager)

## Integration Status v6 (2026-06-25)

### ✅ Fully Integrated (44 endpoints)

All major flows connected:
- Auth (login/register/me/profile/upload-photo)
- Subscriptions (CRUD + stats/summary + stats/trend + cancel/downgrade)
- Family vault (CRUD + join/leave/transfer + payment_info)
- Family payments (list/mark-paid/confirm/reject/history/summary)
- Payment proofs (upload/get/delete)
- Vault subscriptions (add/list/remove)
- Notifications (list/mark-read/read-all/register-token/settings)
- Admin scheduler (trigger-billing/trial/overdue + status)
- Detector (detect/confirm)
- Payments (create/history/cancel/downgrade)

### 🟠 Model Mismatches
None.

### 🟡 Unused Backend Endpoints (Expected)

| Endpoint | Reason |
|----------|--------|
| POST /api/v1/notifications/send-test | Admin/dev only |
| POST /api/v1/payments/webhook/midtrans | Midtrans callback |

## Change Log

### 2026-06-25 (v6)
- Added: `PUT /api/v1/auth/profile` — update display_name & photo_url
- Added: `POST /api/v1/auth/upload-photo` — multipart photo upload
- Added: `POST /api/v1/payments/cancel` — cancel subscription (keeps tier until expiry)
- Added: `POST /api/v1/payments/downgrade` — immediate revert to free
- Fixed: delete proof permission — only block when status=CONFIRMED
- Fixed: delete proof reverts status from AWAITING_CONFIRM to PENDING
- Result: 0 critical, 0 mismatch, 2 expected unused, 44 integrated

### 2026-06-20 (v5)
- Fixed: `first_payment_month` type — backend `Optional[str]` → `Optional[int]`
- Result: 0 critical, 0 mismatch, 2 expected unused, 44 integrated

### 2026-06-19 (v3)
- All Flutter models updated by KII
- Result: 0 critical, 0 mismatch, 2 unused, 42 integrated

### 2026-06-19 (v1)
- Initial scan
- Result: 5 critical, 11 mismatches, 3 unused

## Backend Conventions
- Routes: `app/routes/*.py` with `@router.(get|post|put|patch|delete)`
- Schemas: `app/schemas/*.py` Pydantic BaseModel
- Models: `app/models/*.py` SQLAlchemy
- Auth: JWT via `get_current_user` dependency
- Tests: `tests/` with `pytest`, `TestingSessionLocal`, `set_auth_user()`
- Config: `app/config.py` with `DOMAIN` env var

## Frontend Conventions
- API calls: `lib/services/api_service.dart` via `_dio.(get|post|put|patch|delete)`
- Models: `lib/models/*.dart` with `fromJson` factory
- Screens: `lib/screens/**/*.dart`
- Auth: token stored in Dio interceptors

## Known Pitfalls
- Flutter model field names use camelCase vs backend snake_case — Dio handles this
- Backend returns `403` for non-owner access to payment summary
- `payment_info` field on FamilyVault — owner sets bank/e-wallet info
- `stats/trend` returns 12-month data — Flutter displays as BarChart
- `first_payment_month` is computed field (not DB column)
- Tests should NOT hardcode full URLs — use flexible path assertions
- Tests should NOT import `app.config` — circular import risk
- **Google Sign-In popup not appearing** = SHA-1 fingerprint not registered in Firebase Console (add both debug + release)
- **Cloudflare 525 error** = SSL mode mismatch (set to Full when origin has valid cert, Flexible when no cert)
- **NPM forward_host must be IP** not hostname (NPM doesn't resolve Docker container names across networks)
