# Gdrive Storage Project Reference

## Project Info
- **Repo**: https://github.com/Dwiki13/gdrive-storage (private)
- **Path**: `/root/projects/gdrive-storage/`
- **Status**: Docs/architecture phase — no code yet
- **Start date**: June 21, 2026

## Stack
- **Frontend**: Next.js 15, Tailwind CSS, shadcn/ui
- **Backend**: FastAPI, PostgreSQL 16, Redis, Celery
- **Auth**: JWT + Google OAuth2
- **Storage**: Google Drive API (per-user OAuth2)
- **Payment**: Midtrans Snap API
- **Style**: Clean & Minimal (white + gray + blue-600 accent)

## Docs Created
- `DESIGN.md` — product overview
- `ARCHITECTURE.md` — system architecture + diagrams
- `API_REFERENCE.md` — all endpoints (request/response)
- `DATABASE_SCHEMA.md` — SQL schema + SQLAlchemy models
- `FRONTEND_SPEC.md` — screen-by-screen spec + component tree
- `SPRINT_PLAN.md` — 8 sprint breakdown
- `SETUP_GUIDE.md` — dev environment setup
- `DESIGN_SYSTEM.md` — color, typography, spacing, components
- `STYLE_GUIDE.md` — Tailwind config, CSS vars, shadcn setup
- `BRAND_GUIDELINES.md` — logo, tone, copywriting, landing page
- `.env.example` — environment template (updated June 22 with VPS config)
- `README.md` — project overview

## .env.example Configuration (June 22, 2026)
Updated to connect to VPS infrastructure (same as SubTrack ID):
- `DATABASE_URL`: `postgresql+asyncpg://hermes:hermespassword@db:5432/gdrive_storage`
- `REDIS_URL`: `redis://redis:6379/0`
- `SECRET_KEY`: generated (32-byte hex)
- `GOOGLE_CLIENT_ID`: filled by KII
- `GOOGLE_CLIENT_SECRET`: filled by KII
- `GOOGLE_REDIRECT_URI`: `https://gdrive.devlokal.id/accounts/google/callback`
- `ENCRYPTION_KEY`: generated (32-byte hex)
- `DOMAIN`: `gdrive.devlokal.id`
- `NEXT_PUBLIC_API_URL`: `https://gdrive.devlokal.id`
- `MIDTRANS_*`: placeholder (fill when ready)
- `SENTRY_DSN`: placeholder (optional)

## Monetization
- **Source code**: Rp 149rb on Lynk (trust-based license)
- **Hosted SaaS**: Free (2 accounts), Lite Rp 29rb (5 accounts), Pro Rp 79rb (15 accounts)

## Sprint Plan
1. Setup + DB + Auth (weeks 1-2)
2. OAuth2 + Connect Drive (weeks 3-4)
3. File Browser + List (weeks 5-6)
4. Upload + Download + Delete (weeks 7-8)
5. Frontend all screens (weeks 9-10)
6. Payment + Billing (weeks 11-12)
7. Testing + Polish (weeks 13-14)
8. Deploy + Docs + Lynk (weeks 15-16)

## Key Design Decisions
- **Split-equal billing only** — no full_price option (same pattern as SubTrack ID)
- **Policy Engine** — most_free_space strategy for upload balancing
- **Refresh tokens encrypted** at rest (AES-256)
- **Tier enforcement** at connect + upload endpoints
- **Activity log** Pro tier only

## Deployment
- Same VPS pattern as SubTrack ID (Docker + NPM + Let's Encrypt)
- Domain: `gdrive.devlokal.id`
- DB: shared PostgreSQL container (`postgres`), new database `gdrive_storage`
- Redis: shared Redis container (`redis`)

## Google OAuth2 Setup
- Client ID/Secret from Google Cloud Console
- Redirect URI: `https://gdrive.devlokal.id/accounts/google/callback`
- KII filled in credentials on June 22, 2026
