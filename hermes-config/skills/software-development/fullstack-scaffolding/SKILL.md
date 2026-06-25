---
name: fullstack-scaffolding
description: "Scaffold, build, and deploy full-stack web applications — FastAPI, Next.js, Flutter mobile, WhatsApp bots, CI/CD pipelines, Docker, AI integration, and VPS deployment. Covers project scaffolding, GitHub Actions CI/CD, Supabase auth, Baileys/WhatsApp Web integration, and end-to-end deployment from code to production."
version: 1.6.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
---

# Full-Stack Project Scaffolding

Scaffold complete Python web applications with modern stack: FastAPI, PostgreSQL (+ pgvector), Docker, and AI integration.

## When to Use

- Building a new web app or API from scratch
- User wants a complete project with DB, API, and AI features
- Need to set up Docker Compose with multiple services
- Integrating AI (Gemini/OpenAI) into a web service
- Building a cross-platform mobile app (Flutter) with FastAPI backend
- Scaffolding a subscription-based SaaS product with monetization (free/pro/family tiers)
- User asks to "bikin app" or "scaffold project" with mobile + backend

## Architecture Pattern

### Recommended Stack
- **Backend**: Python 3.12, FastAPI, SQLAlchemy (ORM) or asyncpg (raw SQL)
- **Database**: PostgreSQL 16 + pgvector (hybrid FTS + vector search)
- **AI**: OpenRouter (primary), Google Gemini (embedding/fallback)
- **WhatsApp**: whatsapp-web.js (dev) → Meta Cloud API (prod via adapter pattern)
- **Container**: Docker Compose

### Project Structure
```
project/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI entry
│   │   ├── config.py            # Pydantic Settings from .env
│   │   ├── database.py          # SQLAlchemy engine/session
│   │   ├── models/              # SQLAlchemy models
│   │   ├── schemas/             # Pydantic schemas
│   │   ├── routes/              # API route handlers
│   │   ├── services/            # Business logic
│   │   └── utils/               # Auth, helpers
│   ├── alembic/                 # DB migrations
│   │   └── versions/
│   ├── Dockerfile
│   └── requirements.txt
├── mobile/                      # Flutter (optional)
├── docker-compose.yml
├── .env.example
└── .gitignore
```

## Database Schema Pattern

