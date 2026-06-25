# Telegram Send via Python — Workaround for Shell Quoting Issues

## Problem
Sending Telegram messages via `curl` in shell fails repeatedly when:
- The bot token contains special characters (`:`, `/`, `+`, `=`)
- The message contains emoji, markdown, or special characters
- Shell variable interpolation conflicts with quoting (single vs double quotes)

## Root Cause
The token format `8863639977:AAHCO...` contains `:` which breaks some shell parsing.
Message content with emoji, `*markdown*`, `&`, `%0A` encoding all create escaping nightmares.

## ⚠️ Token Location (UPDATED 2026-06-23)
**The token in `/root/.hermes/.env` is MASKED** (`886363...aez8`). Do NOT extract from `.env`.

**Use the unmasked token from:**
```bash
cat /root/.hermes/scripts/.bot_token | tr -d '\n'
```
This file contains the full 46-character token.

## Working Solution: Python urllib
Write a small Python script and execute it:

```python
#!/usr/bin/env python3
import urllib.request
import urllib.parse
import pathlib

# Read token from file (avoids shell escaping entirely)
token = pathlib.Path('/root/.hermes/scripts/.bot_token').read_text().strip()

# Read message from file (avoids shell escaping entirely)
msg = pathlib.Path('/tmp/briefing-msg.txt').read_text()

url = f"https://api.telegram.org/bot{token}/sendMessage"
data = urllib.parse.urlencode({
    'chat_id': '-1003966561389',
    'message_thread_id': '1264',
    'parse_mode': 'Markdown',
    'text': msg
}).encode('utf-8')

req = urllib.request.Request(url, data=data, method='POST')
resp = urllib.request.urlopen(req, timeout=15)
print(resp.status, resp.read().decode('utf-8'))
```

## Alternative: curl with Python-generated JSON (validated 2026-06-23)
```bash
TOKEN=*** /root/.hermes/scripts/.bot_token | tr -d '\n')
MSG="your message here"
PAYLOAD=$(python3 -c "
import json, sys
text = sys.stdin.read()
payload = {'chat_id': -1003966561389, 'message_thread_id': 1264, 'text': text, 'parse_mode': 'Markdown'}
print(json.dumps(payload))
" <<< "$MSG")

curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

## Steps
1. Extract token: `cat /root/.hermes/scripts/.bot_token | tr -d '\n'`
2. Write message to file: write briefing text to `/tmp/briefing-msg.txt`
3. Write Python script to `/tmp/send-briefing.py`
4. Run: `python3 /tmp/send-briefing.py`
5. Verify: check for `"ok":true` in response

## Verification
Successful response looks like:
```json
{"ok":true,"result":{"message_id":14574,...}}
```

## When to Use
- Any cron job or automated task that sends to Telegram
- When curl with `--data-urlencode` fails due to shell escaping
- When message contains complex markdown + emoji

## Token Extraction (reliable)
```bash
cat /root/.hermes/scripts/.bot_token | tr -d '\n'
```
Do NOT use `grep` on `/root/.hermes/.env` — the token there is masked/truncated.
