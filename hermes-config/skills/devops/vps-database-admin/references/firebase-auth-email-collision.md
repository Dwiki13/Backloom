# FastAPI Auth: Handling Email Collision with Firebase UID

## Problem
When using Firebase Auth with a `users` table that has both `firebase_uid` (unique) and `email` (unique) columns, a user can exist with:
- Same email but different/empty `firebase_uid` (e.g. created via different auth provider)
- Same `firebase_uid` but the email was already taken

This causes `IntegrityError: duplicate key value violates unique constraint "users_email_key"` on login/register.

## Solution Pattern

In **register** endpoint:
```python
# 1. Check firebase_uid first
existing = db.query(User).filter(User.firebase_uid == firebase_uid).first()
if existing:
    raise HTTPException(status_code=409, detail="User already registered")

# 2. Check email collision
email = decoded.get("email", f"{firebase_uid}@placeholder.subtrack.id")
existing_email = db.query(User).filter(User.email == email).first()
if existing_email:
    if not existing_email.firebase_uid:
        existing_email.firebase_uid = firebase_uid
        db.commit()
        db.refresh(existing_email)
    raise HTTPException(status_code=409, detail="User already registered")

# 3. Safe to create
user = User(firebase_uid=firebase_uid, email=email, ...)
```

In **login** endpoint:
```python
user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
if not user:
    email = decoded.get("email", f"{firebase_uid}@placeholder.subtrack.id")
    existing_email = db.query(User).filter(User.email == email).first()
    if existing_email:
        existing_email.firebase_uid = firebase_uid
        db.commit()
        db.refresh(existing_email)
        user = existing_email
    else:
        user = User(firebase_uid=firebase_uid, email=email, ...)
```

## Key Insight
Always check BOTH `firebase_uid` AND `email` uniqueness before insert.