### Hybrid Search (FTS + Vector)
```sql
-- Main items table
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    type VARCHAR(20) NOT NULL,
    title VARCHAR(500),
    summary TEXT,
    raw_content TEXT,
    search_tsv tsvector,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Chunks for vector search
CREATE TABLE chunks (
    id SERIAL PRIMARY KEY,
    item_id INTEGER REFERENCES items(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding vector(768),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Family Vault Payment Tracking
```sql
CREATE TABLE family_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID REFERENCES family_vaults(id) ON DELETE CASCADE,
    member_id UUID REFERENCES family_members(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    amount FLOAT NOT NULL,
    amount_paid FLOAT DEFAULT 0,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    paid_at TIMESTAMP,
    confirmed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Family Vault Flow
1. Owner creates vault → gets invite code
2. Members join via invite code
3. Owner has subscriptions (Netflix, Spotify, etc.)
4. Owner calls `POST /{vault_id}/payments/generate` with subscription_id → system creates payment records for all members (equal split default, custom amounts optional)
5. Each member uploads transfer proof → marks payment as paid
6. Owner confirms payments
7. Owner views summary: who paid, who's pending

### Subscription Architecture
- Subscription is per-user (`user_id` FK), NOT per-family-vault
- Each family member gets their own subscription record
- Family vault = grouping container for members only
- Payment tracking = separate `family_payments` table

## WhatsApp Integration

### Adapter Pattern
Maintain a `WhatsAppAdapter` ABC so providers can be swapped via config.

### WA Business API Registration
1. Create Meta Developer account at developers.facebook.com
2. Create Business app, add WhatsApp product
3. Get: Phone Number ID, Access Token, Webhook Verify Token
4. Free tier: 1000 conversations/month

## AI Integration Pattern

### Multi-Provider (Recommended)
| Task | Provider | Model |
|------|----------|-------|
| LLM | OpenRouter | `openrouter/owl-alpha` or any |
| Embedding | Gemini | `models/gemini-embedding-001` |

### OpenRouter Configuration
```python
client = OpenAI(
    api_key=key,
    base_url="https://openrouter.ai/api/v1",
    max_retries=0,
    timeout=10.0,
)
```

## Docker Compose Pattern
```yaml
version: "3.9"
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: subtrack
      POSTGRES_USER: hermes
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data

  backend:
    build: ./backend
    env_file: .env
    ports:
      - "8002:8002"
    depends_on:
      postgres:
        condition: service_healthy
```

## Negative Testing Before Design Doc

When building a tool or product (not just implementing a feature), ALWAYS run negative testing BEFORE writing the design doc or implementation plan.

**Process:**
1. Identify failure categories (8-10): Engine/Core, Connectors/Tools, Memory/Data, Auth/UI, Deployment, Concurrency/Multi-tenancy, Security, UX Edge Cases, Time/Scheduling, Real-World Chaos
2. Brainstorm 10-15 failure modes per category
3. For each: define expected behavior (graceful degradation > crash)
4. Use findings to shape the design doc — every critical failure mode MUST have a design response
5. Include the negative testing section IN the design doc itself

**Design Doc Format:**
- Single file: `/root/projects/<project>/DESIGN.md` (NOT split into multiple files)
- Include: Executive Summary, Differentiators, Architecture, Data Model, API Design, Core Workflows, Security, Deployment, **Negative Testing & Edge Cases**, Project Structure, Roadmap
- Target: 40-60KB for a complete product design
- See `references/croncheck-negative-testing-pattern.md` for a concrete example (100 test cases across 10 categories)

**From session (June 2026):** KII explicitly requested negative testing before design doc for AgentKit (200 test cases) and CronCheck (100 test cases). Design doc should be 1 file saved to `/root/projects/<project>/DESIGN.md`. This pattern is now standard for all tool builds.

## DESIGN.md First for UI Projects

When building a mobile or web app with user-facing screens, ALWAYS create `DESIGN.md` before the implementation plan.

**DESIGN.md should include:**
- Color palette (hex codes)
- Typography
- Screen-by-screen layout
- Navigation structure
- Style references

**Workflow:** DESIGN.md → Implementation Plan → OpenCode execution

## Mobile App Pattern (Flutter)

### Flutter + FastAPI Pattern
- **State Management**: Riverpod
- **Routing**: GoRouter
- **HTTP Client**: Dio with auth interceptor (Bearer token from Firebase)
- **Auth**: Firebase Auth
- **Push**: Firebase Cloud Messaging

## Procedure

0. **Create plan.md first** — Before running OpenCode, write a detailed plan to `.hermes/plans/<feature-name>.md`. Include: context, scope (files to modify AND files NOT to modify), step-by-step changes, DB schema if applicable, and verification steps. KII's rule: "tambahin dulu plan.md nya baru jalankan workflow coding."

1. **Plan the architecture** — confirm stack, DB schema, API endpoints

2. **Set up infra** — Docker Compose, init DB schema via Alembic

3. **Code ALL changes through OpenCode** — ALWAYS use OpenCode for coding tasks. Never edit files directly. Command: `/root/.opencode/bin/opencode run "[task]" --model opencode/deepseek-v4-flash-free`

4. **Review generated code** — check syntax (`python3 -m py_compile`), imports, architecture consistency

5. **Test** — verify endpoints, run migrations

6. **Deploy** — push to GitHub. Deploy to VPS only when KII explicitly asks — never auto-deploy. KII's rule: "belum, mau aku deploy?"

## KII's Plan-First Workflow

**ALWAYS write a plan before coding.** KII's rule: "buat plan dulu baru coding" / "jangan coding dulu".

Workflow:
1. Analyze existing code (read files, understand current state)
2. Write plan in chat — include: files to change, migration steps, test updates
3. Wait for KII approval: "oke implementasikan" or "oke mulai coding"
4. Run OpenCode: `/root/.opencode/bin/opencode run "[plan]" --model opencode/deepseek-v4-flash-free`
5. OpenCode handles: model changes, schema changes, route changes, migration, tests
6. After OpenCode: run `python -m pytest tests/ -x -q` to verify
7. Commit & push, then deploy: `docker cp ... && docker restart subtrack-api`

**NEVER start coding without an approved plan.** Even for small fixes — say "ini plan-nya: ..." first.

## Family Vault Billing Design (June 2026)

### Final Design: Simple Split-Equal
- **No `billing_type` field** — removed. Always split equally.
- **No `share_percentage` billing** — field exists on FamilyMember but not used for billing.
- **Formula**: `amount_per_member = round(subscription.price / member_count)`
- **All members pay the same amount** — no full_price option, no custom percentages.
- **Rationale**: "Kalo full_price, member mikir 'gua tambahin langganan sendiri aja tanpa join vault'"

### payment_info Field
- `FamilyVault.payment_info` (Text, nullable) — bank account / e-wallet info for members
- Example: "Transfer ke BCA 1234567890 a.n. John Doe" or "GoPay 081234567890"
- API: accepted in `POST /api/v1/family` and `PUT /api/v1/family/{vault_id}`, returned in vault response
- Flutter displays this so members know where to transfer

### Payment Flow
1. Celery Beat generates payments on 1st of each month (`generate_family_payments` task)
2. Each member gets `FamilyPayment` with `amount = round(price / member_count)`
3. Member uploads transfer proof → status becomes `AWAITING_CONFIRM`
4. Owner confirms/rejects → `CONFIRMED` or back to `PENDING`
5. If proof deleted → status reverts to `PENDING`
6. Auto-confirm after 24h if owner doesn't respond

## Common Pitfalls

### Telegram File Delivery

- **`send_message` with `media` to Telegram topics/threads often silently fails** — the API returns success (`message_id` assigned) but the attachment never appears in the chat. This happens especially in nested topics/threads (e.g., `telegram:-1003966561389:334`).
- **Workaround 1**: Send to DM directly (`telegram:1724161158`) — more reliable for file attachments.
- **Workaround 2**: Host the file on the web server and share the URL:
  ```bash
  cp /path/to/file /var/www/devlokal.id/html/filename.ext
  # Then send: https://devlokal.id/filename.ext
  ```
- **Workaround 3**: Resize small images (e.g., favicon 180x180 → 512x512) — Telegram may treat tiny files as thumbnails and suppress the attachment.
- **Always verify**: After sending, ask the user to confirm they received the attachment. Don't assume success from the API response alone.

### OCR-Based Detection
- Keyword and price may land on different OCR lines → use expanding outward price search from keyword line
- SKIP_KEYWORDS check must be per-line, not full-text (full-text check breaks family vault where members pay via transfer)
- See [references/subtrack-detector-family-vault-lessons.md](references/subtrack-detector-family-vault-lessons.md)

### SQLAlchemy / PostgreSQL
- **Enum case mismatch**: Python enum lowercase vs DB enum uppercase → `invalid input value for enum` error. Always sync enum values between Python and DB.
- **postgres password + volume**: When volume exists, `POSTGRES_PASSWORD` env var is ignored. Must `ALTER USER` manually inside container.
- **Alembic autogenerate drift**: Existing table changes detected by autogenerate ≠ your changes. Create migration manually with raw SQL.
- **DB credentials**: Never change DB password without KII's explicit instruction. Current: user=`hermes`, password=`hermespassword`.
- **FK cascade chains**: When adding a new table with FKs to existing tables, ALL FKs in the cascade chain must have `ondelete="CASCADE"` at the DB level. SQLAlchemy relationship `cascade` alone is NOT sufficient — PostgreSQL blocks the delete at DB level before SQLAlchemy can act. Audit existing FKs before adding new ones. See [references/subtrack-db-schema-lessons.md](references/subtrack-db-schema-lessons.md).
## Docker Deployment

- **Preferred deploy**: `docker cp <file> subtrack-api:/app/<path> && docker restart subtrack-api` — faster than rebuild
- **Full rebuild** (when needed): `docker-compose up -d --build api`
- **Migration after rebuild**: Run from inside container: `docker-compose exec backend alembic upgrade head`
- **Migration chain issues**: If migration references a previous migration not yet applied on target, copy ALL missing migration files to container first, then run `alembic upgrade head`
- **Don't auto-deploy**: Always ask KII before deploying to VPS.

### Firebase Auth
- **Relative path for credentials**: `FIREBASE_CREDENTIALS_PATH` must be absolute or uvicorn cwd must match. Wrong cwd → `FileNotFoundError` → all auth routes 500.
- **Email collision**: Check both `firebase_uid` AND `email` before inserting new user to avoid `users_email_key` UniqueViolation.

### Midtrans Payment Integration
- **Snap API**: use `snap.create_transaction()` — NOT `create_transaction_token()`. Returns dict with `token` + `redirect_url`.
- **Signature verification**: `SHA512(order_id + status_code + gross_amount + server_key)`. Return `{"message": "OK"}` (not 400) when signature fails in dev/test so Midtrans doesn't retry.
- **Webhook lookup**: `order_id` = `Payment.id` (UUID), NOT `external_transaction_id`
- **Idempotency**: always check `payment.status == COMPLETED` before reprocessing
- **Never read `.env`** — instruct user to update keys manually
- **SQLite UUID comparison**: explicitly cast `UUID(data.param)` when comparing UUID columns with string params — SQLite can't auto-convert
- See [references/subtrack-midtrans-integration.md](references/subtrack-midtrans-integration.md) for full integration guide.

### Subscription Cancel vs Downgrade
- **Cancel**: Deactivate subscriptions but keep current tier until billing period ends. User retains paid features until expiry.
- **Downgrade**: Immediately revert tier to `free` and deactivate all subscriptions. User loses paid features immediately.
- **Implementation**: Cancel sets `subscription.is_active = False` but doesn't change `user.tier`. Downgrade sets both `subscription.is_active = False` AND `user.tier = UserTier.FREE`.

### Profile Photo Upload Pattern
When adding profile photo upload to an existing auth system:

**Endpoint**: `POST /api/v1/auth/upload-photo`
- Accepts `multipart/form-data` with `file` field
- Validate extension whitelist: `{".jpg", ".jpeg", ".png", ".webp"}`
- Validate max file size (e.g., 5MB)
- Save as `{user_id}.{ext}` in dedicated dir (e.g., `/app/uploads/profile_photos/`)
- Overwrite previous photo (same filename per user)
- Update `user.photo_url` with full URL: `https://{DOMAIN}/uploads/profile_photos/{user_id}.{ext}`
- Return `UserResponse` with updated `photo_url`

**Static files**: Ensure `app.mount("/uploads", StaticFiles(directory="/app/uploads"))` covers the profile photos subdirectory.

**Flutter side**: Use `NetworkImage(photo_url)` in `CircleAvatar` widget.

### Profile Update Endpoint
**Endpoint**: `PUT /api/v1/auth/profile`
- Body: `{"display_name": "...", "photo_url": "..."}` (both optional)
- Only update fields that are not `None`
- Touch `updated_at` on every update
- Return `UserResponse`

### Project Documentation Pattern (for KII's manual coding)
When KII wants to code manually with OpenCode assistance, create these docs BEFORE coding:
1. `DESIGN.md` — product overview, architecture, user flow
2. `ARCHITECTURE.md` — system architecture, layer diagrams, auth flow, deployment
3. `API_REFERENCE.md` — all endpoints with request/response schemas
4. `DATABASE_SCHEMA.md` — SQL schema + SQLAlchemy models + migration guide
5. `FRONTEND_SPEC.md` — screen-by-screen spec, component tree, API client pattern
6. `SPRINT_PLAN.md` — sprint breakdown with task lists
7. `SETUP_GUIDE.md` — dev environment setup, Docker, env vars, troubleshooting
8. `DESIGN_SYSTEM.md` — color palette, typography, spacing, component styles
9. `STYLE_GUIDE.md` — Tailwind config, CSS variables, shadcn/ui setup, utility classes
10. `BRAND_GUIDELINES.md` — logo, tone of voice, copywriting, landing page copy
11. `.env.example` — template environment variables
12. `README.md` — project overview

**Rule**: KII prefers to review and discuss design docs BEFORE any coding starts. Never start coding without KII's approval of the docs/plan.

### "Just Asking" Pattern
When KII says "jangan lakukan apa apa ya", "gua hanya nanya", or "cek dulu aja" — this is an **inspect-only** request. Do NOT modify any files, do NOT suggest changes, do NOT "helpfully" fix things. Just answer the question and stop. KII explicitly controls when changes happen.

### GitHub Repo Creation
```bash
# Initialize locally first
git init && git add -A && git commit -m "initial commit"

# Create repo on GitHub (private)
gh repo create Dwiki13/<repo-name> --private --description "..."

# Add remote + push
git remote add origin https://github.com/Dwiki13/<repo-name>.git
git branch -M main
git push -u origin main
```

**Pitfalls:**
- `gh repo create --source=.` fails with `"current directory is not a git repository"` even when `.git` exists — `gh` sometimes can't detect the repo from certain working directories. Always use `--source=.` only when `gh` confirms the cwd is a git repo, otherwise create the repo separately and push manually.
- If `git push` fails with `"not a git repository"` after the cwd has changed between tool calls, use absolute paths with `GIT_DIR` and `GIT_WORK_TREE`:
  ```bash
  GIT_DIR=/root/projects/<repo>/.git GIT_WORK_TREE=/root/projects/<repo> git push -u origin main
  ```
- Never run `gh repo create` with `--push` flag when the repo was already initialized locally — it conflicts. Create repo first, then push.

### .env.example Filling Pattern

When KII asks to "bantu isi" or "update" `.env.example` for VPS deployment:

1. **Pull latest** — always `git pull` first to get KII's latest changes
2. **Check VPS state** — inspect running containers, DB credentials, Redis config:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Image}}"
   docker exec postgres psql -U hermes -d <db> -c "SELECT current_user;"
   ```
3. **Generate secrets** — use `python3 -c "import secrets; print(secrets.token_hex(32))"` for SECRET_KEY, ENCRYPTION_KEY, etc.
4. **Update .env.example** — replace placeholders with VPS-specific values:
   - `DATABASE_URL`: use container name as host (e.g., `db`, `postgres`) for Docker-to-Docker
   - `REDIS_URL`: same pattern
   - `DOMAIN`: production domain (e.g., `gdrive.devlokal.id`)
   - `*_REDIRECT_URI`: must match production domain with `https://`
   - `*_API_URL`: must match production domain
