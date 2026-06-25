# Second Brain — Project Reference

> Active project as of 2026-06-04. KII's first micro-SaaS product.

## Concept

Personal Knowledge Manager via WhatsApp. User forward link/artikel/voice note → bot auto-extract + AI summarize + save. Searchable via WA chat. Evolve into AI chat with saved knowledge.

## Market Validation

- Pocket SHUT DOWN July 2025 — big gap in market
- 3.3B WhatsApp users globally, $45B WA commerce economy (2026)
- No dominant player in "Second Brain via WhatsApp" space
- WA bot conversion: 45-60% (vs email 2-5%)

## Architecture

```
User (WhatsApp) → WA Business API → FastAPI Backend → Gemini AI + PostgreSQL → Next.js Dashboard
```

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Runtime | Python 3.12 | Familiar, rich ecosystem |
| API | FastAPI | Fast, async, auto-docs |
| WA Integration | WA Cloud API (Meta) | Free tier 1000 convo/month |
| DB | PostgreSQL | Reliable, good for search |
| ORM | SQLAlchemy | Standard, flexible |
| AI | Gemini 1.5 Flash | Free tier generous, good quality |
| Web Dashboard | Next.js + Tailwind | Familiar web stack |
| Hosting | VPS (Hetzner/DigitalOcean) | $5-10/month |
| Payments | Stripe (global) / QRIS (Indonesia) | Flexible |

## Monetization

| Tier | Price | Features |
|---|---|---|
| Free | $0 | 20 saves/month, basic summary, 7-day retention |
| Pro | $3-5/month | Unlimited saves, AI summary, search, weekly recap |
| Power | $8-10/month | Everything + AI chat with knowledge, export, priority |

## 4-6 Week Roadmap

### Week 1 (June 4-10) — Foundation
- Tech stack setup, WA Business API registration, DB schema
- Core backend: receive WA message, extract URL content, save to DB
- AI summary integration
- E2E testing: forward link → get summary

### Week 2 (June 11-17) — Core Features
- Search functionality
- Weekly recap feature
- User auth & multi-user support
- Polish + bug fixes

### Week 3 (June 18-24) — Web Dashboard
- Dashboard layout (Next.js), user login
- Saved items list, search, tags
- Settings page, subscription management

### Week 4 (June 25-July 1) — Monetization & Launch Prep
- Stripe/subscription integration
- Free tier limits (20 items) + Premium unlock
- Landing page, documentation
- Soft launch — 10 beta users

### Week 5-6 (July 2-14) — Feedback & Iterate
- Collect feedback, fix bugs, add features
- Performance optimization
- Public launch

## Approach: A → C Evolution

- **Phase A:** Save & Summarize (forward link → AI summary → save → search)
- **Phase B:** Capture Everything (text, voice, image, location)
- **Phase C:** AI Chat with Knowledge (conversational retrieval from saved content)

## File Locations

- Full plan: `/root/projects/braindump/SECOND_BRAIN_PLAN.md`
- Source code: TBD (new repo/project folder)
