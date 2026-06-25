# SubTrack VPS Configuration Reference

## Domain & DNS
- **Domain**: `api.subtrack.devlokal.id`
- **DNS**: Cloudflare (nameservers: `maeve.ns.cloudflare.com`, `christian.ns.cloudflare.com`)
- **A record**: `api.subtrack` → `202.10.46.161` (DNS only / grey cloud, NOT proxied)
- **Flutter env.dart**: `https://api.subtrack.devlokal.id`

## Docker Containers (Full VPS Inventory)
| Container | Image | Internal Port | Host Port | Docker Network | Project |
|-----------|-------|---------------|-----------|----------------|---------|
| subtrack-api | backend_subtrack-api | 8000 | 8002 | backend_net, npm_default | subtrack-id |
| secondbrain-api | secondbrain_secondbrain-api | 8000 | 8001 | backend_net | secondbrain |
| npm_npm_1 | jc21/nginx-proxy-manager:latest | 80, 81, 443 | 80, 81, 443 | npm_default | shared infra |
| postgres | postgres:16 | 5432 | 5432 | backend_net | shared infra |
| secondbrain-db | pgvector/pgvector:pg16 | 5432 | 5433 | backend_net | secondbrain |
| redis | redis:7 | 6379 | 6379 | backend_net | shared infra |
| devlokal | nginx:alpine | 80 | 8080 | — | devlokal-id |
| pgadmin | dpage/pgadmin4 | 80 | 5050 | pgadmin_default | shared infra |
| portainer | portainer/portainer-ce | 8000, 9000 | 8000, 9000 | — | shared infra |

## Shared Database Users
| User | Password | Databases |
|------|----------|-----------|
| hermes | hermes_db_2026 | subtrack, gdrive_storage |
| secondbrain | <set via .env> | secondbrain |

⚠️ **Multi-Project Port Conflicts**: When deploying a new project (e.g., gdrive-storage), ensure its host-mapped ports don't conflict with existing containers. gdrive-storage uses port **8003** for its API container to avoid clashing with subtrack (8002) and secondbrain (8001).

⚠️ **Shared NPM**: All projects behind `*.devlokal.id` domains depend on the same NPM container. If NPM goes down, ALL sites go down simultaneously. Always check `docker ps | grep npm` first when multiple sites are unreachable.

## NPM Proxy Host Config
- **Domain**: `api.subtrack.devlokal.id`
- **Forward to**: `subtrack-api` (container name, shared network `npm_default`)
- **Forward port**: `8000` (container-internal port, NOT the host-mapped 8002)
- **SSL**: Let's Encrypt cert at `/etc/letsencrypt/live/npm-10/`
- **Config file**: `/data/nginx/proxy_host/3.conf`

## Key Pitfall: Container Port vs Host Port
The container exposes port 8000 internally, mapped to host port 8002. When NPM (also a container) connects to `subtrack-api`, it uses the **internal** port 8000. Using host port 8002 in NPM config causes `connect() failed (111: Connection refused)`.

**This fix is LOST when the NPM container is recreated.** Always verify after any NPM container change:
```bash
docker exec npm_npm_1 cat /data/nginx/proxy_host/3.conf | grep "set \$port"
```

## Fixing NPM Config Without UI
```bash
# Edit port in config:
docker exec npm_npm_1 sed -i 's/set $port           8002;/set $port           8000;/' /data/nginx/proxy_host/3.conf

# Validate and reload:
docker exec npm_npm_1 nginx -t
docker exec npm_npm_1 nginx -s reload
```

## Testing from Client
```powershell
# PowerShell (use curl.exe, not curl):
curl.exe -I https://api.subtrack.devlokal.id

# Expected: 403 or 401 (means API is reachable)
# 502 = NPM can't reach upstream (check port/config)
# 000 = DNS issue (check A record, flushdns)
```