5. **Commit + push** — use `GIT_DIR`/`GIT_WORK_TREE` if cwd issue occurs
6. **Never overwrite KII's credentials** — if KII already filled in values (e.g., Google Client ID/Secret), preserve them and only fill in the remaining placeholders

### Google OAuth2 Setup (for KII)

When KII asks where to get Google Client ID/Secret:

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create new project (or use existing)
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. If prompted, configure **OAuth consent screen** first:
   - App name: `<Project Name>`
   - User support email: KII's email
   - Authorized domains: `devlokal.id`
6. Application type: **Web application**
7. Add **Authorized redirect URIs**:
   ```
   https://<domain>/accounts/google/callback
   ```
8. Click **Create** → copy Client ID and Client Secret
9. If reusing an existing OAuth client (e.g., from SubTrack), just add the new redirect URI to the existing client

**Note:** KII usually fills in the credentials manually. OWL's role is to generate the redirect URI and guide where to paste it.

### Cross-Stack Type Consistency
- **Backend ↔ Flutter type mismatch**: When adding new fields to backend schemas, verify the type matches Flutter model expectations BEFORE committing.
  - Example: `first_payment_month` backend returned `Optional[str]` ('YYYY-MM') but Flutter expected `int?` → mismatch caused integration gap.
  - Fix: align types at schema level. Prefer `int` for month values, `str` for ISO dates — match Flutter's `int?` / `String?` expectations.
