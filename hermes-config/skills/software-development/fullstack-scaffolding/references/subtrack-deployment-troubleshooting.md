# SubTrack ID — Deployment Troubleshooting

## DB Container Rebuild + Password Mismatch Cascade

When a DB container is rebuilt, the password in `.env.production` must match the DB's actual password. If the volume is recreated from scratch, the `POSTGRES_PASSWORD` env var sets the initial password. If the volume already has data, the env var is ignored.

**Fix when password doesn't match:**
```sql
ALTER USER hermes PASSWORD 'newpassword';
```

## VPS Docker Deploy Checklist

1. `git pull` on VPS
2. `docker-compose -f docker-compose.prod.yml build subtrack-api`
3. `docker stop subtrack-api && docker rm subtrack-api`
4. `docker-compose -f docker-compose.prod.yml up -d subtrack-api`
5. `docker logs subtrack-api --tail 10`

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `ResponseValidationError: id should be valid string` | Pydantic `id: str` vs SQLAlchemy UUID | Add `@field_validator("id", mode="before")` returning `str(v)` |
| `ResponseValidationError: created_at` | Pydantic `created_at: str` vs datetime | Add `@field_validator` returning `v.isoformat()` |
| `LookupError: 'family' not in enum` | Python enum lowercase, DB enum uppercase | Sync both to same case |
| `password authentication failed` | `.env` password ≠ DB password | Update DB password |
| `database does not exist` | Fresh DB, no DB created | `CREATE DATABASE subtrack;` |
| Mobile: `Null is not subtype of String` | Response field missing/null | Ensure all schema fields populated |
