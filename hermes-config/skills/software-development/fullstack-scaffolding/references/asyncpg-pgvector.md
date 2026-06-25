# asyncpg + pgvector Technical Pitfalls

## 1. asyncpg DSN Parsing — Port Ignored

`asyncpg.create_pool(dsn=...)` with `postgresql://` scheme often ignores the port and falls back to 5432.

**Fix**: Parse DSN manually:
```python
import urllib.parse
dsn = dsn.replace("postgresql://", "postgres://", 1)
p = urllib.parse.urlparse(dsn)
pool = await asyncpg.create_pool(
    host=p.hostname, port=p.port or 5433,
    user=p.username, password=p.password,
    database=p.path.lstrip("/"),
)
```

## 2. pgvector List Encoding — Must Convert to String

asyncpg doesn't auto-convert `list[float]` to pgvector. You get `TypeError: expected str, got list`.

**Fix**: Convert embedding to `[x,x,x,...]` string:
```python
emb_str = "[" + ",".join(str(x) for x in embedding) + "]"
await conn.execute("INSERT INTO chunks (embedding) VALUES ($1::vector)", emb_str)
```

This applies to BOTH inserts AND vector search queries.

## 3. HNSW Dimension Limit = 2000

pgvector ≤0.8.x caps HNSW at 2000 dimensions. Gemini returns 3072 dims.

**Fix**: Truncate to 768: `embedding[:768]`

## 4. .env File Masking

Hermes blocks reading `.env`. Use inline env vars:
```bash
GEMINI_API_KEY=*** python3 -c "..."
```

## 5. Free Tier LLM Rate Limits

All free LLM providers have aggressive rate limits. Always implement:
- Rate limiting (2-6s between requests)
- Graceful fallbacks (truncated text, "lainnya" category, zero vector)
- The fallback path IS the MVP path

## 6. Synchronous AI Calls in Async Context

Both `genai.embed_content()` (Gemini) and `client.chat.completions.create()` (OpenRouter) are **synchronous** and block the FastAPI event loop.

**Fix for embedding**: Wrap in `ThreadPoolExecutor`:
```python
import concurrent.futures
with concurrent.futures.ThreadPoolExecutor() as pool:
    future = pool.submit(genai.embed_content, model=model, content=text, task_type="retrieval_document")
    result = future.result(timeout=8.0)
```

**Fix for LLM calls**: Add `timeout=10.0` AND `max_retries=0` to the OpenAI client:
```python
client = OpenAI(api_key=key, base_url=base_url, max_retries=0, timeout=10.0)
```

Without `max_retries=0`, the SDK auto-retries on 429 with exponential backoff (11s, 30s, 29s...), causing very long request times. With `max_retries=0`, the call fails fast and the fallback path (truncated text / "lainnya" category / zero vector) kicks in immediately.

## 7. FastAPI Port Already in Use

When restarting FastAPI, the old process may still hold the port. Kill before restart:
```bash
fuser -k 8000/tcp 2>/dev/null; sleep 2
```

Or find and kill the specific PID:
```bash
ss -tlnp | grep 8000
kill -9 <PID>
```

## 8. FastAPI --reload Suppresses Output

Running with `--reload` flag can suppress stdout/stderr output. Use without `--reload` for debugging.
