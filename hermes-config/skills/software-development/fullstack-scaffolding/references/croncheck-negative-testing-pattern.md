# CronCheck Negative Testing Pattern

This reference documents the negative testing pattern used for CronCheck (June 2026). Use as a template for future tool builds.

## Test Case Categories (100 total)

| Category | Count | Focus |
|----------|-------|-------|
| Ping Endpoint Failures | 15 | Invalid tokens, rate limits, DB downtime, concurrent pings |
| Missed Job Detection | 15 | Scheduler failures, clock skew, DST, mass misses |
| Notification Failures | 15 | Bot blocked, API down, rate limits, dedup |
| Authentication Failures | 15 | Brute force, expired JWT, session fixation |
| Database Failures | 10 | Connection loss, corruption, deadlocks, pool exhaustion |
| Telegram Bot Failures | 15 | Blocked bot, invalid commands, rate limits |
| Deployment Failures | 10 | Port conflicts, OOM, config missing |
| Time/Scheduling Edge Cases | 15 | DST, leap seconds, timezone extremes |
| Data/Storage Edge Cases | 10 | Unicode, long names, token collision |
| User Behavior Edge Cases | 10 | Account deletion, spam, inactivity |

## Key Patterns

### 1. Ping Endpoint Resilience
- Invalid token → 404 (not 500)
- Rate limit → 429 with Retry-After
- DB down → Queue ping, retry later
- Concurrent pings → All succeed, no race conditions

### 2. Missed Job Detection
- Scheduler crash → Auto-restart, catch up
- Clock skew → Use monotonic clock
- DST changes → Handle gap/duplicate hours
- Mass misses → Queue alerts, rate limit notifications

### 3. Notification Resilience
- Bot blocked → Mark inactive, fallback to email
- API down → Retry with exponential backoff
- Rate limit → Queue, send with delay
- Dedup → Max 1 alert per 5 min per job

### 4. Security
- Brute force → Rate limit + lockout
- JWT tampering → RS256 signature verification
- SQL injection → Parameterized queries
- XSS → Template escaping

## Design Doc Location
`/root/projects/croncheck/DESIGN.md` — single file, 43KB, includes all 100 negative test cases in Section 10.
