# CronCheck Project Reference

> Created: 2026-06-22
> Repo: https://github.com/Dwiki13/croncheck (private)
> Status: Design docs complete (8 files), not yet started coding

## Overview
Dead-simple cron monitoring. Add 1 line to crontab, get instant Telegram alerts.

## Tech Stack
- Backend: FastAPI (Python)
- Database: SQLite (dev) + PostgreSQL (prod)
- Cache/Queue: Redis
- Frontend: htmx + Jinja2
- Bot: python-telegram-bot
- Deploy: Docker + docker-compose

## Project Structure (from DESIGN.md)
```
croncheck/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── celery_app.py
│   │   ├── api/v1/
│   │   │   ├── auth.py
│   │   │   ├── jobs.py
│   │   │   ├── ping.py
│   │   │   ├── notifications.py
│   │   │   └── stats.py
│   │   ├── core/
│   │   │   ├── security.py
│   │   │   ├── rate_limiter.py
│   │   │   └── exceptions.py
│   │   ├── services/
│   │   │   ├── ping_service.py
│   │   │   ├── job_service.py
│   │   │   ├── scheduler.py
│   │   │   ├── notifier.py
│   │   │   ├── smart_detect.py
│   │   │   └── stats_service.py
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── bot/
│   │   └── templates/
│   └── tests/
├── docs/
├── scripts/
├── docker-compose.yml
├── Dockerfile
├── .env.example
└── README.md
```

## Key Design Decisions
- **Ping-based monitoring**: Cron jobs ping via `GET /ping/{token}` — no agent to install
- **Token per job**: 32-byte hex, unique per job, no auth needed for ping
- **Grace period**: Configurable (default 300s) before alerting on missed job
- **Smart detection**: Drift, slow, escalation, recovery
- **Telegram-first**: Bot commands for status, add, pause, resume, delete, stats
- **Self-hosted**: Docker 1-command setup
- **Free tier**: Unlimited monitors, unlimited notifications

## Data Model Highlights
- **users**: id, email, password_hash, plan (free/pro/team), telegram_chat_id, timezone
- **cron_jobs**: id, user_id, name, token (unique), schedule, grace_period, status, last_ping, next_expected, avg_duration_ms, consecutive_failures
- **ping_logs**: id, cron_job_id, status, response_time_ms, error, ip_address, created_at
- **notifications**: id, user_id, type (telegram/email/webhook), config (JSONB)
- **alert_history**: id, cron_job_id, type, message, sent_via, sent_successfully
- **sessions**: id, user_id, token_hash, expires_at, is_revoked

## API Endpoints
- Auth: POST /api/auth/register, /login, /logout, /forgot-password, /reset-password
- Jobs: GET/POST /api/jobs, GET/PUT/DELETE /api/jobs/{id}, POST /api/jobs/{id}/pause|resume
- Jobs: GET /api/jobs/{id}/history, /api/jobs/{id}/stats
- Ping: GET /ping/{token}, POST /ping/{token}, GET /ping/{token}/start|fail|complete
- Notifications: GET/POST /api/notifications, PUT/DELETE /api/notifications/{id}
- Dashboard: GET /api/stats, /api/alerts
- Health: GET /health, /health/detailed

## Sprint Plan Summary
- Week 1 (Day 1-5): Core MVP — Ping, Jobs, Auth, Dashboard
- Week 2 (Day 6-10): Notifications + Bot — Scheduler, Telegram, Smart Detection
- Week 3 (Day 11-15): Testing + Launch — Negative testing, Docker, docs, launch
- Total: ~121.5 hours

## Negative Testing Categories (100+ cases)
1. Ping endpoint failures (15 cases)
2. Missed job detection failures (15 cases)
3. Notification failures (15 cases)
4. Authentication failures (15 cases)
5. Database failures (10 cases)
6. Telegram bot failures (15 cases)
7. Deployment failures (10 cases)
8. Time & scheduling edge cases (15 cases)
9. Data & storage edge cases (10 cases)
10. User behavior edge cases (10 cases)

## Files Created & Pushed (June 22, 2026)
- `DESIGN.md` (1072 lines) — Full design document
- `ARCHITECTURE.md` — System architecture, component details, data flow, security, deployment
- `API_REFERENCE.md` — All endpoints with request/response examples
- `DATABASE_SCHEMA.md` — ERD, table definitions, enums, indexes, migrations, retention
- `FRONTEND_SPEC.md` — Page structure, components, htmx patterns, color palette, responsive
- `SPRINT_PLAN.md` — 3-week sprint plan with daily task breakdown
- `SETUP_GUIDE.md` — Quick start, local dev, Telegram bot setup, production deploy, troubleshooting
- `README.md` — Project overview, features, comparison, tech stack, roadmap

**Commit:** `22e6dc6` — Initial commit: CronCheck design docs

## Next Steps
1. KII reviews design docs
2. KII approves → start coding (Week 1: Core MVP)
3. All code through OpenCode
4. Deploy to VPS when KII asks
