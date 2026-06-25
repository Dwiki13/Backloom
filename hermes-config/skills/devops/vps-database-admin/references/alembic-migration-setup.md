# SubTrack VPS: Alembic Migration Setup

## Context
SubTrack ID backend (`/root/projects/subtrack-id/backend`) uses FastAPI + SQLAlchemy + PostgreSQL. Initially had no migration system — tables were created via `Base.metadata.create_all()`. This document covers the first-time Alembic setup.

## Initial Setup (2026-06-12)

### Problem
- New column `ocr_detect_count` added to `User` model
- Production DB (PostgreSQL in Docker) didn't have the column
- No Alembic setup existed
- All authenticated endpoints returned 500: `column users.ocr_detect_count does not exist`

### Solution Path

#### 1. Manual Column Add (Immediate Fix)
```bash
docker exec postgres psql -U hermes -d subtrack -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS ocr_detect_count INTEGER NOT NULL DEFAULT 0;"
```

#### 2. Alembic Setup
```bash
cd /root/projects/subtrack-id/backend
alembic init alembic
```

Edit `alembic/env.py`:
```python
import os
from alembic import context
from app.database import Base
from app.models import user, subscription, family, payment  # noqa: F401

config = context.config
config.set_main_option("sqlalchemy.url", os.environ.get("DATABASE_URL", ""))
target_metadata = Base.metadata
```

**CRITICAL**: Use `os.environ.get("DATABASE_URL")` NOT `from app.config import settings`. The `settings` module reads `.env` file at import time, which may be the baked-in image `.env` (not the runtime `.env.production`). The env var is set correctly by docker-compose at container creation.

#### 3. Migration File
```bash
alembic revision --autogenerate -m "add ocr_detect_count to users"
```

**WARNING**: Autogenerate may create `op.create_table()` for ALL tables if it detects an empty comparison DB. Manually edit the migration to only include the actual change:

```python
def upgrade():
    op.add_column('users', sa.Column('ocr_detect_count', sa.Integer(), nullable=False, server_default='0'))

def downgrade():
    op.drop_column('users', 'ocr_detect_count')
```

#### 4. Alembic Version Stamp (since column was added manually)
```bash
docker exec postgres psql -U hermes -d subtrack -c "CREATE TABLE IF NOT EXISTS alembic_version (version_num VARCHAR(32) NOT NULL PRIMARY KEY); INSERT INTO alembic_version (version_num) VALUES ('a581483d9ec5') ON CONFLICT DO NOTHING;"
```

#### 5. Verify
```bash
docker exec subtrack-api alembic upgrade head
curl http://202.10.46.161:8002/health
```

## Production Deployment Notes

### Docker Compose v1 Syntax
```bash
docker rm -f subtrack-api
cd /root/projects/subtrack-id/backend
docker-compose -f docker-compose.prod.yml up -d --build subtrack-api
```

### .env.production Volume Mount
- Host file: `/root/projects/subtrack-id/backend/.env.production`
- Mounted to: `/app/.env.production` (read-only)
- **Edit on host, then recreate container** — cannot edit from inside (read-only)

## Migration Workflow for Future Changes

1. Edit model in `app/models/`
2. Generate migration: `alembic revision --autogenerate -m "description"`
3. Review/edit migration file
4. Test locally: `alembic upgrade head`
5. Commit + push
6. Deploy: pull + rebuild container
7. Run migration: `docker exec subtrack-api alembic upgrade head`
8. Verify: check logs + test endpoints