- **Rule**: When backend adds a new field, check ALL Flutter model files that parse it. Run integration check after.

### Test Assertions with Config-Dependent Values
- **Never hardcode domain/URL in test assertions** — `DOMAIN` config may differ between dev/staging/prod.
- **Bad**: `assert p["proof_url"] == "https://localhost:8000/app/uploads/proofs/test.jpg"`
- **Good**: `assert "app/uploads/proofs/test.jpg" in p["proof_url"]` (flexible) or `os.environ.get("DOMAIN", "localhost:8000")` (config-aware)
- **Import inside test functions**: `from app.config import X` may fail due to circular imports in test context. Use `os.environ` instead.

## Verification

Smoke test OpenCode:
```
terminal(command="opencode run 'Respond with exactly: OPENCODE_SMOKE_OK'")
```

Success criteria:
- Output includes `OPENCODE_SMOKE_OK`
- For code tasks: `python3 -m py_compile` passes, imports resolve

## Integration with Other Skills

- **OpenCode** (`autonomous-ai-agents/opencode`): The coding workflow engine — all code goes through this
- **writing-plans** (`_archive/writing-plans`): For creating implementation plans before OpenCode execution
- **subagent-driven-development** (`software-development/subagent-driven-development`): For complex multi-file refactors
- **cross-stack-integration-check** (`software-development/cross-stack-integration-check`): For detecting backend/frontend integration gaps and generating reports

