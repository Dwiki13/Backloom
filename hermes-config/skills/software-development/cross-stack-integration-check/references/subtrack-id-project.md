# SubTrack ID — Project-Specific Patterns

## Tech Stack
- **Backend:** FastAPI (Python 3.11) at `/root/projects/subtrack-id/backend`
- **Frontend:** Flutter/Dart at `/root/projects/subtrack-id/mobile`
- **Database:** PostgreSQL 16 + Redis 7 + Celery (Docker containers)
- **Domain:** `api.subtrack.devlokal.id` (HTTPS via Nginx Proxy Manager)

## Docker Workflow
- Container `subtrack-api` runs backend on port 8002 (host-mapped)
- After ANY Python file edit: `docker cp <file> subtrack-api:/app/<path> && docker restart subtrack-api`
- Alternative: `docker-compose up -d --build api` (cleaner but slower)
- Alembic head must be verified before feature work: `docker exec subtrack-api alembic current`

## NPM (Nginx Proxy Manager) Coexistence
- Port 80/443 are handled by NPM container (`npm_npm_1`) with `network_mode: host`
- DO NOT install standalone Nginx — it will conflict on port 80
- To add a new domain: use NPM UI (port 81) → Proxy Host → add domain → forward to container IP (not hostname)
- SSL: Add cert to `/etc/letsencrypt/live/npm-N/` and write nginx server block manually if NPM UI is inaccessible
- Let's Encrypt certs: check `openssl x509 -in .../cert.pem -noout -subject` to find which cert-ID maps to which domain
- Container name in `forward_host` must be an IP, not hostname (NPM doesn't resolve Docker hostnames across networks)
- **When NPM UI inaccessible:** write nginx config manually to `/etc/nginx/conf.d/<domain>.conf`, then `nginx -s reload`
- **Cloudflare SSL mode:** Must be **Full** (not Flexible) when origin has valid Let's Encrypt cert
- **Subdomain DNS:** Use CNAME with grey cloud (DNS-only, no proxy) for Let's Encrypt HTTP-01 challenge
- See `references/ssl-origin-setup-for-new-domains.md` in `vps-database-admin` skill for the SSL server block template

### Known SSL Certs
| Domain | Cert Folder | Cert ID | Expires |
|--------|-------------|---------|---------|
| `devlokal.id` / `www.devlokal.id` | `/root/npm/letsencrypt/live/npm-1/` | npm-1 | check |
| `api.subtrack.devlokal.id` | `/root/npm/letsencrypt/live/npm-10/` | npm-10 | 2026-09-08 |
| `secondbrain.devlokal.id` | `/root/npm/letsencrypt/live/npm-N/` | npm-N | check |

### Proxy Host Config (Database)
| Domain | forward_host | forward_port | certificate_id | ssl_forced |
|--------|-------------|-------------|----------------|------------|
| `devlokal.id` | 172.17.0.3 | 80 | 1 | 0 |
| `www.devlokal.id` | 172.17.0.3 | 80 | 1 | 0 |
| `api.subtrack.devlokal.id` | 172.18.0.5 | 8000 | 10 | 0 |
| `secondbrain.devlokal.id` | 172.17.0.3 | 8001 | N | 0 |

## Backend Route Patterns
- All family endpoints: `/api/v1/family/...`
- All subscription endpoints: `/api/v1/subscriptions/...`
- Auth: `/api/v1/auth/...`
- Admin scheduler: `/api/v1/admin/scheduler/...`
- Notifications: `/api/v1/notifications/...`

## Frontend API Patterns
- All API calls centralized in `lib/services/api_service.dart`
- Models in `lib/models/*.dart`
- Providers in `lib/providers/*.dart`
- Screens in `lib/screens/**/*.dart`

## Known Conventions
- Backend `DOMAIN` config in `app/config.py` — must match production domain for proof URLs
- Flutter `FamilyPayment` model uses camelCase in fromJson but backend returns snake_case (auto-converted)
- `share_percentage` exists on `FamilyMember` model but is NOT used for billing — billing is always split-equal
- `payment_info` on `FamilyVault` is free-text field for owner to specify bank account / e-wallet info

## Integration Check History
- 2026-06-19 v1: 5 critical, 11 mismatch, 3 unused → 41 ok
- 2026-06-19 v2: 0 critical, 4 mismatch, 3 unused → 41 ok (KII fixed Flutter models)
- 2026-06-19 v3: 0 critical, 0 mismatch, 2 unused (admin/webhook only) → 42 ok ✅
- 2026-06-25 v4: 0 critical, 0 mismatch, 2 unused → 44 ok ✅ (after auth profile + payment cancel/downgrade)
- 2026-06-25 v5: 0 critical, 0 mismatch, 2 unused → 44 ok ✅ (after first_payment_month type fix)
