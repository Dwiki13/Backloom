# Testing Python Backend in Docker Container (When Host Lacks Dependencies)

## When to Use
- Host Python venv is missing heavy dependencies (`sentry_sdk`, `aiosqlite`, `asyncpg`, `psycopg2`)
- `pip install` times out (slow/unstable network on VPS)
- But an existing Docker container (e.g., `subtrack-api`) already has the deps installed

## Workaround

```bash
# Copy project code to container
docker cp . <container>:/<project_path>/.

# Run tests inside container with proper env vars
docker exec <container> bash -c '
export PYTHONPATH=/<project_path>
cd /<project_path>

# Set minimal env vars (match .env.example)
export DATABASE_URL="sqlite+aiosqlite:///:memory:"
export REDIS_URL="redis://localhost:6379/0"
export SECRET_KEY="test-secret-key"
export GOOGLE_CLIENT_ID="test"
export GOOGLE_CLIENT_SECRET="test"
export GOOGLE_REDIRECT_URI="http://localhost:8000/callback"
export ENCRYPTION_KEY="dGVzdC1lbmNyeXB0aW9uLWtleS0xMjM0NTY3ODkw"
export MIDTRANS_SERVER_KEY="test"
export MIDTRANS_CLIENT_KEY="test"
export MIDTRANS_IS_PRODUCTION="false"

# If sentry_sdk not installed, mock it
python3 -c "
import sys, types
sentry = types.ModuleType(\"sentry_sdk\")
sentry.init = lambda *a, **k: None
sys.modules[\"sentry_sdk\"] = sentry

import asyncio
# run your test function directly
from app.tasks.sync import _sync_account_files
# ... test code here
"
'
```

## Key Points
- Use `sqlite+aiosqlite:///:memory:` if PostgreSQL is unreachable from container
- Mock `sentry_sdk` with `types.ModuleType` if Docker image doesn't include it
- Use `PYTHONPATH` to avoid module resolution conflicts (especially when container has another project with same `app` package name)
- For async tests, wrap with `asyncio.run()` at the end
