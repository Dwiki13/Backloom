# Firebase Auth + FastAPI Integration Pattern

Reference implementation from subtrack-id (2026-06-06). For any FastAPI backend using Firebase Authentication.

## Architecture

```
Flutter App → Firebase Auth SDK → ID Token → Backend /api/v1/auth/login
Backend → firebase_admin.auth.verify_id_token() → Firebase UID → User lookup/create
```

## Implementation: app/utils/auth.py

```python
import firebase_admin
from firebase_admin import credentials, auth as firebase_auth
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.config import settings

cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)

security = HTTPBearer()

def verify_firebase_token(token: str) -> dict:
    try:
        return firebase_auth.verify_id_token(token)
    except (
        ValueError,
        firebase_auth.InvalidIdTokenError,
        firebase_auth.ExpiredIdTokenError,
        firebase_auth.RevokedIdTokenError,
        firebase_auth.CertificateFetchError,
    ) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired token: {str(e)}",
        )

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials
    decoded = verify_firebase_token(token)
    firebase_uid = decoded["uid"]

    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
    if not user:
        # Auto-register on first login
        email = decoded.get("email", f"{firebase_uid}@placeholder.local")
        display_name = decoded.get("name") or email.split("@")[0]
        user = User(
            firebase_uid=firebase_uid,
            email=email,
            display_name=display_name,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is deactivated",
        )
    return user
```

## Implementation: app/routes/auth.py

```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.utils.auth import get_current_user, verify_firebase_token, security

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

class UserResponse(BaseModel):
    id: str
    email: str
    display_name: str | None
    tier: str
    class Config:
        from_attributes = True

@router.post("/register", response_model=UserResponse, status_code=201)
async def register(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    decoded = verify_firebase_token(credentials.credentials)
    firebase_uid = decoded["uid"]
    existing = db.query(User).filter(User.firebase_uid == firebase_uid).first()
    if existing:
        raise HTTPException(status_code=409, detail="User already registered")
    email = decoded.get("email", f"{firebase_uid}@placeholder.local")
    display_name = decoded.get("name") or email.split("@")[0]
    user = User(firebase_uid=firebase_uid, email=email, display_name=display_name)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/login", response_model=UserResponse)
async def login(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    decoded = verify_firebase_token(credentials.credentials)
    firebase_uid = decoded["uid"]
    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
    if not user:
        email = decoded.get("email", f"{firebase_uid}@placeholder.local")
        display_name = decoded.get("name") or email.split("@")[0]
        user = User(firebase_uid=firebase_uid, email=email, display_name=display_name)
        db.add(user)
        db.commit()
        db.refresh(user)
    return user

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
```

## Prerequisites

- `firebase-admin` in `requirements.txt`
- Firebase Service Account JSON file placed on server (NOT committed to git)
- Set path in `.env.production`: `FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json`
- Firebase Authentication enabled in Firebase Console (Email, Google, etc.)

## Endpoints Summary

| Endpoint | Auth | Description |
|----------|------|-------------|
| `POST /api/v1/auth/register` | Bearer token | Register new user from Firebase token |
| `POST /api/v1/auth/login` | Bearer token | Login + auto-register if new |
| `GET /api/v1/auth/me` | Bearer token | Get current user profile |
| All other routes | Bearer token | Protected by `get_current_user` dependency |

## Dev Mode Alternative (No Firebase SDK)

For local development without Firebase credentials:

```python
# Replace verify_firebase_token with:
def verify_firebase_token(token: str) -> dict:
    # Dev mode: treat token as firebase_uid directly
    return {"uid": token, "email": f"{token}@dev.local", "name": "Dev User"}
```

Nail the production implementation first, then add dev fallback behind `if settings.DEBUG`.
