# Second Brain Project Reference

> Project: Second Brain via WhatsApp — Personal knowledge manager
> Repo: https://github.com/Dwiki13/secondbrain
> Status: MVP working — WA + OpenAI + DB (June 2026)

## Project Decisions

### Tech Stack
- **Backend**: Python 3.12, FastAPI, asyncpg (raw SQL, no ORM)
- **Database**: PostgreSQL 16 + pgvector 0.8.2 (port 5433)
- **AI**: OpenAI (LLM) + Gemini (embedding)
- **WhatsApp**: Baileys via subprocess bridge (dev, QR scan) → Meta Cloud API (prod)
- **Container**: Docker Compose (DB + API)

### AI Provider Strategy (Updated June 2026)
All free LLM providers (Gemini, Groq, OpenRouter free models) are heavily rate-limited. Current approach:

| Task | Provider | Model | Status |
|------|----------|-------|--------|
| LLM (summarize, categorize) | **OpenAI** | `gpt-4o-mini` | ✅ Working (paid, $5 credit) |
| Embedding | Gemini | `models/gemini-embedding-001` | ⚠️ Rate-limited |

**Provider history**: OpenRouter free → OpenAI paid (KII chose OpenAI for reliability with $5 top-up).

**Fallback mode (active)**: Truncated text for summary, "lainnya" for category, zero vector for embedding. This IS the MVP path until a paid key is available.

**Key lesson**: Don't rely on any single free provider. Implement graceful fallbacks from day 1.

