# SubTrack ID — Celery + Beat Task Reference

> June 14, 2026. Celery tasks, Beat schedules, and Docker services for SubTrack ID.

## Architecture

```
subtrack-redis (Redis 7 Alpine)
  ↑ broker + backend
subtrack-celery-worker (celery worker)
  ↑ scheduled by
subtrack-celery-beat (celery beat)
```

All three services defined in `docker-compose.yml`, connected via `backend_net`.

## Task List

### 1. generate_family_payments (Monthly)
- **Schedule:** `crontab(day_of_month=1, hour=0, minute=0)` — 1st of each month 00:00 UTC
- **File:** `app/services/family_billing_service.py`
- **Logic:**
  - Query all FamilyVaults
  - For each vault, get all FamilyMembers
  - **Opsi C:** Skip members who joined in the same month as billing period
  - Get owner's subscription price (default 59000 if no subscription)
  - Create FamilyPayment if not exists (idempotent — checks vault_id + member_id + month + year)
- **Idempotent:** Yes — safe to run multiple times

### 2. check_overdue_payments (Daily)
- **Schedule:** `crontab(hour=9, minute=0)` — daily 09:00 UTC
- **File:** `app/services/family_billing_service.py`
- **Logic:**
  - Query FamilyPayment with `status=PENDING` and `created_at < now() - 7 days`
  - Mark as `OVERDUE`
  - Send in-app notification to member via `send_notification` task

### 3. check_upcoming_billings (Daily) — EXISTING
- **Schedule:** `crontab(hour=1, minute=0)`
- **File:** `app/services/scheduler_service.py`
- Subscription billing reminder (3 days before)

### 4. check_trial_expirations (Daily) — EXISTING
- **Schedule:** `crontab(hour=1, minute=0)`
- **File:** `app/services/scheduler_service.py`
- Trial ending notification (2 days before)

### 5. check_price_increases (Daily) — EXISTING
- **Schedule:** `crontab(hour=1, minute=0)`
- **File:** `app/services/scheduler_service.py`
- Price change notification

### 6. send_notification (On-Demand) — EXISTING
- **File:** `app/services/scheduler_service.py`
- FCM push notification via Firebase Admin SDK

## Admin Trigger Endpoints

All under `/api/v1/admin/scheduler/` (require auth):

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/trigger-billing-check` | Manually trigger family payments generation |
| POST | `/trigger-trial-check` | Manually trigger trial expiration check |
| POST | `/trigger-overdue-check` | Manually trigger overdue payments check |
| GET | `/status` | View beat schedule + current time |

## Docker Services

```yaml
redis:
  image: redis:7-alpine
  container_name: subtrack-redis
  networks: [backend_net]
  volumes: [redis_data:/data]

celery_worker:
  build: .
  container_name: subtrack-celery-worker
  command: celery -A app.services.scheduler_service.celery_app worker --loglevel=info
  env_file: .env
  depends_on: [redis]
  networks: [backend_net]

celery_beat:
  build: .
  container_name: subtrack-celery-beat
  command: celery -A app.services.scheduler_service.celery_app beat --loglevel=info
  env_file: .env
  depends_on: [redis]
  networks: [backend_net]
```

## Redis Connection

- URL: `redis://subtrack-redis:6379/0` (Docker network, no auth)
- Configured in `app/config.py` as `REDIS_URL`
- Celery app in `app/services/scheduler_service.py`

## Testing Pattern

Patch `get_session` and call task directly (not via `.delay()`):

```python
@patch('app.services.family_billing_service.get_session')
def test_generate_family_payments(mock_session):
    mock_db = MagicMock()
    mock_session.return_value = mock_db
    # ... setup mocks for query chains ...
    result = generate_family_payments()
    mock_db.commit.assert_called()
```

For tasks with `bind=True` + `self.retry()`, pass `None` as `self` in direct tests.

## Common Pitfalls

1. **Task must be idempotent** — Beat may retry on failure. Always check if record exists before creating.
2. **DB sessions in tasks** — Each task creates its own session via `get_session()`. Never reuse sessions across tasks.
3. **engine.dispose() in tests** — SQLite file locks persist without this. Always call after `drop_all()`.
4. **Redis must be running** — `depends_on` ensures startup order but not readiness. Celery worker retries connection.
5. **Beat timezone** — Celery uses UTC. `crontab(hour=0)` = midnight UTC = 07:00 WIB.
