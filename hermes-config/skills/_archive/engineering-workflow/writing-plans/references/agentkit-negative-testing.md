# AgentKit — Negative Testing Framework

> Source: KII session June 21 2026. 89 test cases across 8 categories for an AI Agent Starter Kit (AgentKit).
> Use this as a template for negative testing before design docs on any tool/product.

## Category 1: Agent Engine Core + Execution (18 tests)

| # | Category | Test Case | Expected Behavior |
|---|----------|-----------|-------------------|
| 1 | Engine | API key invalid | Return error clearly, DON'T crash |
| 2 | Engine | API key expired | Detect → prompt re-auth |
| 3 | Engine | Rate limit hit (>100 req/sec) | Graceful backoff + queue |
| 4 | Engine | Model down (provider offline) | Auto-fallback to backup model |
| 5 | Engine | Model timeout (>30s) | Timeout → retry → fallback |
| 6 | Engine | Model returns empty (200 OK, body empty) | Detect → retry with different prompt |
| 7 | Engine | Model returns garbage | Validate output → retry |
| 8 | Engine | Token limit exceeded | Auto-truncate or split |
| 9 | Engine | Cost limit exceeded (budget) | Block request → notify user |
| 10 | Engine | Model version deprecated | Auto-migrate + warn user |
| 11 | Execution | Agent stuck in loop (tool error → retry → loop) | Detect loop → break after N retries |
| 12 | Execution | Agent hallucination | Fact-check → flag uncertain |
| 13 | Execution | Tool call failed (API down) | Graceful degradation → partial response |
| 14 | Execution | Memory corruption (file corrupted) | Detect → restore from backup |
| 15 | Execution | Context overflow (conversation too long) | Summarize old → keep recent |
| 16 | Execution | Conflicting instructions (2 contradictory) | Detect → ask clarification |
| 17 | Execution | Unsafe output (harmful content) | Content filter → block + log |
| 18 | Execution | Infinite tool call (recursive >10x) | Hard stop → alert user |

## Category 2: Tool Connectors (15 tests)

### Telegram (8 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | Bot token invalid/revoked | Detect → prompt re-auth → pause connector |
| 2 | User blocked bot | Detect → mark inactive → stop sending |
| 3 | Message too long (>4096 chars) | Split into multiple messages |
| 4 | Media upload fail (>5MB/unsupported) | Compress → retry → fallback to text |
| 5 | Webhook down | Auto-switch to polling → notify |
| 6 | Spam detection (>100 msg/min) | Rate limit → queue → delayed send |
| 7 | Chat not found (user deleted) | Detect → mark inactive |
| 8 | Bot kicked from group | Detect → notify admin → remove |

### Discord (8 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | Bot token invalid | Detect → prompt re-auth |
| 2 | Missing permissions | Detect → list missing → guide user |
| 3 | Channel deleted | Detect → fallback to DM → notify |
| 4 | Rate limit (Discord) | Exponential backoff → queue |
| 5 | Gateway disconnect | Auto-reconnect → resume session |
| 6 | Interaction timeout (>3s) | Defer → process async → follow-up |
| 7 | Embed too large (>6000 chars) | Truncate → split → plain text |
| 8 | Intents missing on startup | Fail fast → guide user |

### WhatsApp (7 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | QR code expired | Auto-regenerate → notify |
| 2 | Number banned by WhatsApp | Detect → pause → guide Cloud API migration |
| 3 | Media download fail (URL expired) | Retry → fallback to text |
| 4 | Template message rejected | Log error → use fallback message |
| 5 | Phone offline (>24h) | Queue → deliver when online |
| 6 | API version deprecated | Warning → auto-migrate if compatible |
| 7 | Group admin only restriction | Detect → ignore non-admin → log |

## Category 3: Memory Layer (8 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | Database full (disk) | Detect → compress old data → alert |
| 2 | Database corrupted (crash) | Detect on load → restore from backup |
| 3 | Concurrent write conflict (2 agents) | Locking → queue → retry |
| 4 | Memory leak (usage rising) | Monitor → restart if > threshold |
| 5 | Query timeout (>5s) | Timeout → log → optimize |
| 6 | Data inconsistency (A says X, B says Y) | Source of truth check → merge |
| 7 | Encryption key lost | Detect → prompt recovery → can't decrypt old |
| 8 | Schema migration fail | Rollback → notify → manual fix guide |

## Category 4: Dashboard & Auth (15 tests)

### Authentication (8 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | Brute force (100 logins/min) | Rate limit → lockout → CAPTCHA |
| 2 | JWT expired mid-request | 401 → redirect → preserve intended URL |
| 3 | JWT signature invalid (tampered) | 401 → log → invalidate session |
| 4 | Session hijack (different device) | Device fingerprinting → re-auth required |
| 5 | OAuth callback error/cancel | Graceful error page → retry option |
| 6 | CSRF attack | CSRF token validation → reject |
| 7 | Account deletion mid-session | Invalidate all sessions → goodbye page |
| 8 | Concurrent sessions (5+ devices) | Limit sessions → notify → force logout oldest |