## PostgreSQL Access from pgAdmin Desktop (PC)
When KII wants to connect pgAdmin4 desktop on their PC directly to the VPS PostgreSQL:
- **Host**: `202.10.46.161`
- **Port**: `5432`
- **Database**: `subtrack` (or `hermesdb` for the shared Hermes DB)
- **Username**: `hermes`
- **Password**: `hermes_db_2026`
- **Firewall**: port 5432 is open on VPS (`ufw allow 5432`)
- **Auth**: `scram-sha-256` (set via `ALTER USER hermes WITH PASSWORD 'hermes_db_2026'`)

If connection fails from PC, test with: `Test-NetConnection -ComputerName 202.10.46.161 -Port 5432`

## ⚠️ API Returns 500 on All Endpoints: PostgreSQL Password Mismatch

### Symptoms
- All API endpoints return 500 (not 403/401)
- Network is fine (DNS resolves, ping works, NPM config correct)
- API container is up (`docker ps` shows `subtrack-api Up`)
- API logs show: `password authentication failed for user "hermes"`

### Root Cause
The `.env.production` file on the host has a password that doesn't match the actual PostgreSQL password. The container reads this file via volume mount, so the API always uses the wrong password.

### Diagnosis
```bash
# 1. Check API logs for DB auth errors:
docker logs subtrack-api --tail 50 | grep -i "password authentication failed"

# 2. Test DB connection from within the API container:
docker exec subtrack-api python3 -c "
import psycopg2
for pwd in ['hermespassword', 'Hermes123!', 'hermes', 'hermes_db_2026']:
    try:
        conn = psycopg2.connect(f'postgresql://hermes:***@postgres:5432/subtrack')
        print(f'Password \"{pwd}\" → Connected!')
        conn.close()
        break
    except:
        print(f'Password \"{pwd}\" → Failed')
"

# 3. Check what password is in the mounted .env:
docker exec subtrack-api cat /app/.env.production | grep DATABASE
```

### Fix
```bash
# 1. Update the .env.production file on the HOST (not inside container — it's read-only mounted):
# Edit /root/projects/subtrack-id/backend/.env.production

# 2. Remove old container and recreate (volume mount reads the updated file):
docker rm -f subtrack-api
cd /root/projects/subtrack-id/backend
docker-compose -f docker-compose.prod.yml up -d subtrack-api

# 3. Verify:
sleep 5
docker logs subtrack-api --tail 10
# Should show: "Application startup complete" with no DB errors
```

### ⚠️ .env.production Read-Only Mount
The `.env.production` file is mounted into the container as **read-only** (`:ro`). You CANNOT edit it from inside the container:
```
OSError: [Errno 30] Read-only file system: '/app/.env.production'
```

**Always edit the file on the HOST** at `/root/projects/subtrack-id/backend/.env.production`, then recreate the container.

**Sed gotcha:** Special chars in passwords (`@`, `%`, `*`) break sed replacement patterns. Use Python instead:
```bash
python3 -c "
data = open('/root/projects/subtrack-id/backend/.env.production').read()
new_data = data.replace('OLD_PASSWORD', 'NEW_PASSWORD')
open('/root/projects/subtrack-id/backend/.env.production', 'w').write(new_data)
"
```

### ⚠️ Special Characters in DATABASE_URL Password (`@`, `!`, `#`, `%`)

**Problem:** Passwords containing `@`, `!`, `#`, `%`, or other URL-special characters break PostgreSQL connection strings. psycopg2 and SQLAlchemy do NOT auto-URL-decode the password portion of `DATABASE_URL`.

**Symptoms:**
- `password authentication failed` even though the password is "correct"
- URL-encoded password (e.g., `hermes_db_2026%21%40%23`) still fails — psycopg2 sends the literal encoded string as the password
- `sed` replacement patterns break because `@` and `%` are regex/shell metacharacters
- Double `@` in URL (e.g., `hermes:***@#@postgres`) causes parse errors

