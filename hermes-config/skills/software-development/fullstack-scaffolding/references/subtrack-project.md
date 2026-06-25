# SubTrack ID Project Reference

> Project: SubTrack ID — Subscription Tracker for Indonesian Market
> Repo: /root/projects/subtrack-id/
> Status: Scaffolded — plan.md + code structure ready (June 2026)

## Project Decisions

### Tech Stack
- **Backend**: Python 3.11, FastAPI, SQLAlchemy (ORM), PostgreSQL 16, Alembic
- **Mobile**: Flutter 3.x, Dart, Riverpod state management, go_router
- **Auth**: Firebase Auth (Email, Google, Apple)
- **Push**: Firebase Cloud Messaging
- **Payments**: Midtrans (IDR) + Stripe (international)
- **OCR**: Tesseract + Google Vision API (bank statement detection)
- **Container**: Docker Compose (DB + API + Redis)

### Why SQLAlchemy instead of asyncpg?
This project uses SQLAlchemy ORM (not raw asyncpg like Second Brain). Reasons:
- Faster development speed for CRUD-heavy app
- Alembic migrations built-in
- KII is familiar with ORM patterns
- Performance difference negligible at MVP scale
- Phase 1 (MVP): FastAPI for speed; Phase 2 (Scale): optionally migrate to Go

### Architecture
- REST API (FastAPI) ↔ Flutter mobile app
- Firebase Auth for authentication (Bearer token)
- E2EE cloud sync for sensitive data
- Midtrans for IDR payments (GoPay, OVA, Transfer)
- Free tier: 2 subscriptions max (conversion sweet spot)

### Pricing (IDR)
| Plan | Monthly | Yearly |
|------|---------|--------|
| Free | Rp 0 (max 2 subs) | Rp 0 |
| Pro | Rp 39.000 | Rp 390.000 |
| Family | Rp 59.000 | Rp 590.000 |

### Key Features
1. **Smart Detection**: OCR bank statement → auto-detect recurring charges (Pro)
2. **Trial Tracker**: Track free trials, remind before conversion
3. **Price Alert**: Detect price increases in recurring charges
4. **Family Vault**: Shared subscriptions with cost splitting
5. **Local-first**: Indonesian services, IDR currency, Midtrans payment

### Competitive Moat
- Local market focus (IDR, Indonesian services, Bahasa Indonesia)
- Shared vault for families (no competitor has this)
- Trial tracker (underserved pain point)
- Cheaper ($2.5/month vs Rocket Money $3-12/month)

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) created June 2026:
- 3 jobs: test-backend → build-docker → deploy
- Tests run on push/PR to main/develop
- Docker image pushed to GHCR on main merge
- Auto-deploy to VPS (202.10.46.161) via SSH
- Secrets needed: `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`

## VPS Deployment (June 2026)

### Final State
- **API**: `https://api.subtrack.devlokal.id` → NPM → `subtrack-api:8000` (internal)
- **Port**: 8002 on host (8000 taken by Portainer, 8001 by Second Brain)
- **SSL**: Let's Encrypt via NPM (certificate_id: 8, npm-8)
- **DNS**: `api.subtrack.devlokal.id` → A record → `202.10.46.161`
- **Containers**: subtrack-api, subtrack-celery-worker, subtrack-celery-beat, subtrack-redis
- **Networks**: `npm_default` (for NPM proxy) + `backend_net` (for PostgreSQL/Redis)
- **Database**: 5 tables created (users, subscriptions, family_vaults, family_members, payments)
- **Health check**: `curl https://api.subtrack.devlokal.id/health` → `{"status":"healthy","version":"1.0.0"}`

### Preferred Deploy Pattern (Fast)
```bash
docker cp <file> subtrack-api:/app/<path> && docker restart subtrack-api
```
- Use this for every code change — faster than rebuild
- No need to rebuild image for single-file changes

### Full Rebuild (When Needed)
```bash
docker-compose up -d --build api
docker-compose exec backend alembic upgrade head
```

### Deploy Gotchas
1. `docker restart` picks up changes because code is copied into container (not bind-mounted)
2. `git pull` on host does NOT affect running containers without explicit copy
3. VPS uses `docker-compose` (v1), not `docker compose` (v2)
4. Alembic `head` must be on VPS before applying migrations
5. Container does NOT bind-mount source code from host — must `docker cp` after ANY Python file edit
6. SQLAlchemy engine caches at import time — `.env.production` must be correct at image build time

### Remaining
- Flutter app `apiBaseUrl` updated to `https://api.subtrack.devlokal.id` (done June 2026)
- GitHub Secrets (`VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`) not yet set — CI/CD deploy won't work until added
- Task #13 (Midtrans payment flow) — HOLD until production keys ready
- Task #30 (App Store/Play Store prep) — pending
- Task #31 (Beta testing + bug fixes) — pending