### Dashboard (7 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | WebSocket disconnect | Auto-reconnect → fallback to polling |
| 2 | Large data load (100K+ entries) | Paginate → lazy load → skeleton UI |
| 3 | Old browser (IE11) | Feature detection → graceful degradation |
| 4 | Slow network (3G) | Optimistic UI → offline mode → sync |
| 5 | Dashboard crash (JS error) | Error boundary → fallback UI → report |
| 6 | API timeout (>10s) | Loading state → timeout message → retry |
| 7 | XSS attempt in form input | Sanitize → reject → log attempt |

## Category 5: Deployment (10 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | Docker build fail (conflict) | Clear error message → suggest fix |
| 2 | Port conflict (8000 taken) | Detect → suggest alternative → auto-switch |
| 3 | Out of memory (OOM) | OOM killer → restart → alert |
| 4 | Disk full (logs) | Log rotation → compress → alert |
| 5 | SSL certificate expired | Auto-renew → alert if renew fails |
| 6 | DNS propagation fail | Detect → fallback to IP → notify |
| 7 | VPS provider down | Health check → alert → guide migration |
| 8 | Config file missing (.env) | Fail fast → clear error → setup wizard |
| 9 | Migration fail | Rollback → preserve data → notify |
| 10 | Rollback needed (broken release) | One-click rollback → preserve data |

## Category 6: Multi-Agent & Concurrency (7 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | Dependency failure (A→B, B down) | Timeout → partial response → notify |
| 2 | Circular dependency (A↔B) | Detect cycle → break → log |
| 3 | Resource contention (10 agents concurrent) | Queue → rate limit → fair scheduling |
| 4 | Priority conflict (2 high, limited resources) | Priority queue → preempt lower |
| 5 | Agent state inconsistency (restart mid-task) | State recovery → resume or restart |
| 6 | Deadlock (2 agents wait for each other) | Timeout → detect → break |
| 7 | Agent fork bomb (recursive spawn) | Hard limit on spawn depth → block |

## Category 7: Security (8 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | SQL injection (' OR 1=1 --) | Parameterized query → reject → log |
| 2 | Prompt injection ("Ignore previous...") | Detect → sanitize → log |
| 3 | Path traversal (../../etc/passwd) | Validate path → reject → log |
| 4 | SSRF attack (webhook to internal IP) | Block internal IPs → validate URL |
| 5 | Data exfiltration (agent told to leak) | Block → log → alert |
| 6 | Privilege escalation (user → admin) | RBAC → 403 → log |
| 7 | Supply chain attack (compromised package) | Lock deps → audit → sandbox |
| 8 | Secret leakage (API key in log/response) | Mask secrets → scan responses |

## Category 8: UX Edge Cases (8 tests)

| # | Test Case | Expected Behavior |
|---|-----------|-------------------|
| 1 | Agent deleted mid-conversation | Graceful shutdown → save state → notify |
| 2 | Model changed mid-conversation | Preserve context → adapt → notify |
| 3 | Free tier exceeded (1000 requests) | Soft limit → upsell → don't hard break |
| 4 | Broken config import (corrupt JSON) | Validate schema → show errors → suggest fix |
| 5 | Agent created without model | Block → guide to setup model first |
| 6 | "Regenerate" spam (50x in 1 min) | Rate limit → queue → show position |
| 7 | User offline during long task (10 min) | Complete → save → notify when back |
| 8 | Mixed language input (ID + EN) | Handle multilingual → don't break |

## Summary

| Category | Tests | Critical | High | Medium |
|----------|-------|----------|------|--------|
| Agent Engine + Execution | 18 | 5 | 7 | 6 |
| Tool Connectors | 15 | 5 | 7 | 3 |
| Memory Layer | 8 | 3 | 3 | 2 |
| Dashboard & Auth | 15 | 6 | 6 | 3 |
| Deployment | 10 | 4 | 4 | 2 |
| Multi-Agent | 7 | 3 | 3 | 1 |
| Security | 8 | 6 | 2 | 0 |
| UX Edge Cases | 8 | 2 | 4 | 2 |
| **TOTAL** | **89** | **34** | **36** | **19** |

## Design Doc Implications (Must Address in Architecture)

1. **Resilience-first architecture** — every component must have fallback
2. **Circuit breaker pattern** — for all external calls (API, connectors)
3. **Graceful degradation** — partial response > no response
4. **State management** — agent state must be persistable and recoverable
5. **Security by default** — input validation at all entry points
6. **Observability** — all failures must be logged, monitored, alerted
7. **Rate limiting** — at all levels (user, agent, tool, API)
8. **Graceful shutdown** — agent must be stoppable without losing state