**Root cause:** In `postgresql://user:***@host:port/db`, the first `@` in the password is interpreted as the separator between credentials and host. URL-encoding (`%40`) is NOT decoded by psycopg2.

**Fix — Use a password without URL-special characters:**
```bash
# Good: no @, !, #, %, :, /, ?, &
ALTER USER hermes WITH PASSWORD 'hermes_db_2026';

# Bad: contains @ which breaks URL parsing
ALTER USER hermes WITH PASSWORD 'hermes_db_2026!@#';
```

**If you MUST use special chars**, use SQLAlchemy's `URL.create()` builder in code instead of a raw URL string — but this requires code changes. Simpler: just avoid `@!#%:` in DB passwords.

**Editing `.env.production` with special chars — use Python, not sed:**
```bash
python3 -c "
data = open('/root/projects/subtrack-id/backend/.env.production').read()
data = data.replace('OLD_PASS', 'NEW_PASS')
open('/root/projects/subtrack-id/backend/.env.production', 'w').write(data)
"
```

### ⚠️ docker-compose `KeyError: 'ContainerConfig'` Bug
Old docker-compose versions (e.g., 1.29.2) may fail with `KeyError: 'ContainerConfig'` when recreating containers with certain volume mount configs.

**Workaround:**
```bash
# Remove the old container FIRST, then recreate:
docker rm -f subtrack-api
cd /root/projects/subtrack-id/backend
docker-compose -f docker-compose.prod.yml up -d subtrack-api
```

If that still fails, create the container manually:
```bash
docker create --name subtrack-api \
  --network backend_net --network npm_default \
  -e "DATABASE_URL=postgresql://hermes:***@postgres:5432/subtrack" \
  -e "REDIS_URL=redis://redis:6379/1" \
  -e "FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json" \
  -e "APP_NAME=SubTrack ID" -e "APP_VERSION=1.0.0" -e "DEBUG=false" \
  -v /root/projects/subtrack-id/backend/.env.production:/app/.env.production:ro \
  -v /root/projects/subtrack-id/backend/firebase-credentials.json:/app/firebase-credentials.json:ro \
  --restart unless-stopped \
  backend_subtrack-api \
  uvicorn app.main:app --host 0.0.0.0 --port 8000

docker start subtrack-api
```

### ⚠️ Password Baked into Docker Image Layers
When `Dockerfile` contains `COPY . .` and `.env.production` is in the build context, the password gets **baked into the image layers** at build time. Even with `env_file:` in docker-compose, the baked-in values can override the volume-mounted file.

**Symptoms:**
- `.env.production` on host has the correct password
- `docker exec <container> cat /app/.env.production` shows the correct password
- BUT `docker exec <container> python3 -c "import os; print(os.environ['DATABASE_URL'])"` shows the OLD password

**Fix options (pick one):**
1. **Rebuild the image** with the correct `.env.production`: `docker-compose build --no-cache subtrack-api`
2. **Set password in PostgreSQL to match the baked-in value** (quick fix)
3. **Override with `docker run -e`** or `environment:` in docker-compose

**Prevention:** Add `.env.production` to `.dockerignore` so it's never baked into the image.

### ⚠️ Password Change Gets Lost After Container Recreate
When you `ALTER USER hermes WITH PASSWORD '...'` from the host, the password change takes effect immediately. BUT if the `.env.production` file on the host still has the OLD password, recreating the container will revert to using the old password.

**Always update `.env.production` on the host BEFORE recreating the container.**

### Verification After Fix
```bash
# From VPS:
curl -s -o /dev/null -w "%{http_code}" -k https://api.subtrack.devlokal.id/api/v1/subscriptions
# Expected: 403 (Not authenticated) — means API + DB are working

# From client PowerShell:
curl.exe -I https://api.subtrack.devlokal.id
# Expected: 403 or 401
```

