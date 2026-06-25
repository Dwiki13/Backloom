# pgAdmin Server Registration — Correct Approach

## ⚠️ DO NOT Inject Encrypted Passwords from Outside pgAdmin

**This file previously described a technique to manually AES-CFB8 encrypt passwords and SQL-insert them into pgAdmin's database. THIS DOES NOT WORK.**

Even with the correct SECRET_KEY, correct algorithm (AES-CFB8), and passing local roundtrip tests, pgAdmin's running process **cannot decrypt externally-encrypted passwords**. Error at connect time:

```
ERROR: Could not connect to server(#100) - 'SubTrack DB'.
Error: Failed to decrypt the saved password.
Error: 'utf-8' codec can't decode byte 0xaf in position 1: invalid start byte
```

**Root cause:** pgAdmin's encryption/decryption has additional internal state or encoding handling that can't be replicated from a standalone Python script, even using the same `cryptography` library and algorithm.

## The Only Reliable Method: Register via pgAdmin Web UI

1. **Delete the broken server entry** (if it exists) from SQLite:
   ```bash
   docker exec pgadmin /venv/bin/python3 -c "
   import sqlite3
   db = sqlite3.connect('/var/lib/pgadmin/pgadmin4.db')
   c = db.cursor()
   c.execute('DELETE FROM server WHERE id=<broken_id>')
   db.commit(); db.close()
   "
   ```

2. **Have the user register via pgAdmin web UI:**
   - Open `http://<vps-ip>:5050` in browser
   - Right-click **Servers** → **Register** → **Server**
   - **General** tab: Set name (e.g. `SubTrack DB`)
   - **Connection** tab:
     - Host: Docker container name (e.g. `postgres`) — NOT `localhost`
     - Port: `5432`
     - Maintenance DB: `postgres` (or target DB)
     - Username / Password: actual PostgreSQL credentials
     - ✅ Check **Save Password**
   - Click **Save**

3. pgAdmin encrypts and stores the password internally — guaranteed to work.

## Why Docker Container Name as Host?

pgAdmin runs inside a Docker container. When it connects to PostgreSQL:
- It resolves the hostname within the Docker network
- `postgres` (container name) → internal Docker IP (e.g. `172.21.0.2`)
- `localhost` or `127.0.0.1` → the pgAdmin container itself (nothing listening on 5432)

Both containers must be on the **same Docker network** (check with `docker inspect <container> --format '{{json .NetworkSettings.Networks}}'`).

## Diagnosing 401 Errors

```bash
# Check pgAdmin logs
docker logs pgadmin --tail 50 | grep -i "error\|401\|fail"

# Common patterns:
# - "Failed to decrypt the saved password" → externally injected password, use UI
# - "definition of service \"\" not found" → stale server entry, delete and re-register
# - "connection to server at \"127.0.0.1\", port 5432 failed: Connection refused" → wrong host (should be container name)
```

## Verifying PostgreSQL Password Directly

```bash
# Test from postgres container itself
docker exec postgres psql -U <user> -d <db> -c "SELECT 1"

# Test from pgadmin container (if psql available)
docker exec pgadmin sh -c 'PGPASSWORD=<pass> psql -h <host> -p 5432 -U <user> -d <db> -c "SELECT 1"'
```
