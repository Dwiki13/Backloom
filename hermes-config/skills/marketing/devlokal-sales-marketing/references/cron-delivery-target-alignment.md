# Cron Delivery Target Alignment — Pitfall & Fix

## Problem
Cron job messages (daily briefing, weekly report, follow up reminders) were delivered to the **wrong Telegram topic** — Topic Trading (334) instead of Topic Sales Marketing (1264).

## Root Cause
Two independent delivery mechanisms must match:
1. **`deliver` field** on the cron job (`cronjob create/update` → `telegram:-1003966561389:1264`)
2. **Prompt internal send target** — the agent's `send_message` or `curl` call inside the prompt MUST use the same thread ID

When the prompt hardcoded `THREAD_ID=334` (Topic Trading) but `deliver` was set to `1264`, the agent sent to 334 via curl/send_message — and that went directly to the wrong topic.

## Telegram Topic Map
| Topic | Thread ID | Purpose |
|---|---|---|
| Sales Marketing | `1264` | ✅ All marketing: daily briefing, weekly report, follow up reminders, Google Ads |
| Notifikasi | `5` | Todo reminders only (handled by separate scripts) |
| Trading | `334` | ❌ Never send marketing here — trading signals only |

## Fix Pattern
When creating/updating a cron job that sends to Telegram:

1. Set `deliver: "telegram:-1003966561389:1264"` on the cron job
2. In prompt steps that send messages, hardcode `THREAD_ID="1264"` and `CHAT_ID="-1003966561389"`
3. Add explicit warning in prompt: "JANGAN kirim ke Topic Trading (334)"
4. Verify BOTH `deliver` field AND prompt internal target match

## Affected Cron Jobs (fixed 2026-06-20)
| Job ID | Name | Schedule | Target |
|---|---|---|---|
| `cda46638c4ea` | DevLokal Daily Marketing Briefing | 07:00 WIB daily | `1264` (Sales Marketing) |
| `a9c92b2f4071` | DevLokal Marketing — Weekly Report | Mon 09:00 WIB | `1264` (Sales Marketing) |
