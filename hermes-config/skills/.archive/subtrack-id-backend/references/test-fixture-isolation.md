# SQLite Test Fixture Isolation (pytest + FastAPI + SQLAlchemy)

## The Problem

When multiple test files each use their own SQLite file + SQLAlchemy engine, running them together causes:
- `attempt to write a readonly database` — SQLite file locked by previous test's engine
- `no such table: X` — tables created in wrong DB because `app.dependency_overrides[get_db]` points elsewhere
- Cross-contamination — `Base.metadata.drop_all()` in one test file drops tables in another's DB

## Root Causes

1. **Module-level `app.dependency_overrides[get_db]`** — conftest root's override wins over test file's (or vice versa depending on import order)
2. **`Base.metadata.drop_all()` doesn't release file handles** — SQLite file stays locked
3. **`import app.models` after `from app.main import app`** — shadows the FastAPI `app` object with the package

## The Fix (3 rules)

### Rule 1: Set `dependency_overrides` INSIDE the fixture, not at module level

```python
# WRONG — conftest root's override may overwrite this at runtime
app.dependency_overrides[get_db] = override_get_db

# RIGHT — set inside setup_db so it runs at fixture resolution time
@pytest.fixture(autouse=True)
def setup_db():
    app.dependency_overrides[get_db] = override_get_db  # <-- here
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
```

### Rule 2: Call `engine.dispose()` after `drop_all()` in teardown

```python
@pytest.fixture(autouse=True)
def setup_db():
    app.dependency_overrides[get_db] = override_get_db
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    engine.dispose()  # <-- releases SQLite file locks
```

Without `dispose()`, the SQLAlchemy connection pool holds file handles open. The next test trying to `create_all` on the same file gets "readonly database".

### Rule 3: Import order matters

```python
# CORRECT — import app.models first (registers all models in Base.metadata)
import app.models
from app.main import app as _fastapi_app
app = _fastapi_app

# WRONG — this shadows the FastAPI app with the package
from app.main import app
import app.models  # now `app` is the package, not the FastAPI instance
```

## Working Pattern (copy-paste template)

```python
import app.models  # Register all models FIRST
from app.main import app as _fastapi_app
app = _fastapi_app
from app.database import Base, get_db
from app.models.user import User, UserTier
# ... other model imports ...

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_mydb.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture(autouse=True)
def setup_db():
    app.dependency_overrides[get_db] = override_get_db
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    engine.dispose()
```

## Do NOT put `autouse=True` fixtures with the same name in conftest.py AND test files

pytest resolves `autouse=True` fixtures by scope. If `conftest.py` has `setup_db` and `test_foo.py` also has `setup_db`, one **silently overrides** the other. Result: the overridden fixture never runs, tables are never created in the test file's DB, and all tests fail with "no such table".

**Solution**: Either:
- Use conftest.py fixtures ONLY (all test files share one DB file) — simple but doesn't work when tests need different DB schemas
- Use per-file fixtures with UNIQUE names — but then conftest.py's `setup_db` still conflicts
- **Best**: Keep conftest.py minimal (just `client` fixture), let each test file own its DB lifecycle

## Import order for test files that use FastAPI app

```python
# 1. Register all SQLAlchemy models first
import app.models

# 2. Import FastAPI app (with alias to avoid shadowing)
from app.main import app as _fastapi_app
app = _fastapi_app

# 3. Import DB and models
from app.database import Base, get_db
from app.models.user import User, UserTier
# ...
```