### OpenAI Integration (June 2026)
KII chose OpenAI over OpenRouter/Groq for reliability. Setup:
1. Create account at [platform.openai.com](https://platform.openai.com)
2. Top up $5-10 (enough for MVP testing)
3. Create API key (format: `sk-proj-...`)
4. Update `.env`: `OPENAI_API_KEY=*** Model: `gpt-4o-mini` (cheap, fast, good quality)

**Important**: Baileys swap does NOT fix LLM rate limiting — it only changes the WhatsApp connection layer. LLM and WA adapter are separate concerns.

### Architecture
- Adapter pattern for WhatsApp (swappable dev/prod)
- Hybrid search: FTS (ts_rank) + vector (cosine) with RRF fusion
- Multi-source ingest: text, URL (phase 1), PDF/image/voice (phase 2)
- Baileys subprocess bridge via stdin/stdout JSON lines

### Database
- DB: `secondbrain`, User: `secondbrain`, Port: `5433`
- Password: set via `ALTER USER` (not from `.env` — Hermes masks it)
- Tables: `users`, `items`, `chunks`
- Embedding: `vector(768)` with HNSW index
- FTS: GIN index on `search_tsv` with auto-update trigger

## Lessons Learned

### API Key Format Gotchas
- **Gemini (AI Studio)**: Valid key starts with `AIzaSy...`. Keys starting with `AQ...` are NOT Gemini keys.
- **Groq**: Valid key starts with `gsk_...`
- **OpenAI**: Valid key starts with `sk-...`
- **OpenRouter**: Valid key starts with `sk-or-v1-...`
- If a user shares a key with unexpected prefix, verify it's from the correct provider before debugging auth errors.

### Gemini API
- Free tier rate limits hit fast (daily quota can exhaust in minutes)
- Always implement rate limiting (6s between requests) + graceful fallbacks
- `text-embedding-004` is deprecated → use `models/gemini-embedding-001`
- Embedding returns 3072 dims → truncate to 768 for pgvector HNSW
- **Gemini embedding is synchronous** — `genai.embed_content()` blocks the FastAPI event loop. Wrap in `ThreadPoolExecutor` with timeout.
- Daily quota resets at midnight Pacific Time (14:00 WIB next day)

### OpenRouter
- Free models (`:free` suffix) are **extremely** rate-limited — expect 429 errors during development
- Even with a valid key, free models may be unavailable
- Paid models are more reliable but cost money
- Always add `timeout=10.0` to OpenRouter API calls to prevent hanging
- **OpenRouter auto-retry**: The OpenAI Python SDK auto-retries on 429 with exponential backoff (11s, 30s, 29s...). This causes very long request times even with `timeout=10.0`. Set `max_retries=0` or `max_retries=1` on the OpenAI client to fail fast and use fallback:
```python
from openai import OpenAI
client = OpenAI(
    api_key=key,
    base_url="https://openrouter.ai/api/v1",
    max_retries=0,  # Fail fast, use fallback
    timeout=10.0,
)
```

### pgvector
- Version 0.8.2 caps HNSW at 2000 dimensions
- Must truncate embeddings to ≤2000 dims (768 is safe)
- `ALTER TABLE chunks ALTER COLUMN embedding TYPE vector(768)` works with existing data
- Must drop and recreate index after changing column type
- **Vector encoding**: Must convert `list[float]` to `[x,x,x,...]` string for asyncpg

### asyncpg
- `asyncpg.create_pool(dsn=...)` with `postgresql://` scheme often ignores the port
- Parse DSN manually with `urllib.parse.urlparse()` and pass explicit params
- `.env` password masked by Hermes (shows as `***`) — detect and use fallback

### FastAPI
- Running with `--reload` flag can suppress stdout/stderr output
- Always add timeouts to synchronous AI calls to prevent blocking the event loop
- Use `background=True` for long-running processes, not shell `&`
- **Port already in use**: When restarting FastAPI, old process may still hold the port. Kill with `fuser -k 8000/tcp` or `lsof -ti:8000 | xargs kill -9` before restart.

### Baileys (Current — June 2026)
- Auth dir: `.baileys_auth/` (NOT `.wwebjs_auth/`)
- Clear when switching adapters: `rm -rf .baileys_auth`
- Requires `makeCacheableSignalKeyStore` — without it, infinite disconnect loop
- Requires `git` in Docker for `npm install` (installs from GitHub)
- Large JSON lines (QR codes) exceed Node.js `readline()` 64KB buffer — use custom chunked reader in Python
- Repeated "disconnected" logs during QR generation = normal retry behavior
- **Heartbeat timeout**: After AI calls complete, Baileys may disconnect because the synchronous AI call blocks the event loop, preventing heartbeat. Auto-reconnects after ~5-7s. Minor issue — messages during reconnect window may be lost.

### .gitignore Essentials
Always include from project start:
```
.wwebjs_auth/
.baileys_auth/
node_modules/
__pycache__/
*.pyc
.env
```

### OpenCode Workflow
- Always create repo first (`gh repo create`), then scaffold
- Provide detailed task descriptions with exact model names + dimensions
- Review generated code for: duplicate statements, wrong dims, deprecated models
- After OpenCode generation, always verify imports resolve and no duplicate code

### .env File Protection
- Hermes blocks reading `.env` files (shows `***` for all values)
- Use `python3 -c` with inline env vars for testing
- Detect `***` in settings and use fallback values

## Docker Networking on VPS

### Critical: Docker DNAT Can Hijack Host Ports

When Docker containers publish ports, Docker adds DNAT rules to iptables. These rules intercept traffic BEFORE it reaches host processes.

**Symptom**: `curl localhost:8000` works, but `curl http://PUBLIC_IP:8000` returns content from a different service (or 404).

**Diagnosis**:
```bash
# Check for DNAT rules on your port
iptables -t nat -L -n | grep 8000
# Example output showing the problem:
# DNAT tcp -- 0.0.0.0/0 0.0.0.0/0 tcp dpt:8000 to:172.17.0.2:8000

# Find which container owns the IP
docker ps -q | while read cid; do
  ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cid)
  name=$(docker inspect -f '{{.Name}}' $cid)
  echo "$name → $ip"
done
```

**Solution**: Run your service in Docker on the same Docker network as the proxy (NPM), so traffic stays within Docker networking.

### Running FastAPI in Docker with Multiple Networks

When FastAPI needs to talk to both DB and NPM proxy, attach it to both networks:

```bash
# Run FastAPI on DB network
docker run -d --name api --network db_net \
  -e DATABASE_URL="postgresql://user:***@db:5432/dbname" \
  myapp

# Then attach to NPM network too
docker network connect npm_default api
```

A Docker container can be on multiple networks simultaneously.

### NPM Container Can't Reach Host Services

NPM in Docker **cannot** reliably reach services on the host via `172.17.0.1` when DNAT rules exist for that port. **Solution**: Run everything in Docker on shared networks. Use container names (e.g., `api`, `db`) instead of IPs in configs.

### FastAPI Import Path in Docker

The `uvicorn` module string must match the Python import path from WORKDIR:

```dockerfile
# If main.py imports "api.config":
COPY api/ /app/api/
CMD ["uvicorn", "api.main:app", ...]

# If main.py imports "config" (flat):
COPY . .
CMD ["uvicorn", "main:app", ...]
```

## Service Exposure / Reverse Proxy Pattern

### Problem: Exposing Non-Standard Ports on VPS

When running services on non-standard ports (e.g., 8000 for FastAPI), you can't always open them in the firewall. Common VPS setups have:
- Firewall (ufw/iptables) blocking all except SSH, 80, 443
- Nginx Proxy Manager (NPM) in Docker handling 80/443
- Docker proxy intercepting traffic on published ports

### Solution: Nginx Proxy Manager Reverse Proxy

Instead of opening new ports, route through NPM on port 443:

1. **Add DNS A record**: `subdomain.domain.com → VPS_IP`
2. **Add NPM proxy host config** (file-based, since NPM UI may be inaccessible):
```bash
cat > /tmp/sb_proxy.conf << 'EOF'
server {
  set $forward_scheme http;
  set $server         "secondbrain-api";
  set $port           8000;

  listen 80;
  listen [::]:80;
  listen 443 ssl;
  listen [::]:443 ssl;

  server_name subdomain.domain.com;

  include conf.d/include/letsencrypt-acme-challenge.conf;
  include conf.d/include/ssl-cache.conf;
  include conf.d/include/ssl-ciphers.conf;
  ssl_certificate /etc/letsencrypt/live/npm-1/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/npm-1/privkey.pem;

  access_log /data/logs/sb_access.log proxy;
  error_log /data/logs/sb_error.log warn;

  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://secondbrain-api:8000;
  }
}
EOF
docker cp /tmp/sb_proxy.conf npm_npm_1:/data/nginx/proxy_host/2.conf
docker exec npm_npm_1 nginx -t && docker exec npm_npm_1 nginx -s reload
```

3. **SSL**: NPM auto-requests Let's Encrypt certs when DNS resolves. If cert fails, check DNS propagation first.

### Debugging: "Works on localhost but not from IP"

If `curl localhost:8000` works but `curl http://PUBLIC_IP:8000` returns "Not found":
1. Check firewall: `ufw status`, `iptables -L INPUT -n | grep PORT`
2. Check for hairpin NAT issues (server can't reach itself via public IP)
3. Check if Docker proxy or nginx is intercepting: `ss -tlnp | grep PORT`
4. Check routing: `ip route show default`
5. Test with `tcpdump -i eth0 port PORT -c 10` to see if traffic arrives

### NPM Default Ports
- NPM UI: port 81 (not firewalled by default — use SSH tunnel: `ssh -L 81:localhost:81 user@host`)
- NPM proxy: ports 80, 443 (firewalled — must use reverse proxy pattern above)

## Recent Fixes (June 2026 Session)

### Port Conflict: FastAPI vs Portainer
Portainer claims port 8000 by default. FastAPI must use a different external port:
```yaml
# docker-compose.yml
ports:
  - "8001:8000"  # host:container — 8000 is taken by Portainer
```

### Verified Working State (June 4, 2026)
- `secondbrain-api` container running on port 8001→8000
- `secondbrain-db` container healthy on port 5433
- User `secondbrain` created in PostgreSQL with password
- `/health` returns `{"status":"ok","database":"connected"}` via `localhost:8001` and `https://secondbrain.devlokal.id`
- `/api/qr` serves QR code HTML page with client-side rendering
- `/api/stats` shows items in database
- SSL via Let's Encrypt on `secondbrain.devlokal.id` working
- DNS `secondbrain.devlokal.id → 202.10.46.161` propagated
- Baileys adapter connected, QR scanned, messages received
- OpenAI LLM (gpt-4o-mini) summarizing messages successfully
- End-to-end flow: WA message → Baileys → FastAPI → OpenAI summarize → save to DB ✅

### Working with User Manual Fixes
When KII fixes things manually and asks to "cek dulu, jangan ubah apa-apa":
1. **Never change code** — only inspect and verify
2. Run `git diff` to see what changed
3. Test endpoints to confirm working state
4. If asked, commit & push the changes with a descriptive message
5. Update README if needed for clarity

### PostgreSQL User Creation (June 2026)
`POSTGRES_USER` / `POSTGRES_PASSWORD` in docker-compose only creates the **default superuser** (usually `postgres`). If your app uses a different DB user (e.g., `secondbrain`), you must create it manually:

```bash
# Create app user
docker exec <container> psql -U postgres -c "CREATE USER secondbrain WITH PASSWORD 'your_password';"
# Grant privileges
docker exec <container> psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE secondbrain TO secondbrain;"
# Test
docker exec <container> psql -U secondbrain -d secondbrain -c "SELECT 1;"
```

Then update `.env` to use the new user. The `init_db.py` script creates tables but does NOT create PostgreSQL users.

### .env.example Is Meant to Be Pushed
`.env.example` is a **template** — it's supposed to be committed to GitHub. It should contain placeholder values (`your_key_here`), NOT real secrets. The real `.env` is in `.gitignore`. If `.env.example` has placeholder values, it's correct and safe to push.

### WhatsApp Personal Number Works for Dev
You can use a personal WhatsApp number for QR scan mode. Messages from **any** number (including WA Business accounts) to the bot number will be received. The bot doesn't need a dedicated number in QR scan mode — that's only required for Meta Cloud API production mode.

### End-to-End Flow Verified (June 4, 2026)
Full flow confirmed working:
1. Scan QR → WA connected ✅
2. Send message from different number → received ✅
3. Message processed by ingest service ✅
4. OpenAI summarizes message (e.g., "Test bro" → "Tes berhasil. Ada yang bisa saya bantu?") ✅
5. Saved to DB with summary + category ✅
6. Searchable via hybrid search ✅
7. Accessible via `https://secondbrain.devlokal.id` with SSL ✅

### Baileys Swap — IMPLEMENTED (June 2026)

Baileys adapter was implemented and pushed to GitHub (commit `1102f66`):
- New files: `api/adapters/baileys.py`, `api/adapters/wa_bridge_baileys.js`
- `api/main.py` now imports `BaileysAdapter` for `WA_MODE=web`
- `api/package.json` includes `@whiskeysockets/baileys ^6.7.0`
- `api/Dockerfile` simplified (removed Puppeteer/Chromium deps), added `git` for npm install
- `api/services/ai.py` uses OpenAI client (`gpt-4o-mini`) instead of OpenRouter

**Verified working**: Baileys connects, QR generates, messages received, OpenAI summarizes.

### Auto-Reply Not Yet Implemented (June 2026)

The bot currently only receives and saves messages. It does NOT auto-reply. To add auto-reply, modify `handle_incoming_message` in `main.py`:

```python
# After saving item, send reply
await _wa_adapter.send_message(
    to=data["from"],
    text=f"✅ Tersimpan: {summary}"
)
```

### Docker Multi-Network Fix (June 2026)

NPM container couldn't reach `secondbrain-api` by name because they were on different Docker networks. Fix:
```bash
docker network connect npm_default secondbrain-api
```

After this, `https://secondbrain.devlokal.id/health` returned 200 OK.

### Docker Compose v1 ContainerConfig Bug

After `docker-compose down secondbrain-api`, subsequent `docker-compose up -d` failed with `KeyError: 'ContainerConfig'`. The `down` command corrupted container metadata. Fix:
```bash
docker rm -f secondbrain-api
docker-compose up -d secondbrain-api
```

### Baileys npm install Requires Git

Baileys (`@whiskeysockets/baileys`) is hosted on GitHub. `npm install` in Dockerfile failed with `ENOENT` because `git` wasn't installed. Added `git` to apt-get in Dockerfile. As fallback, installed directly in running container:
```bash
docker exec secondbrain-api bash -c "cd /app/api && npm install @whiskeysockets/baileys"
```

### Baileys Heartbeat Timeout After AI Calls

After OpenAI LLM calls complete (2-5s), Baileys often disconnects because the synchronous AI call blocks the FastAPI event loop, preventing Baileys heartbeat from being sent in time. Auto-reconnects after ~5-7s. Minor issue — messages during reconnect window may be lost. Potential fix: run AI calls in separate thread/process.

### TODO (Next Steps)

- [x] Dockerize FastAPI app (build + run in container)
- [x] Fix DB auth for Docker container
- [x] Connect FastAPI container to both networks
- [x] SSL + DNS via NPM working
- [x] Swap WhatsApp adapter to Baileys
- [x] Swap LLM to OpenAI
- [x] Docker multi-network connectivity fix
- [x] Baileys npm install fix (git in Dockerfile)
- [x] End-to-end flow verified (WA → Baileys → FastAPI → OpenAI → DB)
- [ ] Add auto-reply to WhatsApp messages
- [ ] Fix Baileys heartbeat timeout after AI calls
- [ ] Add PDF ingest (phase 2)
- [ ] Add image OCR (phase 2)
- [ ] Add voice note transcription (phase 2)
- [ ] Web dashboard (Next.js, phase 2)
