# SQLite Test Fixture Isolation for FastAPI + SQLAlchemy + pytest

## Problem

When multiple test files each create their own SQLite engine + `Base.metadata.create_all()` + `autouse=True` setup_db fixture, running the full suite fails with:
- `sqlite3.OperationalError: attempt to write a readonly database`
- `no such table: <tname>` — tables from other test files' models don't exist

Root causes:
1. **Module-level `app.dependency_overrides[get_db]` conflicts** — conftest.py root and test files both set this; the last import wins, pointing get_db to the wrong engine
2. **Same-name `autouse=True` fixtures** — pytest resolves `setup_db` from conftest root, NOT from the test file, so the test file's `create_all` never runs
3. **SQLite file locking** — `drop_all` doesn't release file locks; subsequent `create_all` in the next test gets "readonly database"

## Solution Pattern

### 1. Each test file owns its own engine and DB file

```python
# In EACH test file (NOT in conftest.py)
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_<name>.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

# Set override at module level
app.dependency_overrides[get_db] = override_get_db
```

### 2. Import `app.models` BEFORE `from app.main import app`

```python
# CORRECT order:
import app.models  # Registers all models in Base.metadata (MUST be first)
from app.main import app as _fastapi_app
app = _fastapi_app
from app.database import Base, get_db
```

If you do `from app.main import app` first, then `import app.models`, the name `app` becomes the package (not the FastAPI instance) and `app.dependency_overrides` fails with `AttributeError`.

### 3. Override dependency INSIDE the setup_db fixture, not just at module level

```python
@pytest.fixture(autouse=True)
def setup_db():
    # Ensure get_db override points to THIS file's engine
    app.dependency_overrides[get_db] = override_get_db
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    engine.dispose()  # CRITICAL: releases SQLite file locks
```

The `engine.dispose()` call is essential — without it, SQLite file handles persist and subsequent test files get "readonly database" errors.

### 4. Keep conftest.py minimal

```python
# conftest.py — NO setup_db, NO override_get_db
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
import app.models  # Register all models

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
```

### 5. Import models explicitly in each test file

Even though `app.models` is imported at module level, also import individual models explicitly to ensure they're registered in `Base.metadata`:

```python
from app.models.user import User, UserTier
from app.models.family_payment import FamilyPayment, FamilyPaymentStatus
from app.models.notification import Notification  # noqa: F401
```

## Celery Task Testing

For Celery tasks with `bind=True` + `self.retry()`:

```python
@celery_app.task(bind=True, max_retries=3)
def my_task(self):
    db = get_session()
    try:
        # ... do work ...
        db.commit()
    except Exception as e:
        db.rollback()
        raise self.retry(exc=e, countdown=60)
    finally:
        db.close()
```

Test by patching `get_session` and calling the task function directly (not via `.delay()`):

```python
@patch('app.services.my_service.get_session')
def test_my_task(mock_session):
    mock_db = MagicMock()
    mock_session.return_value = mock_db
    # ... setup mock query results ...
    result = my_task()
    mock_db.commit.assert_called()
```

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| `import app.models` after `from app.main import app` | `AttributeError: module 'app' has no attribute 'dependency_overrides'` | Import order: `app.models` first |
| No `engine.dispose()` in teardown | "attempt to write a readonly database" on next test | Add `engine.dispose()` after `drop_all` |
| `setup_db` in conftest.py with same name | Test file's `setup_db` never runs | Keep conftest minimal; each test file owns its fixture |
| Module-level `app.dependency_overrides` only | conftest overrides test file's override | Also set override INSIDE `setup_db` fixture |
| Not importing `app.models` | `no such table: <new_model>` in tests | `import app.models` before app import |