## Indonesian ISP DNS Intercept
Some Indonesian ISPs perform DNS hijacking — they return NXDOMAIN for ANY domain query regardless of whether the record exists at the authoritative NS. Telltale signs:
- `nslookup domain.com` → NXDOMAIN on Google (8.8.8.8), Cloudflare (1.1.1.1), AND OpenDNS simultaneously
- `dig @1.1.1.1 domain.com` → NXDOMAIN while the record clearly exists on Cloudflare dashboard
- **This is NOT a propagation delay.** The ISP is lying.

**Diagnosis:** Check from a different network/VPN, or query Cloudflare's API directly.

**Fix:** Hosts file override works every time:
- **Windows**: `C:\Windows\System32\drivers\etc\hosts` (open as Admin)
- Add: `202.10.46.161 api.subtrack.devlokal.id`
- Flush: `ipconfig /flushdns`

## Testing API via Postman/Insomnia

### Base URL
- **Production (HTTPS via domain)**: `https://api.subtrack.devlokal.id`
- **Direct (HTTP via IP)**: `http://202.10.46.161:8002`
- **Health check**: `GET /health` → expect 200, no auth needed

### Auth Flow (Required for All API Calls)
```jsonc
// 1. Register: POST /api/v1/auth/register
{
  "email": "test@example.com",
  "password": "test123",
  "name": "Test User"
}

// 2. Login: POST /api/v1/auth/login
{
  "email": "test@example.com",
  "password": "test123"
}
// Response includes: { "access_token": "...", "token_type": "bearer" }

// 3. Use token in subsequent requests:
// Header: Authorization: Bearer <access_token>
```

### Endpoints
| Method | Endpoint | Auth Needed |
|--------|----------|-------------|
| GET | `/health` | No |
| POST | `/api/v1/auth/register` | No |
| POST | `/api/v1/auth/login` | No |
| GET | `/api/v1/submissions` | Yes (Bearer) |
| POST | `/api/v1/subscriptions` | Yes (Bearer) |
| GET | `/api/v1/notifications` | Yes (Bearer) |
| POST | `/api/v1/payments` | Yes (Bearer) |
| POST | `/api/v1/detect` | Yes (Bearer) |
| GET | `/api/v1/family` | Yes (Bearer) |
| GET | `/api/v1/admin/scheduler` | Yes (Bearer) |

**403 on any endpoint with no token** = API + DB are working correctly.
**500 on all endpoints** = Check DB password mismatch first (see above).

### Read-Only File Gotcha
`read_file` returns a "secret-bearing" error for `.env.production`. Always use `cat` via terminal to read it:
```bash
cat /root/projects/subtrack-id/backend/.env.production
```

## End-to-End Debugging Checklist

When API returns 500/502/404 from client:

1. **DNS**: `nslookup api.subtrack.devlokal.id` → should resolve to `202.10.46.161`
2. **Ping**: `ping api.subtrack.devlokal.id` → should get replies
3. **NPM config**: `docker exec npm_npm_1 cat /data/nginx/proxy_host/3.conf | grep -E "set \$port|set \$server"` → port should be 8000, server should be "subtrack-api"
4. **NPM→API connectivity**: `docker exec npm_npm_1 curl -s -o /dev/null -w "%{http_code}" http://subtrack-api:8000/` → should be 404 or 403
5. **API container health**: `docker logs subtrack-api --tail 20` → should show "Application startup complete"
6. **Route count**: `docker exec subtrack-api python3 -c "from app.main import app; print(len(app.routes))"` → should be 29+, not 5
7. **DB connectivity**: `docker logs subtrack-api --tail 50 | grep -i "password authentication failed"` → should be empty
8. **From VPS via HTTPS**: `curl -s -k https://api.subtrack.devlokal.id/api/v1/subscriptions` → should be 403
9. **Cloudflare proxy**: Check if A record is DNS only (grey cloud). Proxied mode breaks origin SSL.
10. **From client**: `curl.exe -I https://api.subtrack.devlokal.id` → should be 403 or 401

---

