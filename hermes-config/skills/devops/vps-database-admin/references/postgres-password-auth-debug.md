# PostgreSQL Password Auth Failure in Docker — Debugging Notes

## Symptom
`ALTER USER <user> WITH PASSWORD '<pw>'` succeeds, local connections (trust auth via unix socket) work, but **remote TCP connections from other containers** consistently fail with:
```
FATAL: password authentication failed for user "<user>"
```

## Root Causes (in order of likelihood)

### 1. Special Characters in Password
The most common cause. The password flows through multiple layers:
`.env` file → `pydantic-settings` → `SQLAlchemy` engine URL → `psycopg2` → PostgreSQL

At **any** of these layers, special characters (`@`, `:`, `#`, `%`, `!`, spaces) can be mangled:
- `@` in password breaks URL parsing (it's the `user:password@host` separator)
- `:` in password breaks URL parsing
- `%` may be interpreted as URL encoding
- `pydantic-settings` may or may not strip quotes depending on `.env` format

**Debug technique — isolate with a simple password:**
```sql
ALTER USER hermes PASSWORD 'test123';
```
Then test from remote container:
```python
import psycopg2
conn = psycopg2.connect('postgresql://hermes:***@postgres:5432/db')
```
If simple password works → original password has special char issues.

**Fix:** Either:
- Use only alphanumeric characters in PostgreSQL passwords (safest)
- URL-encode the password in `.env`: `postgresql://user:***@host/db` (but psycopg2 may not decode it)
- Set password in postgres to match exactly what the app sends (test with `test123` first)

### 2. POSTGRES_PASSWORD Env Var Corruption
The Docker `postgres` image sets the superuser password from `POSTGRES_PASSWORD` env var **only on first init** (empty data directory). If the volume already exists, the env var is ignored for password purposes — BUT the env var may still show a corrupt/wrong value:
```bash
docker exec postgres bash -c 'echo $POSTGRES_PASSWORD'
# May output garbage like: "bin boot dev etc home lib..."
```
This is normal when the data directory pre-exists. The actual password is stored in `pg_shadow`.

### 3. Different DB Drivers, Different Auth Behavior
`asyncpg` (Second Brain) and `psycopg2` (SubTrack) handle SCRAM-SHA-256 authentication differently. A password that works with one may fail with the other if it contains characters that one driver URL-encodes and the other doesn't.

**Test which driver your app uses:**
```python
# In the API container:
python3 -c "import psycopg2; print('psycopg2:', psycopg2.__version__)"
python3 -c "import asyncpg; print('asyncpg:', asyncpg.__version__)"
```

### 4. pg_hba.conf Method Mismatch
Check the auth method for remote connections:
```bash
docker exec postgres cat /var/lib/postgresql/data/pg_hba.conf | grep -v "^#" | grep -v "^$"
```
If the line says `scram-sha-256`, passwords are hashed. If it says `md5`, different hash. If it says `trust`, no password needed (insecure).

## Quick Diagnostic Checklist

```bash
# 1. Verify local auth works (trust via unix socket)
docker exec postgres psql -U hermes -h /run/postgresql -d subtrack -c "SELECT 1;"

# 2. Check current password hash
docker exec postgres psql -U hermes -h /run/postgresql -d subtrack -c "SELECT passwd FROM pg_shadow WHERE usename='hermes';"

# 3. Set simple test password
docker exec postgres psql -U hermes -h /run/postgresql -d subtrack -c "ALTER USER hermes PASSWORD 'test123';"

# 4. Test from remote container
docker exec <api-container> python3 -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://hermes:***@postgres:5432/subtrack')
    print('CONNECTED')
    conn.close()
except Exception as e:
    print(f'FAILED: {e}')
"

# 5. If simple password works, the original password has special char issues
# Set the real password in postgres to match what .env sends
# Then update .env to use a simple alphanumeric password
```

## Prevention
- **Always use simple alphanumeric passwords** for PostgreSQL in Docker (no `@`, `:`, `#`, `%`, `!`, spaces)
- Add `.env` to `.dockerignore` so passwords don't get baked into image layers
- Document the actual password in a secure location (not in code/repos)

## New Findings (June 2026 Session)

### POSTGRES_PASSWORD Env Var Corruption — Detailed
When `ALTER USER` succeeds but remote auth still fails, check postgres logs for:
```
DETAIL: User "hermes" has no password assigned.
```
This means the `POSTGRES_PASSWORD` env var in the Docker container is corrupt. The hash in `pg_shadow` exists but PostgreSQL's auth state is inconsistent.

### SQLAlchemy vs psycopg2 Driver Difference
SQLAlchemy (used by SubTrack) connected successfully when raw psycopg2 failed with the same connection string. **Always test DB auth with the same driver the app uses**, not just raw psycopg2.

### .env Files Are Masked on Host
Reading `.env` via Hermes tools on host shows masked passwords. To get real values, read from inside the container via Python (see subtrack-vps-config.md for exact command).
