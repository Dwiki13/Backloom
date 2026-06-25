# FastAPI Auth Duplicate Key Fix

## Error Log Snippet
```
sqlalchemy.exc.IntegrityError: (psycopg2.errors.UniqueViolation) duplicate key value violates unique constraint "users_email_key"
DETAIL:  Key (email)=(dwikinugroho67@gmail.com) already exists.

[SQL: INSERT INTO users (id, firebase_uid, email, display_name, photo_url, tier, is_active, fcm_token, notifications_enabled, created_at, updated_at) VALUES (%(id)s::UUID, %(firebase_uid)s, %(email)s, %(display_name)s, %(photo_url)s, %(tier)s, %(is_active)s, %(fcm_token)s, %(notifications_enabled)s, %(created_at)s, %(updated_at)s)]
[parameters: {'id': UUID('429d901b-f1ef-42b8-85f7-b8c5ea8a2b2b'), 'firebase_uid': 'gsgIRHkzjHe9hxUPrEyfkDTFYHg1', 'email': 'dwikinugroho67@gmail.com', 'display_name': 'Dwiki Nugroho', 'photo_url': None, 'tier': 'FREE', 'is_active': True, 'fcm_token': None, 'notifications_enabled': True, 'created_at': datetime.datetime(2026, 6, 9, 2, 9, 58, 141074), 'updated_at': datetime.datetime(2026, 6, 9, 2, 9, 58, 141077)}]
```

## Root Cause
The `/register` and `/login` endpoints in `app/routes/auth.py` only checked for an existing user by `firebase_uid` before attempting to insert a new user. They did not verify whether the email address already existed in the `users` table with a different (or empty) `firebase_uid`. When a user tried to register or log in with an email that was already associated with another account (or no firebase_uid), the insert would fail on the unique email constraint, causing a 500 Internal Server Error.

## Fix Applied
Modified `/root/projects/subtrack-id/backend/app/routes/auth.py` to:
1. **Register endpoint**: After extracting the email from the Firebase token, check if a user with that email already exists. If yes, raise `409 Conflict` (user already registered) instead of attempting to insert.
2. **Login endpoint**: If no user is found by `firebase_uid`, check if a user exists with the same email. If such a user exists and lacks a `firebase_uid`, link the current `firebase_uid` to that account (update the record) and return the user. If the email user already has a different `firebase_uid`, treat as conflict (raise 409) to avoid overriding existing associations.

### Key Changes
- Added email‑existence check before insert in both endpoints.
- When linking an existing email account, update its `firebase_uid` and commit.
- Preserve existing behavior for truly new emails.

### Code Diff (simplified)
```diff
@@
     existing = db.query(User).filter(User.firebase_uid == firebase_uid).first()
     if existing:
         raise HTTPException(status_code=409, detail="User already registered")
 
     email = decoded.get("email", f"{firebase_uid}@placeholder.subtrack.id")
+    # Check if email already exists with different firebase_uid
+    existing_email = db.query(User).filter(User.email == email).first()
+    if existing_email:
+        # Link firebase_uid to existing account
+        if not existing_email.firebase_uid:
+            existing_email.firebase_uid = firebase_uid
+            db.commit()
+            db.refresh(existing_email)
+        raise HTTPException(status_code=409, detail="User already registered")
 
     display_name = decoded.get("name") or email.split("@")[0]
     user = User(
```
*(See the full file for context.)*

## Verification
- Registering a new user with a fresh email succeeds (201).
- Logging in with a known Firebase UID returns the existing user (200).
- Attempting to register with an email that already exists (regardless of firebase_uid) returns `409 Conflict` instead of 500.
- No `UniqueViolation` errors appear in the API logs after the fix.

## References
- Commit `9f51123 fix: handle email collision in register/login` in the SubTrack repository.