# FastAPI Auth Override Testing Pattern

## When to Use
When testing FastAPI endpoints that depend on auth (e.g., Firebase `get_current_user`), and you want to test without real auth tokens.

## The Pattern

### The Problem
```python
# app/utils/auth.py
security = HTTPBearer()  # Requires real Bearer token

async def get_current_user(credentials=Depends(security), db=Depends(get_db)):
    token = credentials.credentials
    decoded = verify_firebase_token(token)  # Connects to Firebase
    ...
```

### The Solution: Dependency Override

```python
# tests/test_endpoints.py
from app.utils.auth import get_current_user
from app.models.user import User

def override_auth(user):
    async def _override():
        return user
    return _override

_auth_user = [None]

def set_auth_user(user):
    _auth_user[0] = user
    app.dependency_overrides[get_current_user] = override_auth(user)

def clear_auth():
    _auth_user[0] = None
    app.dependency_overrides.pop(get_current_user, None)
```

### Two Fixtures Pattern

```python
@pytest_asyncio.fixture
async def client():
    """NO auth client — tests 403 guards."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest_asyncio.fixture
async def auth_client():
    """Auth-enabled client. Call set_auth_user(user) in test body."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

# Usage:
@pytest.mark.asyncio
async def test_owner_only_endpoint(auth_client):
    db = TestingSessionLocal()
    user = create_user(db, tier=UserTier.PRO)
    set_auth_user(user)
    try:
        resp = await auth_client.get("/api/v1/protected")
        assert resp.status_code == 200
    finally:
        clear_auth()
        db.close()
```

## SQLite Gotchas

1. **UUID comparison fails on SQLite**: `Model.id == "string"` errors with `'str' object has no attribute 'hex'`. Fix in route code: use `UUID(data.id)` explicit cast for SQLite compatibility.

2. **`declarative_base()` deprecation warning**: Use `from sqlalchemy.orm import declarative_base` (SQLAlchemy 2.0).

## Key Rules
- Always use `try/finally` with `set_auth_user` + `clear_auth` to prevent leaks between tests
- `autouse=True` fixture handles DB create/drop per test
- Keep `TestingSessionLocal` isolated from production `SessionLocal`