### Deploy Gotchas (Updated June 2026)
1. `docker restart` does NOT pick up code changes — must rebuild image + recreate container
2. `git pull` on VPS host does NOT affect running containers without volume mount
3. Full deploy: `git pull` → `docker-compose -f docker-compose.prod.yml build <svc>` → `docker stop <container>` → `docker rm <container>` → `docker-compose -f docker-compose.prod.yml up -d <svc>`
4. `docker-compose up` fails if old container still exists — must `docker rm` first
5. Docker Compose v1 on VPS: use `docker-compose` not `docker compose`
6. SQLAlchemy engine caches at import time — `.env.production` must be correct at image build time
7. `write_file` redacts passwords — use `chr()` workaround or SCP + Python script on VPS
8. NPM forward port = container internal port (8000), not host-mapped port (8002)

## Auth Contract: Flutter ↔ FastAPI

### Critical Pattern: Bearer Token Only
The backend `/api/v1/auth/register` and `/api/v1/auth/login` endpoints **only accept Bearer token** in the Authorization header. They do NOT accept POST body credentials (`firebase_uid`, `email`, `display_name`).

**Wrong (common mistake in api_service.dart):**
```dart
// ❌ Backend does NOT read POST body for auth
Future<Map<String, dynamic>> register({
  required String firebaseUid,
  required String email,
  String? displayName,
}) async {
  final response = await _dio.post('/api/v1/auth/register', data: {
    'firebase_uid': firebaseUid,
    'email': email,
    'display_name': displayName,
  });
  return response.data;
}
```

**Correct:**
```dart
// ✅ Token is already in Bearer header via Dio interceptor
// After Firebase Auth (Google/Email), just call login
Future<Map<String, dynamic>> login() async {
  final response = await _dio.post('/api/v1/auth/login');
  return response.data;
}
```

**Flow:**
1. Flutter → Firebase Auth (Google Sign-In or Email/Password) → ID Token
2. Store ID Token in SharedPreferences as `auth_token`
3. Dio interceptor adds `Authorization: Bearer <token>` to all requests
4. Call `POST /api/v1/auth/login` — backend verifies token, auto-registers if new
5. Both Google and Email login use the SAME flow — Firebase handles the difference

### Auth works for both Google and Email login
The backend doesn't distinguish between Google and Email/Password login. Both go through Firebase Auth → ID Token → Bearer header. The `login` endpoint auto-registers unknown users.

## Accessing PostgreSQL from Local Machine (pgAdmin)

### Problem
The PostgreSQL container runs in Docker on the VPS but **does not expose port 5432 to the host** — it's only accessible within the `backend_net` Docker network. This means pgAdmin on a local PC cannot connect directly.

### Solution: SSH Tunnel (Recommended)

**Do NOT expose port 5432 publicly** — databases should not be accessible from the internet. Use SSH tunnel instead.

**Step 1 — Open tunnel from local PC (Git Bash / PowerShell):**
```bash
ssh -N -L 15432:postgres:5432 root@202.10.46.161
```
- Use port `15432` (not `5432`) to avoid conflict with local PostgreSQL
- Keep this terminal open while using pgAdmin
- If port 5432 is already in use locally, you'll get `bind [127.0.0.1]:5432: Address already in use` — that's why we use 15432

**Step 2 — pgAdmin connection:**
- Host: `localhost`
- Port: `15432`
- Database: `subtrack`
- Username: `hermes`
- Password: (check on VPS: `docker exec postgres env | grep POSTGRES_PASSWORD`)

### SSH Key Setup for WindowsUsers

**Symptom:** `ssh -N -L 15432:postgres:5432 root@VPS` asks for password repeatedly, or `Permission denied`.

**Cause:** Public key not in VPS `~/.ssh/authorized_keys`, or SSH client not offering the right key.

**Fix — Copy public key to VPS:**

1. On Windows PC, get public key:
```powershell
type C:\Users\user\.ssh\id_rsa.pub
```
Copy the output.

2. SSH into VPS (with password):
```powershell
ssh root@202.10.46.161
```

