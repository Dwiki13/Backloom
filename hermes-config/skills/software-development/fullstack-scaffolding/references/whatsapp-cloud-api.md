# WhatsApp Cloud API — Registration & Setup

## When to Use
- Production WhatsApp bot (safe from Meta bans)
- Multi-user / subscription products
- Need separate business phone number

## Requirements
1. Facebook Business Manager account (business.facebook.com)
2. Meta Developer account (developers.facebook.com)
3. Separate phone number (can be virtual/online number)
4. Business verification (can be personal/unverified initially)

## Setup Steps

### 1. Create Meta App
- Go to developers.facebook.com → Create App → Business type
- Add WhatsApp product to the app

### 2. Get API Credentials
- App ID, App Secret
- Phone Number ID (from WhatsApp → Getting Started)
- Permanent Access Token (generate from System User)

### 3. Configure Webhook
- Callback URL: https://yourdomain.com/webhook
- Verify Token: set in .env as WA_VERIFY_TOKEN
- Subscribe to messages field

### 4. Environment Variables
```
WA_MODE=cloud
WA_WEBHOOK_SECRET=your_webhook_secret
WA_VERIFY_TOKEN=your_verify_token
WA_PHONE_NUMBER_ID=your_phone_number_id
WA_ACCESS_TOKEN=your_permanent_access_token
```

### 5. Webhook Endpoint
```python
# GET /webhook — Meta verification
@router.get("/webhook")
async def verify(request: Request):
    mode = request.query_params.get("hub.mode")
    token = request.query_params.get("hub.verify_token")
    challenge = request.query_params.get("hub.challenge")
    if mode == "subscribe" and token == settings.wa_verify_token:
        return Response(content=challenge)
    return Response(status_code=403)

# POST /webhook — Incoming messages
@router.post("/webhook")
async def webhook(data: dict):
    for entry in data.get("entry", []):
        for change in entry.get("changes", []):
            messages = change.get("value", {}).get("messages", [])
            for msg in messages:
                if msg.get("type") == "text":
                    handle_incoming_message({
                        "from": msg["from"],
                        "body": msg["text"]["body"],
                    })
    return {"status": "ok"}
```

## Free Tier
- 1,000 conversations/month free
- Conversation = 24-hour session with 1 user
- After 1,000: ~$0.005-0.008 per conversation

## Migration from Baileys
1. Swap adapter: WA_MODE=cloud instead of WA_MODE=baileys
2. Remove Baileys bridge script (no longer needed)
3. Add webhook routes
4. User registration flow: user sends message → webhook → create user → process
