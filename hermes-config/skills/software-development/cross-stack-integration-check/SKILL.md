---
name: cross-stack-integration-check
description: "Detect integration gaps between backend API endpoints and frontend mobile/web screens. Scans backend routes vs frontend API calls, cross-checks models/schemas, and auto-generates a report of missing/unused endpoints and mismatched contracts."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [integration, cross-stack, api, backend, frontend, gap-analysis]
    related_skills: [codebase-inspection, github-code-review, systematic-debugging]
---

# Cross-Stack Integration Check

## Overview

Detect integration gaps between backend API endpoints and frontend mobile/web screens. Scans backend routes vs frontend API calls, cross-checks models/schemas, and generates a structured report of:

- **Backend endpoints never called from frontend** (dead code / unused APIs)
- **Frontend screens calling non-existent endpoints** (404 / missing backend)
- **Model/schema mismatches** (field name, type, required vs optional)
- **Auth/permission gaps** (frontend assumes access but backend restricts)

**Stack-agnostic:** Works with ANY backend + frontend combination. Auto-detects tech stack from file extensions and patterns.

## When to Use

- After completing a feature that touches both backend and frontend
- During code review of cross-stack PRs
- When planning next sprint — identify what's left to integrate
- User asks: "cek mana yang belum ke-integrate", "backend kurang apa", "frontend kurang apa"

## Prerequisites

- Backend repo path (e.g., `/root/projects/subtrack-id/backend`)
- Frontend repo path (e.g., `/root/projects/subtrack-id/mobile`)
- Both repos pulled to latest code

## The Process

### Phase 0: Auto-Detect Tech Stack

Before scanning, detect the tech stack from file extensions and directory structure:

```
1. List file extensions in both repos
2. Identify backend framework from:
   - *.py → check for FastAPI (router), Django (urls.py), Flask (@app.route)
   - *.ts / *.js → check for Express (app.get), NestJS (@Controller), Fastify
   - *.java / *.kt → check for Spring Boot (@RestController), Ktor
   - *.go → check for Fiber, Gin, Echo
   - *.rb → check for Rails, Sinatra
   - *.rs → check for Actix, Axum, Rocket
3. Identify frontend framework from:
   - *.dart → Flutter
   - *.tsx / *.jsx → React / Next.js
   - *.vue → Vue / Nuxt
   - *.swift → iOS (SwiftUI / UIKit)
   - *.kt → Android (Kotlin)
```

Based on detected stack, use the appropriate scan patterns from the tables below.

### Phase 1: Extract Backend Endpoints

Scan the backend codebase and extract ALL API endpoints:

#### Universal Detection Strategy

```bash
# Step 1: Find all route/controller files
# Backend file patterns to scan:
# - Python: **/routes/*.py, **/views.py, **/urls.py, **/controllers/*.py
# - JS/TS: **/routes/*.ts, **/controllers/*.ts, **/app.ts, **/server.ts
# - Java/Kotlin: **/*Controller.java, **/*Controller.kt
# - Go: **/routes/*.go, **/handlers/*.go, **/main.go
# - Ruby: **/routes.rb, **/controllers/**/*.rb
# - Rust: **/routes/*.rs, **/handlers/*.rs

# Step 2: Extract endpoint patterns based on detected framework
```

#### Backend Scan Patterns by Framework

| Framework | Endpoint Pattern | Example |
|-----------|-----------------|---------|
| **FastAPI** | `@router.<method>(` or `@app.<method>(` | `@router.get("/{vault_id}/payments")` |
| **Express.js** | `app.<method>(` or `router.<method>(` | `app.get('/api/v1/users', ...)` |
| **NestJS** | `@<Method>(` decorator | `@Get('/:id')`, `@Post()` |
| **Django** | `path(` or `re_path(` in urls.py | `path('api/v1/', views.UserView.as_view())` |
| **Flask** | `@app.route(` or `@blueprint.route(` | `@app.route('/api/v1/users')` |
| **Spring Boot** | `@RequestMapping`, `@GetMapping`, `@PostMapping` | `@GetMapping("/api/v1/users")` |
| **Ktor** | `get(`, `post(`, `route(` | `get("/api/v1/users")` |
| **Go Fiber** | `app.Get(`, `app.Post(`, `app.Group(` | `app.Get("/api/v1/users")` |
| **Gin** | `r.GET(`, `r.POST(`, `router.GET(` | `r.GET("/api/v1/users", handler)` |
| **Ruby on Rails** | `get `, `post `, `resources ` in routes.rb | `get '/api/v1/users'` |
| **Actix (Rust)** | `#[get("`, `#[post("`, `#[actix_web::get("` | `#[get("/api/v1/users")]` |
| **Axum (Rust)** | `.route(` or `Router::new(` | `.route("/api/v1/users", get(handler))` |

