# SubTrack ID Project — Session Reference

## Project Info
- **Repo:** github.com/Dwiki13/subtrack-id
- **Path:** `/root/projects/subtrack-id/`
- **Backend:** FastAPI + PostgreSQL
- **Frontend:** Flutter
- **Port:** 8002 (host), 8000 (container)
- **DB:** user=`hermes`, password=`hermespassword`, host=`postgres`, port=5432, db=`subtrack`

## Docker Compose
- **Service name:** `api` (NOT `backend`)
- **Container name:** `subtrack-api`
- **Commands:** `docker-compose exec api ...` or `docker exec subtrack-api ...`
- **Logs:** `docker logs --tail 20 subtrack-api`

## OpenCode Workflow
```bash
cd /root/projects/subtrack-id && /root/.opencode/bin/opencode run "[task]" --model opencode/deepseek-v4-flash-free
```
- Always create `plan.md` in `.hermes/plans/` BEFORE running OpenCode
- After OpenCode: verify syntax, commit, push
- Never write code directly — always use OpenCode

## Alembic Migration Patterns

### Enum Naming Conflicts
- Two tables with different enum values but same `name=` in `sa.Enum(...)` cause PostgreSQL conflict
- Fix: Use unique enum names per table (e.g. `family_paymentstatus` vs `paymentstatus`)

### FK Cascade on Delete
- Add `ondelete="CASCADE"` to FK definition AND migration to drop/recreate constraint
- Check: `psql -U hermes -d subtrack -c "\d table_name"`

### Raw SQL Fallback
When `alembic upgrade head` fails due to transaction state:
```sql
BEGIN;
CREATE TABLE IF NOT EXISTS ...;
ALTER TABLE ... DROP CONSTRAINT IF EXISTS ...;
ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY (...) REFERENCES (...) ON DELETE CASCADE;
COMMIT;
```

## Known Issues

### Delete Vault 500 Error
- Cause: `family_payments` table missing OR FK cascade missing on `family_members.vault_id`
- Fix: Run migration after ensuring enum names don't conflict

### Detector Price Extraction
- Problem: keyword and price on different lines
- Fix: nearest-line expanding search fallback in `detector.py`

### SKIP_KEYWORDS Filter
- Per-line check only (not full-text) for family vault transfer context
