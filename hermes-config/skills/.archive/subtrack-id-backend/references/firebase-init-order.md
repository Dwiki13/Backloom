# Firebase Initialization Order — Lesson Learned (June 2026)

## Problem
FCM push notifications failed with: "The default Firebase app does not exist."

## Root Cause
- `firebase_admin.initialize_app()` was in `app/utils/auth.py` (lazy init)
- `fcm.py` and `fcm_service.py` import `messaging` at module level
- If `fcm.py` is imported before `auth.py` runs `initialize_app()`, FCM calls fail

## Fix
Moved Firebase init to `app/main.py` BEFORE any route imports:

```python
import firebase_admin
from firebase_admin import credentials
from app.config import settings

try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)

# THEN import routes
from app.routes.auth import router as auth_router
```

Removed duplicate `initialize_app()` from `fcm.py` and `fcm_service.py`.

## Key Takeaway
**SDK initialization must happen before any module-level imports of SDK submodules.** Initialize at the application entry point (main.py), not in a utility module.