## ⚠️ API Returns 404 on All Routes (But /health Works) — Silent Import Failure Cascade

### Symptoms
- `/health` returns 200 OK
- All other routes (`/api/v1/subscriptions`, `/api/v1/auth`, etc.) return 404
- API container is up, no errors in logs
- DB connection is fine (no auth errors)
- Route count check shows only 5 routes (just /health, /docs, /redoc, /openapi.json, /docs/oauth2-redirect)

### Root Cause
One `ModuleNotFoundError` in `main.py` imports silently kills ALL subsequent `include_router` calls. FastAPI does NOT always surface these errors clearly in logs.

**Common triggers:**
- Missing `services/` or `utils/` folders in Docker image (build cache issue — old image doesn't include all source folders)
- Missing Python module that a route file imports (e.g., `app.services.fcm_service`)
- Circular import between route files

### Diagnosis
```bash
# 1. Check how many routes are actually registered:
docker exec subtrack-api python3 -c "
import sys; sys.path.insert(0, '/app')
from app.main import app
print('Total routes:', len(app.routes))
for r in app.routes:
    if hasattr(r, 'path'):
        print(f'  {r.path}')
"
# If you see only 5 routes, include_router calls are failing silently.

# 2. Test imports one by one to find the breaking point:
docker exec subtrack-api python3 -c "
import sys; sys.path.insert(0, '/app')
from app.routes.auth import router as r1; print('auth OK')
from app.routes.subscriptions import router as r2; print('subscriptions OK')
from app.routes.family import router as r3; print('family OK')
from app.routes.payments import router as r4; print('payments OK')
from app.routes.detector import router as r5; print('detector OK')
from app.routes.notifications import router as r6; print('notifications OK')
from app.routes.scheduler_admin import router as r7; print('scheduler_admin OK')
"
# The first import that fails is the culprit.

# 3. Check if services/utils folders exist in container:
docker exec subtrack-api ls -la /app/app/services/ /app/app/utils/
# If these folders are missing, it's a Docker build cache issue.
```

### Fix: Rebuild Docker Image Without Cache
```bash
cd /root/projects/subtrack-id/backend

# Remove old container first (docker-compose can't recreate with same name):
docker rm -f subtrack-api

# Rebuild without cache:
docker-compose -f docker-compose.prod.yml build --no-cache subtrack-api

# Start new container:
docker-compose -f docker-compose.prod.yml up -d subtrack-api

# Verify routes:
sleep 5
docker exec subtrack-api python3 -c "
import sys; sys.path.insert(0, '/app')
from app.main import app
print('Total routes:', len(app.routes))
"
# Should show 29+ routes, not 5.
```

### Prevention
- Add `.env.production` to `.dockerignore` so it's never baked into image layers
- After any code change that adds new folders, always rebuild without cache
- Verify route count after every deployment

---

## ⚠️ Docker Build Cache: Missing Folders in Image

### Symptoms
- `ModuleNotFoundError` for modules that exist on the host
- `services/`, `utils/`, or other folders missing inside container
- Code works on host but not in container

### Root Cause
Docker build cache serves an old image layer that doesn't include recently added folders. `COPY . .` in Dockerfile only picks up changes if the build context has changed — but Docker may cache the entire layer.

### Diagnosis
```bash
# Compare host vs container file listing:
ls -la /root/projects/subtrack-id/backend/app/          # on host
docker exec subtrack-api ls -la /app/app/               # in container
```

### Fix
```bash
# Always use --no-cache when rebuilding after adding new folders:
docker-compose -f docker-compose.prod.yml build --no-cache subtrack-api

# Then recreate:
docker rm -f subtrack-api
docker-compose -f docker-compose.prod.yml up -d subtrack-api
```

### ⚠️ docker-compose v1 vs v2 Command Syntax
This server uses docker-compose v1 (with dash). Commands differ:
```bash
# v1 (this server):
docker-compose -f docker-compose.prod.yml up -d subtrack-api
docker-compose -f docker-compose.prod.yml build --no-cache subtrack-api

# v2 (not available here):
docker compose -f docker-compose.prod.yml up -d subtrack-api
```

### ⚠️ Container Name Conflict on Recreate
`docker-compose up -d --build` fails with "Conflict. The container name is already in use" when the old container still exists.

**Fix:**
```bash
# Always remove old container first:
docker rm -f subtrack-api
docker-compose -f docker-compose.prod.yml up -d subtrack-api
```

### ⚠️ `KeyError: 'ContainerConfig'` on `docker-compose up -d --build`
Old docker-compose v1 (1.29.2) may fail with `KeyError: 'ContainerConfig'` when recreating containers, even after `docker rm -f`. This happens when orphan volumes or networks reference the old container.

**Fix — use `docker-compose down` first:**
```bash
cd /root/projects/subtrack-id/backend
docker-compose down  # removes containers + cleans up
docker-compose up -d --build
```

If `docker-compose down` reports "Found orphan containers", add `--remove-orphans`:
```bash
docker-compose down --remove-orphans
docker-compose up -d --build
```

**Note:** `docker-compose down` only removes containers defined in the compose file — it does NOT remove external networks or volumes.

---

## ⚠️ Monorepo Git Workflow: `backend/` is a Subdirectory

The SubTrack project is a monorepo where `backend/` is a subdirectory of `/root/projects/subtrack-id/`, NOT a standalone repo. Both share the same git root.

**Implication:** Files outside `backend/` (like `docs/plans/`) live in the parent repo. Running `git add` from inside `backend/` with relative paths will fail for these files.

**Correct approach for repo-wide commits:**
```bash
# From the REPO ROOT (not from backend/):
cd /root/projects/subtrack-id
git add backend/app/routes/detector.py backend/app/models/user.py docs/plans/new-doc.md
git commit -m "feat: ..."
git push
```

**Git pull/rebase after remote has new commits:**
```bash
cd /root/projects/subtrack-id/backend   # any subdirectory works for pull
git pull --rebase origin main
```

**Pitfall:** If `git stash pop` results in `CONFLICT (add/add)` on files that exist on both local and remote (e.g., `docs/plans/`), resolve with:
```bash
git checkout --ours docs/plans/conflicting-file.md   # keep local version
git add docs/plans/conflicting-file.md
git stash drop
git push
```

**Deploy command (run from VPS):**
```bash
ssh -i ~/.ssh/subtrack_deploy root@202.10.46.161 "cd /root/projects/subtrack-id && git pull --rebase origin main && docker compose -f backend/docker-compose.prod.yml down subtrack-api && docker compose -f backend/docker-compose.prod.yml up -d --build subtrack-api"
```

**Always rebuild after model changes:** Adding new columns (like `ocr_detect_count`) requires a DB migration or manual `ALTER TABLE` since there's no Alembic setup yet. For quick fixes on existing data:
```bash
docker exec postgres psql -U hermes -d subtrack -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS ocr_detect_count INTEGER DEFAULT 0 NOT NULL;"
```

---

## Second Brain Project — Known Issues

### DELETE /api/items/{id} Returns 500
**Symptom:** `DELETE /api/items/{id}` returns 500.
**Root cause:** `delete_item()` in `api/db.py` casts `user_id` to `::int` but `items.user_id` is `varchar(64)` (stores WhatsApp ID).
**Error:** `asyncpg.exceptions.DataError: invalid input for query argument $1: '1' ('str' object cannot be interpreted as an integer)`
**Fix:** Change `WHERE id = $1::int` to `WHERE wa_id = $1` in the UPDATE query.

### Firebase Admin SDK — Cross-Process Token Creation
`create_custom_token()` requires Firebase app to be initialized in the **same process**. It does NOT persist across `docker exec` calls. Each `docker exec` starts a fresh Python process. To generate tokens for testing, run the token creation and API call in the same script/process.