#### For each endpoint, capture:
- HTTP method (GET/POST/PUT/PATCH/DELETE)
- URL path (with parameters)
- Request body model (if any)
- Response model
- Auth/permission decorators (if any)
- File path and line number

### Phase 2: Extract Frontend API Calls

Scan the frontend codebase and extract ALL API calls:

#### Frontend Scan Patterns by Framework

| Framework | API Call Pattern | Example |
|-----------|-----------------|---------|
| **Flutter/Dart** | `dio.<method>(`, `_dio.<method>(`, `http.<method>(` | `dio.get('/api/v1/family')` |
| **React/Next.js** | `fetch(`, `axios.<method>(`, `api.<method>(` | `fetch('/api/v1/users')` |
| **Vue/Nuxt** | `axios.<method>(`, `useFetch(`, `$fetch(` | `axios.get('/api/v1/users')` |
| **Angular** | `this.http.<method>(` | `this.http.get('/api/v1/users')` |
| **iOS/Swift** | `URLSession`, `Alamofire` | `AF.request("/api/v1/users")` |
| **Android/Kotlin** | `retrofit2`, `OkHttp` | `apiService.getUsers()` |
| **React Native** | `fetch(`, `axios.<method>(` | Same as React |

#### For each API call, capture:
- HTTP method
- URL path (handle dynamic interpolation: `$var`, `${var}`, `:var`)
- Query parameters
- Request body structure
- Which screen/component makes the call
- File path and line number

### Phase 3: Cross-Check Models/Schemas

Extract backend response schemas and frontend models:

#### Backend Schema Patterns

| Framework | Schema Location | Pattern |
|-----------|----------------|---------|
| **FastAPI** | `app/schemas/*.py` | `class X(BaseModel):` |
| **Express/NestJS** | `*.dto.ts`, `*.schema.ts`, `*.interface.ts` | `export interface X`, `export class XDto` |
| **Django** | `serializers.py` | `class XSerializer(serializers.ModelSerializer):` |
| **Spring Boot** | `*Dto.java`, `*Response.java` | `public class XDto` |
| **Go** | `*.go` | `type XResponse struct` |
| **Ruby** | `app/serializers/*.rb` | `class XSerializer` |
| **Rust** | `*.rs` | `#[derive(Serialize)] struct XResponse` |

#### Frontend Model Patterns

| Framework | Model Location | Pattern |
|-----------|---------------|---------|
| **Flutter** | `lib/models/*.dart` | `class X { ... fromJson() }` |
| **React/TS** | `src/types/*.ts`, `src/models/*.ts` | `interface X`, `type X` |
| **Vue** | `src/types/*.ts`, `src/models/*.ts` | `interface X` |
| **Angular** | `src/app/models/*.ts` | `interface X` |
| **iOS/Swift** | `*.swift` | `struct X: Codable` |
| **Android/Kotlin** | `*.kt` | `data class X` |

#### Comparison Checklist
For each backend schema field, check:
- [ ] Does frontend model have the same field?
- [ ] Type compatible? (float vs int, string vs String)
- [ ] Required vs optional match?
- [ ] Naming convention match? (snake_case vs camelCase — note as "convention diff" not "mismatch")

### Phase 4: Generate Gap Report

Produce a structured report:

```markdown
# Cross-Stack Integration Report

**Backend:** `<backend_path>` (detected: <framework>)
**Frontend:** `<frontend_path>` (detected: <framework>)
**Date:** YYYY-MM-DD

---

## 🔴 Critical: Frontend Calls Missing Backend

| Screen | API Call | Issue |
|--------|----------|-------|
| PaymentScreen | PUT /api/v1/family/{id}/payments/{id}/cancel | Endpoint not found (404) |

## 🟡 Warning: Backend Endpoints Unused by Frontend

| Endpoint | Since | Note |
|----------|-------|------|
| GET /api/v1/family/{id}/settings | 2026-06-01 | Not called from any screen |

## 🟠 Model Mismatches

| Field | Backend | Frontend | Issue |
|-------|---------|----------|-------|
| FamilyPayment.amount | float | int | Type mismatch |
| FamilyMember.share_percentage | float | missing | Field not in Flutter model |

## ✅ Integrated (No Issues)

| Endpoint | Frontend Screen |
|----------|----------------|
| GET /api/v1/family/{id}/payments | PaymentListScreen |
| POST /api/v1/family/{id}/payments/{id}/proof | PaymentProofScreen |

---

## Summary

- **Critical:** N frontend calls have no backend
- **Warning:** N backend endpoints unused
- **Mismatch:** N field discrepancies
- **OK:** N endpoints properly integrated
```

