# Baileys + Docker — Setup & Debugging

## Dockerfile Checklist

```dockerfile
FROM python:3.12-slim
WORKDIR /app

# MUST include git — Baileys has GitHub deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg libpq-dev gcc git \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY api/ /app/api/

# npm install AFTER copying package.json
RUN cd /app/api && npm install

ENV PYTHONPATH=/app
EXPOSE 8000
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Common Errors

### MODULE_NOT_FOUND: @whiskeysockets/baileys
- npm install ran before COPY api/ — fix order in Dockerfile
- Or install manually: docker exec container bash -c "cd /app/api && npm install @whiskeysockets/baileys"

### Baileys disconnects immediately (no QR)
1. Clear auth state: rm -rf .baileys_auth/
2. Ensure makeCacheableSignalKeyStore is used (Baileys v6 requirement)
3. Restart container

### Separator not found, chunk exceed the limit
- QR code JSON exceeds readline() 64KB buffer
- Fix: use chunked stdout.read(65536) + manual newline splitting

### Container can't reach DB
Attach to additional network: docker network connect npm_default secondbrain-api

### NPM returns 502
- Upstream container must be on same Docker network as NPM
- Use container name (not IP) as upstream in NPM config

## LID vs Phone Number
Baileys may report sender as 251990747672681@lid instead of 628xxx. Always normalize:
clean = number.replace("@lid", "").replace("@s.whatsapp.net", "")
