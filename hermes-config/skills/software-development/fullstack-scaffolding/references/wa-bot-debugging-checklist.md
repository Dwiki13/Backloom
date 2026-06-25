# WhatsApp Bot Debugging Checklist

## Quick Connection Check

```bash
# Check if WA is connected
docker exec <container> python -c "
import asyncio
from api.main import get_wa_adapter
async def check():
    adapter = get_wa_adapter()
    print('is_ready:', adapter.is_ready)
    print('qr_code:', adapter.qr_code[:30] + '...' if adapter.qr_code else None)
asyncio.run(check())
"
```

## Log Monitoring

```bash
# Watch for connection + whitelist activity
docker logs -f <container> 2>&1 | grep -i -E "baileys|bridge|qr|ready|connect|error|disconnect|message|ignore|whitelist"

# Check recent connection history
docker logs --tail 100 <container> 2>&1 | grep -i -E "baileys|bridge|qr|ready|connect|error|disconnect"
```

## Common Scenarios

### "Messages not being received"
1. Check `is_ready` — if `False`, WA is disconnected
2. Look for "Baileys disconnected" in logs
3. Re-scan QR if needed

### "Messages received but not replied"
1. Check whitelist: look for "Ignoring message from non-whitelisted number" in logs
2. If the sender's number appears with `@lid` suffix, the whitelist function must handle it
3. Verify `ALLOWED_NUMBERS` includes the correct number

### "QR code not showing"
1. Clear auth: `docker exec <container> rm -rf /app/api/adapters/.baileys_auth`
2. Restart container
3. Open `/api/qr` in browser (returns HTML page, not JSON)
4. Check logs for "QR code received"

### "Switching to a different phone number"
1. Clear auth + restart (above)
2. Scan new QR with the new number
3. Update `ALLOWED_NUMBERS` in code to match the new number
4. Redeploy

## Second Brain Specific (secondbrain.devlokal.id)

- Container: `secondbrain-api`
- DB: `secondbrain-db` (port 5433)
- QR page: `https://secondbrain.devlokal.id/api/qr`
- Whitelist: `ALLOWED_NUMBERS` in `api/main.py`
- Auth dir: `/app/api/adapters/.baileys_auth`