## Auto-Create Todo Items (Optional)

When user says "masukin ke todo" or "create tasks", convert gaps into actionable todo items:

1. **Critical gaps** → High priority tasks
   - Format: `[ ] Fix: Add backend endpoint {method} {path} for {screen}`
   - Format: `[ ] Fix: Frontend screen {screen} expects {endpoint} but backend missing`

2. **Warning gaps** → Medium priority tasks
   - Format: `[ ] Review: Backend endpoint {method} {path} unused — remove or integrate`
   - Format: `[ ] Integrate: Add {endpoint} to {screen} in Flutter`

3. **Model mismatches** → Low-medium priority tasks
   - Format: `[ ] Fix: Sync {model}.{field} — backend: {type}, frontend: {type}`

Use the `daily-worklist` skill to append these tasks to today's todo file.

## Pitfalls

1. **Dynamic URLs** — Frontend may construct URLs with string interpolation (`/api/v1/family/$vaultId/payments`, `/api/v1/users/${userId}`). These are valid matches.
2. **Query parameters** — Backend may define params that frontend doesn't use (not a gap, just unused params).
3. **Admin/internal endpoints** — Some backend endpoints are for internal/admin use and intentionally not called from frontend. Mark as "Expected" in report.
4. **WebSocket/SSE** — These are different from REST endpoints. Handle separately.
5. **API client wrappers** — Frontend may use wrapper functions that call a shared HTTP client. Trace through to find actual URLs.
6. **Convention differences** — snake_case (Python) vs camelCase (JS/TS) is normal. Don't flag as mismatch unless the actual field name differs.
7. **Versioned endpoints** — `/api/v1/` vs `/api/v2/` may be intentional. Check if both versions are in use.
8. **Duplicate model names** — Frontend may have multiple model files for the same entity (e.g., `family.dart` and `family_member.dart`). Check ALL model files, not just the first match.
9. **New files from concurrent edits** — Frontend may have new files added between pull and scan (e.g., KII working in parallel). Always `git pull` immediately before scanning.
9. **SSL/domain config** — When checking production readiness, verify `DOMAIN` config in backend matches the actual production domain (not `localhost`).
8. **Model fields added but not displayed** — Backend may return fields that frontend model doesn't parse (not shown in UI). Flag as "unused on frontend" — either add to model or confirm intentional.
9. **Flutter model naming** — Flutter models may use different field names than backend (e.g., `proofUrl` vs `proof_url`). Check `fromJson` mapping, not just field names.
10. **Test assertions on dynamic config values** — Tests that hardcode URLs/domains (e.g., `https://localhost:8000/...`) break when `DOMAIN` config changes to production. Use flexible assertions (check path substring) or read from environment/config in tests.
10. **Type coercion traps** — Backend `Optional[str]` for date fields (e.g., `first_payment_month`) vs Flutter `int?` is a real mismatch even if both are "optional". Always check the inner type, not just nullability. ISO date strings ≠ integers.
- **Flutter build is local** — Flutter SDK is typically NOT on VPS. KII builds APK/AAB from local PC. Don't suggest `flutter build` on VPS unless confirmed installed.
- **Tier revision analysis** — When reviewing pricing tiers, don't just list features. Analyze whether the lowest tier "feels complete" for basic use cases. If every feature is locked behind upgrade, the free tier feels abandoned. Recommendation: give free tier a functional basic experience, lock power-user features (history, audit, API) behind paid tiers.
- **Test URL assertions break on domain change** — Tests that hardcode full URLs (e.g., `https://localhost:8000/uploads/...`) break when `DOMAIN` config changes. Use flexible assertions like `"uploads/proofs/test.jpg" in p["proof_url"]` instead of exact string match. Never import `app.config` in test files — it may fail due to circular imports in test context. Also avoid `os.environ.get("DOMAIN")` in tests — the test environment may inherit production defaults from config class variables, giving unexpected values.
- **Testing in Docker containers when host lacks dependencies** — When local Python venv is missing packages (e.g., `aiosqlite`, `sentry_sdk`, `asyncpg`) and `pip install` times out (slow network), copy code to an existing Docker container that has the deps and run tests there. Use `docker cp . /app/<project>/` then `docker exec <container> bash -c "export PYTHONPATH=/app/<project>; cd /app/<project>; python3 ..."`. Mock `sentry_sdk` with `import types; sys.modules['sentry_sdk'] = types.ModuleType('sentry_sdk'); sys.modules['sentry_sdk'].init = lambda *a, **k: None` if not installed. Use SQLite in-memory (`sqlite+aiosqlite:///:memory:`) for isolated tests if PostgreSQL is unreachable from the container.

