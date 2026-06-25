# SubTrack ID Integration Notes

## Project Structure
- **Backend:** FastAPI + PostgreSQL + Celery + Redis (Docker)
- **Frontend:** Flutter/Dart (Dio HTTP client)
- **VPS:** hermes.server.id (Docker Compose)
- **Domain:** api.subtrack.devlokal.id (via Nginx Proxy Manager)

## Key Conventions
- Backend URL prefix: `/api/v1/`
- Flutter API client: `lib/services/api_service.dart` (single file, all API calls)
- Flutter models: `lib/models/*.dart`
- Backend schemas: `app/schemas/*.py` (Pydantic)
- Backend routes: `app/routes/*.py` (FastAPI routers)

## Known Quirks
- Flutter has BOTH `family.dart` (FamilyVault) and `family_member.dart` (FamilyMemberModel) — check both
- `family_payment.dart` contains both `FamilyPayment` and `PaymentSummary` classes
- Backend `DOMAIN` config in `app/config.py` — must be updated for production
- Nginx Proxy Manager (NPM) handles SSL on port 80/443 — do NOT install separate Nginx
- Backend runs on port 8002 externally (mapped from container port 8000)
- Flutter uses camelCase (`proofUrl`) vs backend snake_case (`proof_url`) — Dio handles this automatically
- **`first_payment_month`**: Backend `FamilyMemberResponse.first_payment_month` = `Optional[int]` (month as int 1-12), Flutter `FamilyMemberModel.firstPaymentMonth` = `int?`. **FIXED — both sides now use int.**

## Docker Workflow
- Container `subtrack-api` runs backend on port 8002 (host-mapped)
- After ANY Python file edit: `docker cp <file> subtrack-api:/app/<path> && docker restart subtrack-api`
- Alembic head must be verified before feature work: `docker exec subtrack-api alembic current`
- Migration chain must be continuous — broken chains cause `KeyError` on `alembic heads`

## NPM (Nginx Proxy Manager) Coexistence
- Port 80/443 are handled by NPM container (`npm_npm_1`) with `network_mode: host`
- To add a new domain: use NPM UI (port 81) → Proxy Host → add domain → forward to container **IP** (not hostname)
- SSL: NPM handles Let's Encrypt certificates automatically
- **When NPM UI inaccessible:** write nginx config manually to `/etc/nginx/conf.d/<domain>.conf`, then `nginx -s reload`
- **Cloudflare SSL mode:** Must be **Full** (not Flexible) when origin has valid Let's Encrypt cert
- **Subdomain DNS:** Use CNAME with grey cloud (DNS-only, no proxy) for Let's Encrypt HTTP-01 challenge
- **forward_port** must be container port (8000), NOT host-mapped port (8002), because `network_mode: host` bypasses port mapping

## Flutter Build Environment
- Flutter SDK is NOT installed on VPS — KII builds APK/AAB from local PC (Android Studio / VS Code / PowerShell)
- Build commands: `flutter build apk --release` or `flutter build appbundle --release`
- After build: test internally → upload to Play Console ($25 one-time developer fee)
- **Google Sign-In popup not showing** = SHA-1 fingerprint missing in Firebase Console (add debug + release SHA-1)

## Integration Check History
- 2026-06-19 v1: 5 critical, 11 mismatches → 41 ok
- 2026-06-19 v2: 0 critical, 4 mismatches → 41 ok (KII fixed Flutter models)
- 2026-06-19 v3: 0 critical, 0 mismatches → 42 ok (KII fixed stats/trend + bar chart)
- 2026-06-20 v4: 0 critical, 1 mismatch → 44 ok
  - **Mismatch:** `first_payment_month` — backend `Optional[str]` vs Flutter `int?`
  - **Fix:** Backend changed to `Optional[int]` (returns month as int 1-12), Flutter already `int?` — no Flutter change needed
- 2026-06-20 v5: **0 critical, 0 mismatches → 44 ok** (after `first_payment_month` fix)
  - **2 expected unused:** `POST /send-test` (dev tool), `POST /webhook/midtrans` (callback)
  - **44 endpoints integrated** across auth, family, subscriptions, notifications, payments, detector, admin
- 2026-06-25 v6: **0 critical, 0 mismatches → 44 ok** ✅ (after auth profile, upload-photo, payment cancel/downgrade, delete-proof fixes)

## Current Status (June 25 2026)
- **Backend:** 100% complete (all endpoints, migrations, SSL, 120 tests passing)
- **Flutter:** ~95% complete (all models synced, all endpoints integrated, Google Sign-In working)
- **Infrastructure:** NPM nginx running with SSL for all domains, Cloudflare DNS configured
- **Remaining:** Build APK + deploy to Play Store (KII handles manually)
