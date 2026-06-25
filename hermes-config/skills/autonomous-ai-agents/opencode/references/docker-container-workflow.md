# Docker Container Workflow — SubTrack ID

## Build & Run Commands

```bash
# Rebuild image after code changes
cd /root/projects/subtrack-id/backend
docker build -t backend_api:latest .

# Recreate container (required — restart alone reuses old image)
docker rm -f subtrack-api
docker run -d --name subtrack-api \
  --network backend_net --network npm_default \
  --env-file .env -p 8002:8000 backend_api:latest
```

## Verify Code is Updated

```bash
# Check file inside container matches host
docker exec subtrack-api cat /app/app/models/payment.py | head -20

# Quick health check
docker exec subtrack-api python3 -c "from app.main import app; print('OK')"

# Run tests inside container
docker exec subtrack-api python3 -m pytest tests/ -v --tb=short
```

## Common Mistake

`docker restart subtrack-api` does NOT pick up code changes — it restarts the same image. Always `docker rm -f` + `docker run` after code changes.

## Test DB Isolation

Tests use SQLite files (`test.db`, `test_notifs.db`, `test_proofs.db`) on the host filesystem. When running tests inside the container, these are at `/app/test*.db`. When running on host, they're at `./test*.db`. Be consistent — run tests either all on host or all in container, not mixed.