## Production SSL & DNS Troubleshooting

### NPM Nginx Config Regeneration (When UI Inaccessible)

When NPM container is running but UI (port 81) is not accessible, nginx config must be written manually:

```bash
# 1. Find NPM container ID and exec into it
docker ps | grep npm
docker exec -it <npm_container_id> bash

# 2. Get proxy host configs from NPM database
cat /root/npm/data/database.sqlite3 | sqlite3 | select id, domain_names, forward_host, forward_port, certificate_id, ssl_forced from proxy_hosts;

# 3. Write nginx config to /etc/nginx/conf.d/<domain>.conf
# 4. Include SSL cert paths from /root/npm/letsencrypt/live/npm-N/
openssl x509 -in /root/npm/letsencrypt/live/npm-1/cert.pem -noout -subject  # verify domain
# 5. Test & reload
docker exec <npm_container_id> nginx -t
docker exec <nginx_container_id> nginx -s reload
```

### Cloudflare 525 Error
- **Cause:** Cloudflare SSL/TLS mode set to **Full** but origin only serves HTTP (or vice versa)
- **Fix:** 
  - If origin has valid Let's Encrypt cert → set Cloudflare to **Full**
  - If origin has no cert → set Cloudflare to **Flexible** (but shows 🔓 in browser)
- **DNS-only (grey cloud)** required for Let's Encrypt HTTP-01 challenge on subdomains
  - `api.subtrack` CNAME → `devlokal.id`, grey cloud, proxied=NO
  - `devlokal.id` and `www.devlokal.id` A records, orange cloud, proxied=YES

### Docker network_mode: host for NPM
When `docker-proxy` conflicts with NPM nginx on port 80/443, change NPM `docker-compose.yml`:
```yaml
services:
  npm:
    network_mode: host  # bypasses docker-proxy port mapping
```
Then `forward_port` in proxy hosts must be the **container port** (not host-mapped port).

