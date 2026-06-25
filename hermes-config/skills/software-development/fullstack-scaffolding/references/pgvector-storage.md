# pgvector Storage & Performance Notes

## Storage Overhead of Vector Indexes

pgvector HNSW indexes are **memory-resident** — the entire index must fit in `shared_buffers` + OS page cache. Rule of thumb: HNSW index size ≈ 1.5× the raw vector data.

For 768-dim `vector(768)` with `float4` (4 bytes per dim):
- Per vector: 768 × 4 = 3,072 bytes ≈ 3 KB
- 10K chunks: ~30 MB raw + ~45 MB HNSW index = ~75 MB total
- 100K chunks: ~300 MB raw + ~450 MB index = ~750 MB total

**Recommendation**: For MVP with <50K chunks, default PostgreSQL `shared_buffers` (128 MB) is fine. For larger scale, increase `shared_buffers` to 1-2 GB and consider IVFFlat instead of HNSW.

## Metadata-Heavy Schema Pattern

When each knowledge item has rich metadata (title, summary, category, tags, source_url, file_path, raw_content), the `items` table can grow wide. Consider:

1. **Separate `item_metadata` table** for rarely-queried fields (file_path, raw_content)
2. **Use `jsonb` column** for flexible metadata instead of many nullable columns
3. **Keep `items` table lean** — only fields used in search/filtering

Example lean schema:
```sql
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    type VARCHAR(20) NOT NULL,
    title VARCHAR(500),
    summary TEXT,
    category VARCHAR(100),
    tags VARCHAR(500),
    search_tsv tsvector,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE item_metadata (
    item_id INTEGER PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    source_url VARCHAR(2000),
    file_path VARCHAR(500),
    raw_content TEXT,
    extra JSONb DEFAULT '{}'
);
```

## HNSW vs IVFFlat Tradeoffs

| Factor | HNSW | IVFFlat |
|--------|------|---------|
| Recall | Higher (95-99%) | Lower (80-95%) |
| Build time | Slower | Faster |
| Query speed | Faster | Slower |
| Memory | Higher | Lower |
| Insert speed | Slower (index update) | Faster (add to list) |

**Recommendation**: Use HNSW for MVP (better search quality). Switch to IVFFlat if insert performance becomes a bottleneck with >100K chunks.

## Batch Insert Pattern

When ingesting a document with multiple chunks, use a transaction for atomicity:
```python
async with conn.transaction():
    item_id = await conn.fetchval("INSERT INTO items ... RETURNING id")
    for i, (chunk, emb) in enumerate(zip(chunks, embeddings)):
        emb_str = "[" + ",".join(str(x) for x in emb) + "]"
        await conn.execute(
            "INSERT INTO chunks (item_id, chunk_index, content, embedding) VALUES ($1,$2,$3,$4::vector)",
            item_id, i, chunk, emb_str
        )
```