## References

See [references/secondbrain-project.md](references/secondbrain-project.md) for Second Brain project lessons.
See [references/subtrack-project.md](references/subtrack-project.md) for SubTrack ID project specifics.
See [references/gdrive-storage-project.md](references/gdrive-storage-project.md) for Gdrive Storage project specifics.
See [references/croncheck-project.md](references/croncheck-project.md) for CronCheck project specifics.
See [references/subtrack-detector-family-vault-lessons.md](references/subtrack-detector-family-vault-lessons.md) for OCR extraction & family vault payment lessons.
See [references/subtrack-opencode-lessons.md](references/subtrack-opencode-lessons.md) for OpenCode workflow pitfalls & project rules.
See [references/subtrack-celery-tasks.md](references/subtrack-celery-tasks.md) for Celery + Beat task reference (schedules, endpoints, Docker services).
See [references/subtrack-db-schema-lessons.md](references/subtrack-db-schema-lessons.md) for DB schema lessons including FK cascade chains.
See [references/sqlite-test-fixture-isolation.md](references/sqlite-test-fixture-isolation.md) for SQLite test fixture isolation pattern (multi-file pytest + FastAPI + SQLAlchemy).
See [references/firebase-auth-fastapi.md](references/firebase-auth-fastapi.md) for Firebase Auth + FastAPI integration.