### Firebase Google Sign-In for Mobile
If Google Sign-In popup doesn't appear in Flutter mobile app:
1. Add **SHA-1 fingerprint** to Firebase Console → Project Settings → Android App
   - Debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1`
   - Release: same command with release keystore path
2. Enable Google Sign-In in Firebase Console → Authentication → Sign-in method → Google → Enable
3. Ensure package name matches exactly between Firebase Console and `android/app/build.gradle`
4. Re-download `google-services.json` after adding SHA-1
5. Rebuild Flutter app

### Cloudflare SSL/TLS Mode Quick Check
```bash
# Test if HTTPS works from outside
curl -I https://your-domain.com
# If fails with SSL error → check Cloudflare SSL mode
# If returns 200 → HTTPS is working, issue is likely app-side (Firebase config)
```

## SubTrack ID Specific Patterns

See `references/subtrack-id-integration-report.md` for project-specific scan results, known integration points, infrastructure details, and integration check history.

See `references/tier-pricing-strategy.md` for framework when KII asks about tier/pricing revision strategy.

See `references/testing-in-docker-container.md` for testing workaround when host Python venv lacks dependencies but a Docker container has them.

### Gdrive Storage (New Project — June 2026)
- **Backend:** FastAPI at `/root/projects/gdrive-storage/backend`
- **Frontend:** Next.js at `/root/projects/gdrive-storage/frontend`
- **DB:** PostgreSQL `gdrive_storage`, user `hermes`, pass `hermespassword`
- **Repo:** `Dwiki13/gdrive-storage` (private)
- **Sprint Plan:** All 8 sprints marked complete (KII coded manually)
- **Key features:** Multi-account Google Drive manager, auto-balance upload, subscription billing (Midtrans), quota monitoring
- **Tiers (proposed revision):** Free (2 drives, 30GB, search/filter/sort/quota overview), Lite (5 drives, 75GB, + quota history chart), Pro (15 drives, 225GB, + activity logs + API + file versioning)
- **Prices (proposed):** Free Rp 0, Lite Rp 19.000, Pro Rp 49.000
- **Testing note:** Run tests inside `subtrack-api` container (has all deps), not host venv (missing sentry-sdk, aiosqlite, asyncpg). Mock sentry_sdk with `types.ModuleType` if not installed.

## Integration with Other Skills

- **`codebase-inspection`** — Use to get LOC/metrics for scope estimation
- **`github-code-review`** — Use to review cross-stack PRs
- **`systematic-debugging`** — Use when frontend calls fail due to backend issues
- **`daily-worklist`** — Use to auto-create todo items from gap report

## Output Delivery

When run in Topic Coding (telegram:-1003966561389:1116):
- Send full report as message (under 4096 chars for Telegram)
- If report is long, split into sections
- Always include summary counts at top
- Include detected tech stack in header

When run with auto-todo:
- Append tasks to `/root/todo-YYYY-MM-DD.md`
- Use `daily-worklist` skill format
- Mark origin as "Integration Check"

## Lessons Learned

1. **Always `git pull` both repos before scanning** — concurrent edits between sessions cause false gaps
2. **Check ALL model files** — Flutter may have multiple model files for the same entity (e.g., `family.dart` AND `family_member.dart`)
3. **Distinguish "unused" from "admin-only"** — scheduler triggers, webhooks, and send-test endpoints are expected unused by frontend
4. **SSL is separate from code deployment** — check NPM/Docker config for SSL, not just code
5. **Backend billing logic is authoritative** — Flutter should display `payment.amount` from backend, never calculate locally
6. **Use compact output for large endpoint lists** — When >30 endpoints are integrated, use "✅ 41 endpoints integrated" instead of listing each one. Split into 2 messages: gaps first, full details on request.
7. **Nginx cannot coexist with NPM on same port** — If Nginx Proxy Manager is already running on port 80/443, use NPM's Proxy Host feature instead of installing standalone Nginx
8. **Migration chain must be continuous** — When creating Alembic migrations, ensure the `Revises` field points to the correct parent revision. Broken chains cause `KeyError` on `alembic heads`
9. **NPM database survives container rebuilds** — NPM's SQLite DB at `/root/npm/data/` is volume-persisted. Proxy hosts, SSL certs references survive container restarts. Always check DB before rebuilding config.
10. **Cloudflare grey cloud (DNS-only) is required for Let's Encrypt** — When a subdomain needs HTTP-01 challenge validation, the DNS record MUST be grey cloud (proxied=NO). Orange cloud (proxied=YES) breaks the challenge because Cloudflare proxies the traffic.
- **Firebase SHA-1 fingerprint is mandatory** — Google Sign-In in Flutter mobile apps silently fails (no popup) if SHA-1 isn't registered in Firebase Console. Both debug and release fingerprints need to be added separately.
- **Mobile app cache after backend SSL change** — When backend HTTPS/cert changes, mobile apps may fail to connect even after rebuild. The fix is **Clear Data** (Settings → Apps → [App] → Clear Data) or uninstall+reinstall. The app caches old SSL session/connection state. This is faster than rebuilding.

### Model Field Detection
- Backend Pydantic `Optional[str] = None` → frontend `String?` is a match (just naming convention)
- Backend `float` → frontend `double` (Dart) or `number` (TS) is compatible
- Backend `int` → frontend `int` (Dart) or `number` (TS) is compatible
- Only flag as mismatch when types are truly incompatible (e.g., backend `float` vs frontend `String`)
- **⚠️ `Optional[str]` vs `int?` is a REAL mismatch** — even though both are "optional", the inner types differ. Backend string `'YYYY-MM'` ≠ integer month 1-12. Fix by changing backend return type (e.g., `.month` instead of `.strftime('%Y-%m')`)
- **⚠️ Date vs integer traps** — Backend may return `str` (ISO date/datetime) while frontend expects `int` (month/year). Check the actual return type in the route handler, not just the schema declaration.
- **When fixing mismatches:** Prefer changing backend to match frontend (less client-side impact). If frontend already has the correct type, backend should adapt.
- **`Optional[str]` vs `int?` example:** Backend returned `'YYYY-MM'` string for `first_payment_month`, Flutter expected `int?`. Fix: backend changed to return `.month` (int 1-12) instead of `.strftime('%Y-%m')`.
- **Date/return type mismatches** — Backend may return `str` (ISO date/datetime) while frontend expects `int` (month/year). Check the actual return type in the route handler, not just the schema declaration. Fix by aligning backend return type to frontend expectation when frontend is authoritative (e.g., Flutter `int?` → backend should return `.month` not `.strftime('%Y-%m')`).

### Dynamic URL Matching
Flutter uses `$variable` and `${variable}` in URL strings. When matching:
- `/api/v1/family/$vaultId/payments` matches `GET /api/v1/family/{vault_id}/payments`
- Strip `$` and `{}` from Flutter URLs before comparing with backend path params

When run with auto-todo:
- Append tasks to `/root/todo-YYYY-MM-DD.md`
- Use `daily-worklist` skill format
- Mark origin as "Integration Check"
