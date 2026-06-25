# Git Diff — Checking Uncommitted Changes

KII frequently asks: "yang lokal belum commit/endpoint apa aja yang berubah?"

## Quick Workflow

```bash
# 1. Check what's changed
cd /root/projects/subtrack-id/backend
git status

# 2. See summary of changes
git diff --stat

# 3. See detailed changes per file
git diff app/routes/<file>.py
git diff app/services/<file>.py
git diff app/models/<file>.py
git diff app/schemas/<file>.py
git diff tests/
```

## How to Report

When listing uncommitted endpoint changes, categorize by:
1. **BARU** — new endpoint
2. **DIUBAH** — existing endpoint modified (what changed)
3. **DIHAPUS** — endpoint removed
4. **MODEL/SCHEMA** — supporting model/schema changes
5. **SERVICE** — Celery tasks, business logic
6. **TEST** — test file changes

Always include the HTTP method + path for each endpoint change.
