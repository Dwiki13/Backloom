# SQLite Test Fixture Isolation

## Problem

When multiple test files each define their own `autouse=True` fixture named `setup_db` with separate SQLite DB files, pytest's fixture resolution causes cross-contamination:

- Tests pass individually but fail when run together
- Error: `sqlite3.OperationalError: attempt to write a readonly database` or `no such table: <table>`
- Root cause: a parent `conftest.py` root fixture with the same name (`setup_db`, `autouse=True`) overrides per-file fixtures, OR SQLite file locks persist between test functions

## Root Cause Analysis

Three failure modes observed:

### 1. Fixture Name Collision
When `conftest.py` in `tests/` root defines `setup_db` with `autouse=True`, it **overrides** same-named fixtures in test files under subdirectories. The root fixture creates/drops `test.db`, while test files' fixtures never execute.

**Symptom:** Tables from the test file's models don't exist in any DB.

### 2. `app.dependency_overrides` Override Order
Module-level `app.dependency_overrides[get_db] = override_get_db` in test files can be overridden by conftest's module-level code depending on import order. Pytest loads conftest root first, then test files — so test file overrides should win, but fixture-level overrides are more reliable.

**Symptom:** `get_db` points to wrong engine; queries hit wrong DB.

### 3. SQLite File Locks After `drop_all`
SQLAlchemy's `Base.metadata.drop_all(bind=engine)` drops tables but doesn't release the SQLite file lock. The next `create_all` on the same file fails with "readonly database."

**Symptom:** Second test function can't create tables; "attempt to write a readonly database."

## Fix Pattern

### Per-test-file setup (apply to each test file that uses its own DB)

```python
# At module level — import order matters
import app.models  # Register all models in Base.metadata
from app.main import app as _fastapi_app
app = _fastapi_app
from app.database import Base, get_db

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_<name>.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(autouse=True)
def setup_db():
    app.dependency_overrides[get_db] = override_get_db  # Re-set per test
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    engine.dispose()  # Release SQLite file locks
```

### Key rules

1. **Each test file uses its own DB file** (`test_endpoints.db`, `test_notifs.db`, `test_proofs.db`) — never share
2. **`engine.dispose()` after `drop_all`** — releases file locks so next test can create_all
3. **Set `app.dependency_overrides[get_db]` inside `setup_db` fixture** — not just at module level — ensures correct override even when multiple test files run in sequence
4. **`import app.models` BEFORE `from app.main import app`** — prevents `app` name shadowing (Python will resolve `app` as the package, not the FastAPI instance)
5. **Don't define `setup_db` in root `conftest.py`** if any test file defines its own — same-name fixtures conflict

### Conftest.py should only contain shared fixtures

```python
# tests/conftest.py — minimal, no setup_db
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
import app.models

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
```

## Debugging Checklist

When tests pass individually but fail together:

1. [ ] Check for `setup_db` name collision between conftest and test files
2. [ ] Verify `app.dependency_overrides[get_db]` points to correct engine (add print in fixture)
3. [ ] Check if `engine.dispose()` is called after `drop_all`
4. [ ] Verify `import app.models` comes before `from app.main import app`
5. [ ] Ensure each test file uses a unique DB filename
6. [ ] Run `rm -rf test*.db test*.db-journal` before test suite to clear stale locks
7. [ ] Check `Base.metadata.tables` contains expected tables (add debug print in fixture)

## Real-World Example

SubTrack ID backend (June 2026): 3 test files (`test_endpoints.py`, `test_notifications.py`, `test_payment_proofs.py`) each with own SQLite DB. After adding `engine.dispose()` and removing conflicting conftest `setup_db`, all 85 tests passed.
