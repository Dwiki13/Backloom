# Testing Projects Inside Existing Containers

When host Python venv lacks dependencies (e.g., testing gdrive-storage on host which lacks sentry-sdk, asyncpg, aiosqlite), copy code to an existing container that has all deps (like `subtrack-api`) and run tests there.

## Pattern

```bash
# Copy project code to container
cd /root/projects/gdrive-storage/backend
docker cp . subtrack-api:/app/gdrive-storage/

# Run tests inside container
docker exec subtrack-api bash -c "
export PYTHONPATH=/app/gdrive-storage
cd /app/gdrive-storage

# Mock sentry_sdk if not installed in that container
python3 -c \"
import sys, os, types
sys.path.insert(0, os.getcwd())
sentry = types.ModuleType('sentry_sdk')
sentry.init = lambda *a, **k: None
sys.modules['sentry_sdk'] = sentry

os.environ['DATABASE_URL'] = 'sqlite+aiosqlite:///:memory:'
os.environ['REDIS_URL'] = 'redis://localhost:6379/0'
os.environ['SECRET_KEY'] = 'test-secret-key-for-testing-only-1234567890'
os.environ['GOOGLE_CLIENT_ID'] = 'test-google-client-id'
os.environ['GOOGLE_CLIENT_SECRET'] = 'test-google-client-secret'
os.environ['GOOGLE_REDIRECT_URI'] = 'http://localhost:8000/accounts/google/callback'
os.environ['ENCRYPTION_KEY'] = 'dGVzdC1lbmNyeXB0aW9uLWtleS0xMjM0NTY3ODkw'
os.environ['MIDTRANS_SERVER_KEY'] = 'test-midtrans-server-key'
os.environ['MIDTRANS_CLIENT_KEY'] = 'test-midtrans-client-key'
os.environ['MIDTRANS_IS_PRODUCTION'] = 'false'

import pytest
sys.exit(pytest.main(['-xvs', 'tests/test_sync.py::test_sync_account_files_excludes_shared_drives', '--tb=short']))
\"
"
```

## Key Points

1. **Use existing container** — `subtrack-api` has asyncpg, sentry-sdk, aiosqlite already installed
2. **Set PYTHONPATH** — point to the copied project directory
3. **Mock missing imports** — `sentry_sdk` via `types.ModuleType` if container doesn't have it
4. **Use SQLite in-memory** — faster and no PostgreSQL dependency needed for unit tests
5. **Set ALL env vars** — conftest.py reads from pydantic settings, all must be present

## Why This Works

The `subtrack-api` container has a full Python environment with all production dependencies. By copying another project's code there, we can run tests without installing deps on the host or building a separate test container.