3. Paste the key:
```bash
mkdir -p ~/.ssh
echo "PASTE_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

4. Alternative — have the agent do it directly if user shares their public key:
```bash
ssh root@VPS "echo 'PUBKEY' >> ~/.ssh/authorized_keys"
```

**Symptom:** `bind [127.0.0.1]:5432: Address already in use`

**Cause:** Local PostgreSQL running on port 5432.

**Fix:** Use a different local port: `-L 15432:postgres:5432` and connect pgAdmin to port `15432`.

**Symptom:** OpenSSH on Windows doesn't support tunneling / connection refused after tunnel.

**Alternative:** Use PuTTY:
1. Session: Host `VPS_IP`, Port `22`
2. Connection → SSH → Tunnels: Source `15432`, Destination `postgres:5432`, click Add
3. Connection → SSH → Auth: Browse to `.ppk` key file (convert `.id_rsa` via PuTTYgen if needed)
4. Open session, keep window open
5. pgAdmin → `localhost:15432`

### SSH Tunnel: End-to-End Checklist (June 2026)

If pgAdmin still shows "Connection refused" after establishing tunnel:
1. Verify tunnel terminal is still running (don't close it)
2. Ensure port `15432` is used (not `5432`) to avoid local PostgreSQL conflict
3. Verify public key is in VPS `~/.ssh/authorized_keys` — SSH must connect without password
4. If key auth fails silently, check: `ssh -v -N -L 15432:postgres:5432 root@VPS` for debug output
5. **Most common cause on Windows:** SSH key not registered → falls back to password → password denied → tunnel never establishes

### SQLAlchemy Relationship Pitfall: backref Conflict
Use `back_populates` on BOTH sides instead of `backref` when both models have relationships to each other.

## Family Vault Payment System

### Billing: Split-Equal (Default — June 2026)
- **No `billing_type` field** — removed. Always split equally.
- **No `share_percentage` billing** — field exists on FamilyMember but not used for billing.
- **Formula**: `amount_per_member = round(subscription.price / member_count)`
- **All members pay the same amount** — no full_price option, no custom percentages.

### payment_info Field
- `FamilyVault.payment_info` (Text, nullable) — bank account / e-wallet info for members
- Example: "Transfer ke BCA 1234567890 a.n. John Doe" or "GoPay 081234567890"
- API: `POST /api/v1/family` and `PUT /api/v1/family/{vault_id}` accept `payment_info`

### Payment Lifecycle
1. Celery Beat (`generate_family_payments`) → 1st of each month
2. Each member gets `FamilyPayment(amount=round(price/count), status=PENDING)`
3. Member uploads proof → `AWAITING_CONFIRM`
4. Owner confirms → `CONFIRMED` / rejects → `PENDING`
5. Proof deleted → reverts to `PENDING`
6. Auto-confirm after 24h (Celery task `auto_confirm_awaiting_payments`)
7. Overdue after 7 days (Celery task `check_overdue_payments`)

### Celery Tasks
| Task | Schedule | Endpoint |
|------|----------|----------|
| `generate_family_payments` | 1st of month | POST `/api/v1/admin/scheduler/trigger-billing` |
| `check_overdue_payments` | Daily | POST `/api/v1/admin/scheduler/trigger-overdue-check` |
| `auto_confirm_awaiting_payments` | Every 6h | Built into task |
| `check_upcoming_billings` | Daily | — |
| `check_trial_expirations` | Daily | — |
| `check_price_increases` | Daily | — |

### Payment Status Flow
```
PENDING → (member uploads proof) → AWAITING_CONFIRM
  AWAITING_CONFIRM → (owner confirms) → CONFIRMED
  AWAITING_CONFIRM → (owner rejects) → PENDING
  AWAITING_CONFIRM → (24h timeout) → CONFIRMED (auto)
  PENDING → (7 days, no action) → OVERDUE
  (proof deleted) → PENDING
```
**Symptom:** Backend fails to start with `sqlalchemy.exc.InvalidRequestError: One or more mappers failed to initialize — can't proceed with initialization of other mappers` and mentions `Error creating backref 'user' on relationship`.

**Cause:** Both sides of a relationship use `backref` for overlapping names. Example:
```python
# user.py
subscriptions = relationship("Subscription", backref="user", ...)

# subscription.py — CONFLICT: also defines backref to "subscriptions"
user = relationship("User", backref="subscriptions")
```

**Fix:** Use `back_populates` on BOTH sides instead of `backref`:
```python
# user.py
subscriptions = relationship("Subscription", back_populates="user", cascade="all, delete-orphan")

# subscription.py
user = relationship("User", back_populates="subscriptions")
```

**Rule of thumb:** If model A has a `relationship()` to model B, and model B has a `relationship()` back to model A, use `back_populates` on both. Only use `back_ref` when one side doesn't need the reverse reference.

### PostgreSQL Password Changes

**Issue:** When the postgres user password is changed on the VPS, the Docker container running the backend still has the OLD password in `.env.production`.

**Symptom:** Backend logs show `psycopg2.OperationalError: connection to server at "postgres" failed: FATAL: password authentication failed for user "hermes"`

**Fix:**
1. Update `.env.production` on VPS: `DATABASE_URL=postgresql://hermes:<NEW_PASSWORD>@postgres:5432/subtrack`
2. Restart backend containers: `docker-compose -f docker-compose.prod.yml restart subtrack-api`
3. If password was baked into Docker image at build time, rebuild: `docker-compose build --no-cache subtrack-api` then restart

| Item | Value |
|------|-------|
| Database | `subtrack` |
| DB User | `hermes` |
| Tables (5) | `users`, `subscriptions`, `family_vaults`, `family_members`, `payments` |
| Backend API URL | `https://api.subtrack.devlokal.id` |
| Health check | `curl https://api.subtrack.devlokal.id/health` |