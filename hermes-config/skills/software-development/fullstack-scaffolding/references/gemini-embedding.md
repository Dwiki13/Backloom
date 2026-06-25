# Gemini Embedding Model Reference

## Current Models (as of June 2026)

| Model | Dimensions | Status |
|-------|------------|--------|
| `models/gemini-embedding-001` | 3072 | ✅ Active |
| `models/gemini-embedding-2` | 3072 | ✅ Active |
| `models/gemini-embedding-2-preview` | 3072 | ✅ Active |
| `text-embedding-004` | 768 | ❌ Deprecated (returns 404) |

## pgvector Compatibility

pgvector ≤0.8.x caps HNSW and IVFFlat indexes at **2000 dimensions max**.

**Solution**: Truncate 3072-dim embeddings to 768 dims (first 768 values).

## Code Pattern

```python
EMBEDDING_DIM = 768
EMBEDDING_MODEL = "models/gemini-embedding-001"

def embed(text: str) -> list[float]:
    result = genai.embed_content(
        model=EMBEDDING_MODEL,
        content=text,
        task_type="retrieval_document",
    )
    return result["embedding"][:EMBEDDING_DIM]
```

## Verification

```python
import google.generativeai as genai
genai.configure(api_key=key)
for m in genai.list_models():
    if 'embed' in m.name.lower():
        print(f"{m.name} | {m.supported_generation_methods}")
```

## API Key Notes

- Valid Gemini API keys start with `AIzaSy...`
- Keys starting with `AQ...` are NOT Gemini API keys
- GCP Console keys require service account binding for Gemini API (won't work with `genai.configure()`)
- AI Studio keys (from aistudio.google.com/apikey) work directly
- Free tier: 1500 embedding requests/day per project
- Daily quota resets at midnight Pacific Time (14:00 WIB next day)
